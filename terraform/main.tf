terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

data "aws_subnet" "default" {
  for_each = toset(data.aws_subnets.default.ids)
  id       = each.value
}

data "aws_ec2_instance_type_offerings" "available" {
  location_type = "availability-zone"

  filter {
    name   = "instance-type"
    values = [var.instance_type]
  }

  filter {
    name   = "location"
    values = data.aws_availability_zones.available.names
  }
}

locals {
  supported_azs = toset(data.aws_ec2_instance_type_offerings.available.locations)
  supported_default_subnet_ids = [
    for s in data.aws_subnet.default : s.id
    if contains(local.supported_azs, s.availability_zone)
  ]
}

resource "aws_security_group" "ec2" {
  name        = "ec2-server-sg"
  description = "Basic security group for EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-server-sg"
  }
}

resource "aws_instance" "main" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = local.supported_default_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  lifecycle {
    precondition {
      condition     = length(local.supported_default_subnet_ids) > 0
      error_message = "No default subnet found in an AZ that supports the selected instance type. Choose a different instance type or provide a subnet in a supported AZ."
    }
  }

  tags = {
    Name = var.instance_name
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region for the EC2 instance"
  default     = "us-east-1"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "instance_name" {
  type        = string
  description = "Tag name for the instance"
  default     = "terraform-ec2"
}

output "instance_id" {
  value = aws_instance.main.id
}

output "public_ip" {
  value = aws_instance.main.public_ip
}
