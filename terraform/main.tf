
terraform {
  backend "s3" {
    bucket         = "genai-prod-movie-summaries"
    key            = "production/movie-summarization/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "genai-prod-movie-summaries"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-west-2"
}