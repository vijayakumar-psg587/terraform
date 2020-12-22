variable "var_tf_tag" {
  description = "Tag tat will used all over"
  type = map(string)
  default = {
    Terraform = true
    Environment = "tf_dev"
  }
}

variable "var_tf_bucket_name" {
  default = "tf-test-video-bucket"
  type = string
}

variable "var_tf_ec2_ami" {
  default = "ami-0885b1f6bd170450c"
  description = "Ubuntu AMI"
  type = string
}

variable "var_tf_vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "Cidr value for vpc"
  type = string
}

variable "var_tf_vpc_name" {
  default = "tf_vpc_name"
  description = "VPC name given for tf creation"
  type = string
}

variable "var_tf_vpc_tag" {
  description = "Tags to apply to resources created by VPC module"
  type = map(string)
  default     = {
    Terraform   = "true"
    Environment = "dev"
    Name = "vpc"
  }
}

variable "var_tf_ec2_tag" {
  description = "Tags to apply to resources created by ec2 module"
  type = map(string)
  default     = {
    Terraform   = "true"
    Environment = "dev"
    Name = "ec2"
  }
}


variable "var_tf_vpc_az" {
  description = "Availability zones for vpc"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "var_vpc_private_subnets" {
  description = "Private subnets for VPC"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "var_vpc_public_subnets" {
  description = "Public subnets for VPC"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "var_vpc_enable_nat_gateway" {
  description = "Enable NAT gateway for VPC"
  type    = bool
  default = true
}

variable "var_tf_ec2_ubuntu_name" {
  description = "Name of the ec2 ubuntu 20.0 image"
  default = "tf_ec2"
  type = string
}

variable "var_tf_route_table_tag" {
  description = "Tags to apply to resources created by Route table"
  type = map(string)
  default     = {
    Terraform   = "true"
    Environment = "dev"
    Name = "route-table"
  }
}