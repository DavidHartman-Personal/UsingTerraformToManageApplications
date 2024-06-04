output "ami_id" {
  value = data.aws_ssm_parameter.this.value
}

output "subnet_id" {
  value = aws_subnet.this.id
}
