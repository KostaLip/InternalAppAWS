terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
    archive = {
        source = "hashicorp/archive"
        version = "~> 2.4"
    }
    awscc = {
      source = "hashicorp/awscc"
      version = "~> 1.94.0"
    }
  }
}

provider "aws" {
  alias = "compute"
  profile = "compute"
  region = "eu-central-1"
}

provider "aws" {
  alias = "management"
  profile = "management"
  region = "eu-central-1"
}

provider "aws" {
  alias = "storage-datasync"
  profile = "storage-datasync"
  region = "eu-central-1"
}

provider "aws" {
  alias = "storage-s3"
  profile = "storage-s3"
  region = "eu-central-1"
}

provider "awscc" {
  alias = "storage-datasync"
  profile = "storage-datasync"
  region = "eu-central-1"
}