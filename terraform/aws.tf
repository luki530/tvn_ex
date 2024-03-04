provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "tf-state-lo"
    key    = "state/terraform.tfstate"
    region = "eu-central-1"
  }
}
