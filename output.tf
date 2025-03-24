output "instance_ids" {
  value = { for k, v in aws_instance.server : k => v.id }
}
