terraform {
  required_version = "= 1.2.8"

  backend "s3" {
    bucket         = "detect-terraform-trackit"
    key            = "terraform.state"
    region         = "eu-west-2"
    dynamodb_table = "detect-terraform-lock"
  }
}

provider "aws" {
  alias = "us-east-2"
  region = "us-east-2"
}

provider "aws" {
  alias = "eu-west-2"
  region = "eu-west-2"
}
