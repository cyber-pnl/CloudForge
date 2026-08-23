resource "aws_iam_role" "this" {
  name = var.role_name

  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect    = "Allow"
          Action    = "sts:AssumeRole"
          Principal = { Service = "lambda.amazonaws.com" }
        }
      ]
    }
  )

  tags = merge(
    {
      Name        = var.role_name
      Environment = var.environment
      ManagedBy   = "opentofu"
    },
    var.tags,
  )
}

resource "aws_iam_role_policy" "this" {
  name = "${var.role_name}-inline"
  role = aws_iam_role.this.id

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = concat(
        [
          {
            Effect   = "Allow"
            Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
            Resource = ["*"]
          }
        ],
        var.policy_statements,
      )
    }
  )
}
