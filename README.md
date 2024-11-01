# Terraform勉強-第18回

github: "https://github.com/shu130/terraform-study18"

## テーマ

- Terraform公式モジュールを使用し、**VPC、EC2、S3、IAM** の各リソースを作成し、それぞれを連携させる
- Terraform公式モジュールの使い方に慣れる
- Terraform公式ドキュメントの使い方に慣れる
- 公式ドキュメントの各モジュールを参照しながらコード作成する

## 概要図
```markdown
+-----------------------------+
|           VPC               |
+-----------------------------+
| - Public Subnets            |
| - Private Subnets           |
| - Security Groups           |
+-----------------------------+
              |
              |
              v
+-----------------------------+
|        IAM Role             |
+-----------------------------+
| - Role Name: ec2-s3-readonly|
| - Policies:                 |
|   - AmazonS3ReadOnlyAccess  |
+-----------------------------+
              |
              |
              v
+-----------------------------+
|    Instance Profile         |
+-----------------------------+
| - Attached to IAM Role      |
+-----------------------------+
              |
              |
              v
+-----------------------------+
|       EC2 Instance          |
+-----------------------------+
| - AMI ID                    |
| - Instance Type             |
| - IAM Instance Profile      |
| - Security Group:           |
|   - Default Security Group  |
+-----------------------------+
              |
              |
              v
+-----------------------------+
|        S3 Bucket            |
+-----------------------------+
| - Bucket Name               |
| - Permissions: Read-Only    |
| - Force Destroy: Enabled    |
+-----------------------------+
              |
     (Read-only Access)
              |
              v
+-----------------------------+
|   EC2 -> S3 Access          |
+-----------------------------+
| - EC2 reads data from S3    |
+-----------------------------+
```

## ディレクトリ
```plaintext
.
├── main.tf
├── variables.tf
├── outputs.tf
├── provider.tf
└── terraform.tfvars
```

## 1. VPC

`terraform-aws-modules/vpc/aws`モジュールを使用

```hcl:./main.tf
# ./main.tf

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.14.0"

  name             = var.vpc_name
  cidr             = var.vpc_cidr
  azs              = var.azs
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets

  tags = merge(var.common_tags, var.vpc_tags)
}
```
> **merge関数**で`common_tags`と`vpc_tags`を合わせたマップを生成

#### 変数を定義：
```hcl:./variables.tf
# ./variables.tf

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
```

#### 変数の具体値を定義：
```hcl:./terraform.tfvars
# ./terraform.tfvars
#---------------
# 共通タグ
#---------------
common_tags = {
  project     = "study"
  Environment = "dev"
}
#---------------
# vpc
#---------------
vpc_name        = "my-vpc"
vpc_cidr        = "10.0.0.0/16"
azs             = ["us-west-2a", "us-west-2b"]
public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
private_subnets = ["10.0.2.0/24", "10.0.3.0/24"]
vpc_tags = {
  Name = "my-vpc"
}
```
---

## 2. IAMロールとインスタンスプロファイル

EC2インスタンスにS3の読み取り専用アクセスを許可するIAMロールを作成

```hcl:./main.tf
# ./main.tf

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
```

- **IAMロールの設定**：EC2がS3を読み取り専用でアクセスできるように、`AmazonS3ReadOnlyAccess`というポリシーをIAMロールに付与
- **インスタンスプロファイル**：EC2インスタンスにIAMロールを関連付けるために必要、  `aws_iam_instance_profile`リソースで、EC2インスタンス用のIAMロールを紐付け
- **`trunted_role_arns`**:   
この設定は、IAMロールをどのエンティティ（ユーザーやアカウント）が引き受けることができるか（Assumeすることができるか）を指定する信頼ポリシーを自動的に作成

#### 変数を定義：

```hcl:./variables.tf
# ./variables.tf

#---------------
# IAM
#---------------
variable "user_name" {
  type = string
}

variable "account_id" {
  type = string
}
```

#### 変数の具体値を定義：

```hcl:./terraform.tfvars
# ./terraform.tfvars

#---------------
# IAM
#---------------
# ユーザ名/アカウントID
user_name  = "example-user"
account_id = "xxxxxxxxxxxx"
```
---

### 3. EC2インスタンス

```hcl:./main.tf
# ./main.tf

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
```

- **`subnet_id`**: 作成されたパブリックサブネットの1つ目にインスタンスを配置
- **`iam_instance_profile`**: 前述のインスタンスプロファイルを関連付け
- **`associate_public_ip_address`**: パブリックIPアドレスを付与して、インターネット経由でアクセス可能にする

#### 変数を定義：

```hcl:./variables.tf
# ./variables.tf

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
```

#### 変数の具体値を定義：

```hcl:./terraform.tfvars
#---------------
# EC2
#---------------
instance_name = "my-ec2-instance"

# 無料枠AMI：Amazon Linux 2：
## (Kernel 5.10 AMI 2.0.20240916.0 x86_64 HVM gp2)
ami_id = "ami-033067239f2d2bfbc"

instance_type = "t2.micro"

ec2_tags = {
  Name = "my-ec2-instance"
}
```
---
## 4. S3バケット

```hcl:./main.tf
# main.tf

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
```

- **`force_destroy`**: 勉強用なのでバケットを削除する際にオブジェクトも同時に削除
- **`object_ownership`**と**`control_object_ownership`**: バケット内オブジェクトの所有権を制御する設定  

##### `object_ownership = "ObjectWriter"`:  
 - S3バケットにオブジェクトがアップロードされる際、**オブジェクトの所有権**が誰にあるのかを指定
 - `ObjectWriter`:
  - **アップロードしたユーザー**がオブジェクトの所有者
  - 例えば、他のAWSアカウントやIAMユーザーがオブジェクトをこのバケットにアップロードした場合、アップロードしたそのアカウントまたはユーザーがオブジェクトの所有者になる
- その他のオプションについて:
  - `BucketOwnerPreferred`: オブジェクトの所有権を**バケット所有者**に設定しバケット内の全オブジェクトを一括管理
  - `BucketOwnerEnforced`: オブジェクトはバケット所有者が必ず所有、  
  バケットのACLを無効化しオブジェクトの所有権が常にバケット所有者に設定
  - バケットを一元的に管理したい場合は、このような設定を利用する

##### `control_object_ownership = true`:  
- バケットのオブジェクト所有権の制御を有効にする設定  
- バケットレベルでのアクセス制御（ACL）を有効化するかどうかを決定
- `object_ownership`で指定したオプション（`ObjectWriter`）が適用される
- バケットレベルのACLやオブジェクト所有者の指定が機能し、**複数のアカウントが同じバケットを使う**ような設定が必要な場合に便利
- (メモ)**`control_object_ownership = false`**:
  - バケットのオブジェクト所有権の制御が無効化され、従来のバケットACLを使用する

#### 変数を定義：

```hcl:./variables.tf
# ./variables.tf

#---------------
# S3
#---------------

variable "s3_bucket_name" {
  type = string
}

variable "s3_tags" {
  type = map(string)
}
```

#### 変数の具体値を定義：

```hcl:./terraform.tfvars
# ./terraform.tfvars

#---------------
# S3
#---------------
# S3バケット名
s3_bucket_name = "s3-bucket10011757"

# タグ
s3_tags = {
  Name = "my-s3-bucket"
}
```
---
今回はここまでにしたいと思います。
