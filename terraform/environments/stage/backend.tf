# Terraform State Backend Configuration
# Store state in S3 with DynamoDB locking for team collaboration

terraform {
  backend "s3" {
    bucket         = "calldata-foundation-terraform-state"
    key            = "stage/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "calldata-foundation-terraform-locks"
  }
}
