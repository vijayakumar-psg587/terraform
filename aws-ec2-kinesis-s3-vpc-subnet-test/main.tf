terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  // configurations for these will come from the environment var
}

// This creates kms key - which will be deleted in 7 days - THis is for sse
resource "aws_kms_key" "tf_kms_key" {
  description             = "KMS key is used to encrypt bucket objects"
  deletion_window_in_days = 7
  tags = var.var_tf_tag
}

// Create vpc isntance
resource "aws_vpc" "tf_vpc" {
  cidr_block = var.var_tf_vpc_cidr
  tags = var.var_tf_vpc_tag
}

// create IAM user
resource "aws_iam_user" "tf_iam_user" {
  name = "tf_iam_user"
  tags = {
    Name = "terraform iam user"
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_iam_role" "tf_iam_role" {
  name = "tf_iam_role_s3_ec2_kinesis"
  assume_role_policy = <<EOF
{
   "Version": "2012-10-17",
    "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ec2.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

data "aws_iam_policy_document" "tf_iam_policy_document" {
  statement {
    actions   = [
      "s3:*",
      "ec2:*",
      ]
    resources = ["*"]
    principals {
      identifiers = ["*"]
      type = "*"
    }
    effect = "Allow"
  }
}


resource "aws_iam_instance_profile" "tf_iam_instance_profile" {
  name = "tf_iam_instance_profile"
  role = aws_iam_role.tf_iam_role.name
}

resource "aws_iam_role_policy" "tf_iam_role_policy" {
  name = "tf_iam_role_policy"
  role = aws_iam_role.tf_iam_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "kinesisvideo:*",
                "s3:*",
                "ec2:*",
                "kinesis:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

// create internet gateway
resource "aws_internet_gateway" "tf_gateway" {
  vpc_id = aws_vpc.tf_vpc.id
  tags = {
    Name = "internet gateway"
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_egress_only_internet_gateway" "tf_egress_gw" {
  vpc_id = aws_vpc.tf_vpc.id
  tags = {
    Name = "Egress internet gateway"
    Terraform   = "true"
    Environment = "dev"
  }

}
// create custom route table
resource "aws_route_table" "tf_route_table" {
  vpc_id = aws_vpc.tf_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf_gateway.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.tf_gateway.id
  }

  tags = var.var_tf_route_table_tag
}
// subnet - this is where the webserver resides on
resource "aws_subnet" "tf_subnet" {
  cidr_block = var.var_vpc_private_subnets[0]
  vpc_id = aws_vpc.tf_vpc.id
  availability_zone = var.var_tf_vpc_az[0]
  tags = {
    Name = "Tf created subnet"
    Terraform   = "true"
    Environment = "dev"
    subnetType = "main"
  }
}

// subnet with route table
resource "aws_route_table_association" "tf_subnet_route_table_association" {
  route_table_id = aws_route_table.tf_route_table.id
  subnet_id = aws_subnet.tf_subnet.id
}
// security group to allow ssh, 80, 443
resource "aws_security_group" "tf_sec_group" {
  name        = "tf_sec_group"
  description = "Allow TLS inbound traffic"
  vpc_id = aws_vpc.tf_vpc.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 32000
    to_port     = 32200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Subnet Web Associated route table"
    Terraform   = "true"
    Environment = "dev"

  }
}
// network interface for above subnet
resource "aws_network_interface" "tf_nic" {
  subnet_id       = aws_subnet.tf_subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.tf_sec_group.id]

  tags = {
    Name = "TF created network interface"
    Terraform   = "true"
    Environment = "dev"
  }
}
// elastic ip for the above network interface
resource "aws_eip" "tf_eip" {
  instance = aws_instance.tf_aws_instance.id
  vpc      = true
  depends_on = [aws_instance.tf_aws_instance, aws_internet_gateway.tf_gateway]
  associate_with_private_ip = "10.0.1.50"
}
// ubuntu server
resource "aws_instance" "tf_aws_instance" {
  ami = var.var_tf_ec2_ami
  instance_type  = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.tf_iam_instance_profile.id
  availability_zone = var.var_tf_vpc_az[0]
  key_name = "ec2_key"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.tf_nic.id
  }
  user_data = <<-EOF
              #! /bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo this is web server >> /var/www/html/index.html'
              EOF
  tags = var.var_tf_ec2_tag
}


resource "aws_s3_bucket" "tf_s3_bucket" {
//  source = "terraform-aws-modules/s3-bucket/aws"
  bucket = var.var_tf_bucket_name
  policy = data.aws_iam_policy_document.tf_iam_policy_document.json
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
  server_side_encryption_configuration  {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.tf_kms_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
  tags = var.var_tf_tag

}
