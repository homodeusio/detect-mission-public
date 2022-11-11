terraform {
  backend "s3" {
    bucket = "xxxxxxxxx"
    key    = "xxxxxxxx"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "primary"
}

provider "aws" {
  alias  = "secondary"
  region = "us-east-2"
}


data "aws_availability_zones" "region_p" {
  state    = "available"
  provider = aws.primary
}

data "aws_availability_zones" "region_s" {
  state    = "available"
  provider = aws.secondary
}