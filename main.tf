# ./main.tf

#---------------
# vpc
#---------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.14.0"

  name = var.vpc_name
  cidr = var.vpc_cidr
  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  tags = merge(var.common_tags, var.vpc_tags)
}

#---------------
# IAM
#---------------
# AssumeRoleを作成し、
module "iam_assumable_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.47.1"

  create_role       = true
  role_requires_mfa = false
  role_name         = "ec2-s3-readonly-role"
  trusted_role_arns = [
    "arn:aws:iam::${var.account_id}:user/${var.user_name}"
  ]
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]
}

## インスタンスプロファイルに関連付ける
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-s3-readonly-profile"
  role = module.iam_assumable_role.iam_role_name
}

#---------------
# EC2
#---------------
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.7.1"

  name               = var.instance_name
  ami                = var.ami_id
  instance_type      = var.instance_type
  subnet_id          = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  associate_public_ip_address = true

  tags = merge(var.common_tags, var.ec2_tags)
}

#---------------
# S3
#---------------

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.2.1"

  bucket                   = var.s3_bucket_name
  object_ownership         = "ObjectWriter"
  control_object_ownership = true
  force_destroy            = true

  tags = merge(var.common_tags, var.s3_tags)
}

