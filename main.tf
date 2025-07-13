provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

# SSH key pair oluşturma
resource "aws_key_pair" "wireguard_key" {
  key_name        = "wireguard-key-${var.aws_region}"  # Bölgeye özel isim
  public_key      = file(var.public_key_path)

  tags = {
    Name = "wireguard-vpn-key"
    Region = var.aws_region
  }
}

# Security group tanımı
resource "aws_security_group" "vpn_sg" {
  name_prefix = "wireguard-vpn-sg-"
  description = "Security group for WireGuard VPN"
  vpc_id      = data.aws_vpc.default.id

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "WireGuard VPN port"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "wireguard-vpn-sg"
    Region = var.aws_region
  }
}

# EC2 Instance oluşturma
resource "aws_instance" "vpn_server" {
  ami           = lookup(var.amis, var.aws_region, var.ami_id)  # Bölgeye göre AMI seçer
  instance_type = var.instance_type
  key_name      = aws_key_pair.wireguard_key.key_name

  vpc_security_group_ids      = [aws_security_group.vpn_sg.id]
  associate_public_ip_address = true
  
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = file("${path.module}/scripts/user-data.sh")

  tags = {
    Name = "wireguard-vpn"
    Region = var.aws_region
  }

  depends_on = [aws_key_pair.wireguard_key]  # Key pair'in önce oluşturulmasını garantile

  # Instance hazır olana kadar bekle
  provisioner "remote-exec" {
    inline = ["echo 'Waiting for instance to be ready...'"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip

      # SSH bağlantı ayarları
      timeout     = "5m"
      agent       = false
    }
  }

  # client.conf dosyasının oluşmasını bekle
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for client configuration...'",
      "while [ ! -f /home/ubuntu/client.conf ]; do sleep 5; done",
      "cat /home/ubuntu/client.conf"
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      timeout     = "5m"
    }
  }

  # client.conf dosyasını yerel makineye kopyala
  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -o ConnectTimeout=300 -i ${var.private_key_path} ubuntu@${self.public_ip}:/home/ubuntu/client.conf ${path.module}/client.conf"
  }

  # VPN kullanıcı ekleme script'ini yükle
  provisioner "file" {
    source      = "${path.module}/scripts/add_vpn_user.sh"
    destination = "/home/ubuntu/add_vpn_user.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  # Script'e çalıştırma izni ver
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/add_vpn_user.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  timeouts {
    create = "10m"
    delete = "10m"
  }
}
