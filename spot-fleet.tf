terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

variable "arn" {
  type = string
  default = "211622251997"
}

variable "iam_role_name" {
  type = string
  default = "spot-fleet-role"
}

variable "key_name" {
  type = string
  default = "test"
}

variable "instance_type" {
  type = string
  default = "t2.micro"
}

variable "target_capacity" {
  type = number
  default = 1
}

variable "image_id" {
  type = string
  default = "ami-0230bd60aa48260c6"
}

variable "vpc_security_group_ids" {
  type = list(string)
  default = ["sg-0dc467f24e92d0dce"]
}

resource "aws_iam_role" "spot_fleet_role" {
  name = "${var.iam_role_name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "spotfleet.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  inline_policy {
    name = "spot-fleet-permissions"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeSubnets",
        "ec2:DescribeInstances",
        "ec2:DescribeImages",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribePlacementGroups",
        "ec2:DescribeVpcs",
        "ec2:DescribeKeyPairs"
      ],
      "Resource": "*"
    }
  ]
}
EOF
  }
}

resource "aws_launch_template" "spotfleet" {
  name                          = "spot-fleet-launch-template"
  image_id                      = "${var.image_id}"
  instance_type                 = "${var.instance_type}"
  key_name                      = "${var.key_name}"
  vpc_security_group_ids        = var.vpc_security_group_ids
}

resource "aws_spot_fleet_request" "spotfleet" {
  iam_fleet_role                = "arn:aws:iam::${var.arn}:role/${var.iam_role_name}"
  spot_price                    = "0.03"
  target_capacity               = var.target_capacity
  allocation_strategy           = "lowestPrice"
  fleet_type                    = "request"
  wait_for_fulfillment          = "true"
  terminate_instances_on_delete = "true"

  launch_template_config {
    launch_template_specification {
      id    = aws_launch_template.spotfleet.id
      version = aws_launch_template.spotfleet.latest_version
    }
  }
}