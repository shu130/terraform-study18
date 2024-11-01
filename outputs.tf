# ./outsputs.tf

#---------------
# vpc
#---------------
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  value = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "internet_gateway_id" {
  value = module.vpc.igw_id
}

output "public_route_table_ids" {
  value = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  value = module.vpc.private_route_table_ids
}

output "default_security_group_id" {
  value = module.vpc.default_security_group_id
}


#---------------
# IAM
#---------------
output "iam_role_arn" {
  value = module.iam_assumable_role.iam_role_arn
}

output "ec2_instance_profile_arn" {
  value = aws_iam_instance_profile.ec2_instance_profile.arn
}
#---------------
# EC2
#---------------
output "instance_id" {
  value = module.ec2_instance.id
}

output "public_ip" {
  value = module.ec2_instance.public_ip
}

output "private_ip" {
  value = module.ec2_instance.private_ip
}

#---------------
# S3
#---------------
output "s3_bucket_name" {
  value = module.s3_bucket.s3_bucket_id
}

output "s3_bucket_arn" {
  value = module.s3_bucket.s3_bucket_arn
}

output "s3_bucket_domain_name" {
  value = module.s3_bucket.s3_bucket_bucket_domain_name
}