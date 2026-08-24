locals {
  top_paths = { for key, route in var.routes : key => "/${route.path_part}" }
  child_paths = {
    for key, route in var.child_routes :
    key => "${local.top_paths[route.parent]}/${route.path_part}"
  }
  grandchild_paths = {
    for key, route in var.grandchild_routes :
    key => "${local.child_paths[route.parent]}/${route.path_part}"
  }

  all_paths = merge(local.top_paths, local.child_paths, local.grandchild_paths)
}

resource "aws_api_gateway_rest_api" "this" {
  name = var.api_name

  tags = merge(
    {
      Name        = var.api_name
      Environment = var.environment
      ManagedBy   = "opentofu"
    },
    var.tags,
  )
}

resource "aws_api_gateway_resource" "top" {
  for_each = var.routes

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_resource" "child" {
  for_each = var.child_routes

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.top[each.value.parent].id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_resource" "grandchild" {
  for_each = var.grandchild_routes

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.child[each.value.parent].id
  path_part   = each.value.path_part
}

locals {
  resource_ids = merge(
    { for key, res in aws_api_gateway_resource.top : key => res.id },
    { for key, res in aws_api_gateway_resource.child : key => res.id },
    { for key, res in aws_api_gateway_resource.grandchild : key => res.id },
  )
  integrations = merge(
    { for key, route in var.routes : key => route },
    { for key, route in var.child_routes : key => route },
    { for key, route in var.grandchild_routes : key => route },
  )
}

resource "aws_api_gateway_method" "this" {
  for_each = local.integrations

  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = local.resource_ids[each.key]
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "this" {
  for_each = local.integrations

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = local.resource_ids[each.key]
  http_method = aws_api_gateway_method.this[each.key].http_method

  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = each.value.lambda_invoke_arn
}

resource "aws_lambda_permission" "this" {
  for_each = local.integrations

  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/${aws_api_gateway_method.this[each.key].http_method}${local.all_paths[each.key]}"
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([
      for _, integration in aws_api_gateway_integration.this : integration.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.this,
    aws_api_gateway_integration.this,
  ]
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = var.stage_name
}
