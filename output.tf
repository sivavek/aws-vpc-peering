# Output
output "jumphost_public_ip" {
  value = aws_instance.jumphost.public_ip
  description = "Public IP address of the Jump Host"
}

output "private_east_1a_ip" {
  value = aws_instance.private_east_1a.private_ip
  description = "Private IP address of EC2 in VPC East 1A"
}

output "private_east_1b_ip" {
  value = aws_instance.private_east_1b.private_ip
  description = "Private IP address of EC2 in VPC East 1B"
}

output "private_west_1_ip" {
  value = aws_instance.private_west_1.private_ip
  description = "Private IP address of EC2 in VPC West 1"
}


