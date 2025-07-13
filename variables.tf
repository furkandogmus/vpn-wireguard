variable "aws_region" {
  description = "AWS bölgesi"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "EC2 instance için kullanılacak AMI ID"
  type        = string
  default     = "ami-042b4708b1d05f512"
}

variable "amis" {
  type = map(string)
  default = {
    # N. Virginia
    "us-east-1"  = "ami-020cba7c55df1f615"
    # Ohio
    "us-east-2" = "ami-0d1b5a8c13042c939"
    # N. California
    "us-west-1"  = "ami-014e30c8a36252ae5"
    # Oregon
    "us-west-2" = "ami-05f991c49d264708f"
    # Mumbai
    "ap-south-1" = "ami-0f918f7e67a3323f0"
    # Singapore
    "ap-southeast-1" = "ami-02c7683e4ca3ebf58"
    # Sydney
    "ap-southeast-2" = "ami-0662f4965dfc70aca"
    # Tokyo
    "ap-northeast-1" = "ami-054400ced365b82a0"
    # Seoul
    "ap-northeast-2" = "ami-0662f4965dfc70aca"
    # Osaka
    "ap-northeast-3" = "ami-0aafffc426e129572"
    # Central Canada
    "ca-central-1" = "ami-0c0a551d0459e9d39"
    # Stockholm
    "eu-north-1" = "ami-042b4708b1d05f512"
    # Ireland
    "eu-west-1" = "ami-01f23391a59163da9"
    # London
    "eu-west-2" = "ami-044415bb13eee2391"
    # Paris
    "eu-west-3" = "ami-04ec97dc75ac850b1"
    # São Paulo
    "sa-east-1" = "ami-0a174b8e659123575"
    
  }
}



variable "instance_type" {
  description = "EC2 instance tipi"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "AWS EC2 için SSH key pair ismi"
  type        = string
}

variable "public_key_path" {
  description = "Yerel makinedeki SSH public key dosyasının tam yolu"
  type        = string
}

variable "private_key_path" {
  description = "Yerel makinedeki SSH private key dosyasının tam yolu"
  type        = string
}

