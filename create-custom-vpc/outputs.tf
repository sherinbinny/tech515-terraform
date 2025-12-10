output "app_public_ip" {
  value = aws_instance.app_instance.public_ip
}

output "posts_url" {
  value = "http://${aws_instance.app_instance.public_ip}/posts"
}