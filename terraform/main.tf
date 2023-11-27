
terraform {
  backend "s3" {
    bucket         = "movie-summary-tf-state"  # replace with your bucket name
    key            = "production/movie-summarization/terraform.tfstate"
    region         = "us-west-2"  # replace with your bucket's region
    dynamodb_table = "movie-summary-tf-state"  # replace with your DynamoDB table name
    encrypt        = true
  }
}

provider "aws" {
  region = "us-west-2"  # or your preferred region
}