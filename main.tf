
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
     github = {
      source = "integrations/github"
      version = "~> 5.0"  # Usa la versión adecuada del proveedor de GitHub
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}


# Create a VPC
resource "aws_vpc" "inmo_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "inmo_vpc"
  }
}

#Ip Elastica
resource "aws_eip" "inmo_eip" {
    public_ipv4_pool = "amazon"

    tags={
        Name="inmo_eip"
    }
}

# Subnet Publica

resource "aws_subnet" "inmo_subnet_publica" {
        vpc_id     = aws_vpc.inmo_vpc.id
        cidr_block = "10.0.100.0/24" 
        map_public_ip_on_launch = true

        tags = {
            Name = "inmo_subnet_publica"
        }
}

#Subnet Privada
resource "aws_subnet" "inmo_subnet_privada" {
  vpc_id     = aws_vpc.inmo_vpc.id
  cidr_block = "10.0.1.0/24" 

  tags = {
    Name = "inmo_subnet_privada"
  }
} 

#crear un aws internet gateway (puerta de enlace a internet)
resource "aws_internet_gateway" "inmo_internet_gateway" {
  vpc_id = aws_vpc.inmo_vpc.id

  tags = {
    Name = "inmo_internet_gateway"
  }
}

resource "aws_nat_gateway" "inmo_nat_gateway" {
  allocation_id = aws_eip.inmo_eip.id
  connectivity_type = "public"
  subnet_id     = aws_subnet.inmo_subnet_publica.id

  tags = {
    Name = "inmo_nat_gateway"
  }
}


resource "aws_route_table" "inmo_route_table" {
  vpc_id = aws_vpc.inmo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.inmo_internet_gateway.id
  }

  tags = {
    Name = "inmo_route_table"
  }
}

resource "aws_route_table_association" "inmo_route_table_association" {
  subnet_id      = aws_subnet.inmo_subnet_publica.id
  route_table_id = aws_route_table.inmo_route_table.id
}


variable "instance_type" {
  default = "t2.micro"
}

variable "ami_id"{
  default = "ami-0866a3c8686eaeeba"
}



# Grupo de seguridad para permitir HTTP y SSH
resource "aws_security_group" "security" {
   vpc_id      = aws_vpc.inmo_vpc.id
  name        = "security"
  description = "Allow HTTP on port 80 and SSH on port 22"

  # Regla para permitir tráfico HTTP (puerto 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permitir desde cualquier IP
  }

  # Regla para permitir tráfico SSH (puerto 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permitir desde cualquier IP (puedes restringirlo a una IP específica por seguridad)
  }

  
}



resource "aws_instance" "inmo_instance" {

  # Script para instalar Apache
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update 
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo systemctl enable apache2
              EOF

  # Configuración de la red
  subnet_id = aws_subnet.inmo_subnet_publica.id 
  associate_public_ip_address = true

 
  # Tags (opcional)
  tags = {
    Name = "inmo_instance"
  }
}


//GITHUB

provider "github" {
  token = var.github_token 
  owner = "carmenOV" 
}

variable "github_token" {
  type        = string
  description = "inmo"
}