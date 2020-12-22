# Terraform configuration

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# All the configuration will be from the environment variables
provider "aws" {} 

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.vpc_az
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_nat_gateway = var.vpc_enable_nat_gateway

  tags = var.vpc_tags
}

module "ec2_instances" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.12.0"

  name           = "my-ec2-cluster"
  instance_count = 2

  ami                    = var.ec2_ubuntu_ami
  instance_type          = "t2.micro"
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  subnet_id              = module.vpc.public_subnets[0]

  depends_on = [aws_internet_gateway.gw]
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Create internet gateway
module "aws" "gw" {
    // Breakdown -  aws_vpc is the resouce created, var.vpc_name is the acutal resouce created by terraform and id si the o/p from that
  vpc_id = ${aws_vpc.var.vpc_name.id}
  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}
