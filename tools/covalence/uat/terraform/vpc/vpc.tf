# AWS Virtual Private Cloud

## Variables
variable "enable_dns" {}

variable "enable_hostnames" {}

variable "region" {}

variable "stack_item_fullname" {}

variable "stack_item_label" {}

variable "vpc_cidr" {}

## Configures AWS provider
provider "aws" {
  region = "${var.region}"
}

## Configures base VPC
module "vpc_base" {
  source = "github.com/unifio/terraform-aws-vpc?ref=v0.3.8//base"

  stack_item_label    = "${var.stack_item_label}"
  stack_item_fullname = "${var.stack_item_fullname}"
  vpc_cidr            = "${var.vpc_cidr}"
  enable_dns          = "${var.enable_dns}"
  enable_hostnames    = "${var.enable_hostnames}"
}
