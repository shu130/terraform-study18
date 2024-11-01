# ./variables.tf

#---------------
# provider,etc
#---------------
# プロファイル
variable "aws_profile" {
  type = string
}

# AWSのリージョン
variable "aws_region" {
  type = string
}

#---------------
# 共通タグ
#---------------
variable "common_tags" {
  type = map(string)
}

#---------------
# vpc
#---------------
variable "vpc_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "vpc_tags" {
  type = map(string)
}

#---------------
# IAM
#---------------
variable "user_name" {
  type = string
}

variable "account_id" {
  type = string
}

#---------------
# EC2
#---------------
variable "instance_name" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "ec2_tags" {
  type = map(string)
}

#---------------
# S3
#---------------

variable "s3_bucket_name" {
  type = string
}

variable "s3_tags" {
  type = map(string)
}