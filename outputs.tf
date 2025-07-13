output "vpn_server_ip" {
  value       = aws_instance.vpn_server.public_ip
  description = "VPN sunucusunun public IP adresi"
}

output "ssh_private_key" {
  value       = var.private_key_path
  description = "SSH private key dosyasının yolu"
  sensitive   = true
}

output "ssh_user" {
  value       = "ubuntu"
  description = "SSH bağlantısı için kullanıcı adı"
}

