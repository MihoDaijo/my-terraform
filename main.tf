terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket       = "my-terraform-tfstate-mihodaijo"
    key          = "terraform/state.tfstate"
    region       = "ap-northeast-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

module "vpc" {
  source         = "./modules/vpc"
  vpc_cidr_block = var.vpc_cidr_block
  instance_name  = var.instance_name
}

module "subnet" {
  source              = "./modules/subnet"
  vpc_id              = module.vpc.vpc_id
  public_subnet_cidr  = var.public_subnet_cidr
  availability_zone   = var.availability_zone
  instance_name       = var.instance_name
}

module "igw" {
  source        = "./modules/igw"
  vpc_id        = module.vpc.vpc_id
  instance_name = var.instance_name
}

module "route" {
  source            = "./modules/route"
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.subnet.subnet_id
  internet_gateway_id = module.igw.internet_gateway_id
  instance_name     = var.instance_name
}

module "security_group" {
  source        = "./modules/security_group"
  vpc_id        = module.vpc.vpc_id
  instance_name = var.instance_name
  my_home_ip    = var.my_home_ip
}

module "ec2" {
  source            = "./modules/ec2"
  ami_id            = data.aws_ami.al2023.id
  instance_type     = var.instance_type
  key_name          = var.key_name
  subnet_id         = module.subnet.subnet_id
  security_group_id = module.security_group.security_group_id
  instance_name     = var.instance_name
}
