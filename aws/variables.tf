variable "vpc_name" {
    description = "vpc default name"
    default = "def_tf_vpc"
    type = string
}

variable "vpc_cidr" {
    description = "vpc cidr"
    default = "10.0.0.0/24"
    type = string
}


variable "vpc_az" {
    description = "Availability zones for vpc"
    type        = list(string)
    default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "vpc_private_subnets" {
  description = "Private subnets for VPC"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "vpc_public_subnets" {
  description = "Public subnets for VPC"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "vpc_enable_nat_gateway" {
  description = "Enable NAT gateway for VPC"
  type    = bool
  default = true
}

variable "vpc_tags" {
  description = "Tags to apply to resources created by VPC module"
  type        = map(string)
  default     = {
    Terraform   = "true"
    Environment = "dev"
  }
}


variable "ec2_ubuntu_ami" {
  description = "AMI Id of ubuntu 20.0 image"
  default = "ami-0885b1f6bd170450c"
  type = string
}

