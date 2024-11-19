provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

terraform {
  backend "s3" {
    profile = var.aws_profile
    region  = var.aws_region
    bucket  = var.s3_bucket
    key     = var.env_name
  }
}
