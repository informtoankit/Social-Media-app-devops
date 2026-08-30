# terraform {
#   backend "s3" {
#     bucket         = "instaclone-terraform-state-ankit-2026"
#     key            = "vpc/terraform.tfstate"
#     region         = "ap-south-1"
#     encrypt        = true
    
#   }
# }

terraform {
  backend "s3" {
    bucket       = "instaclone-terraform-state-ankit-2026"
    key          = "vpc/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    # use_lockfile = true
    dynamodb_table = "terraform-state-lock"
  }
}


# terraform {
#   backend "s3" {
#     bucket         = "instaclone-terraform-state-ankit-2026"
#     key            = "vpc/terraform.tfstate"
#     region         = "ap-south-1"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"
#   }
# }
