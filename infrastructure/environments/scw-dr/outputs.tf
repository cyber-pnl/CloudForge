output "vpc_id" {
  value = scaleway_vpc.dr.id
}

output "private_network_id" {
  value = scaleway_vpc_private_network.dr.id
}

output "standby_instance_id" {
  value = scaleway_instance_server.standby.id
}

output "standby_private_ip" {
  value = one(scaleway_instance_server.standby.private_ips[*].address)
}

output "restore_volume_id" {
  value = scaleway_block_volume.restore_data.id
}
