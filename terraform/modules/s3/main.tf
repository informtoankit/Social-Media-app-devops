# Main bucket jahan images store hongi
resource "aws_s3_bucket" "images" {
  bucket = "${var.project_name}-images-${var.environment}"

  tags = {
    Name = "${var.project_name}-images"
  }
}

# Versioning enable karo — accidental delete/overwrite se bachne ke liye
resource "aws_s3_bucket_versioning" "images" {
  bucket = aws_s3_bucket.images.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption — sab kuch automatically encrypted store ho
resource "aws_s3_bucket_server_side_encryption_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Public access block — koi bhi accidentally poora bucket public na kar de
resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CORS configuration — browser ko allow karta hai directly upload karne ke liye
resource "aws_s3_bucket_cors_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = var.allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Lifecycle policy — purani, incomplete uploads automatically clean karo
# resource "aws_s3_bucket_lifecycle_configuration" "images" {
#   bucket = aws_s3_bucket.images.id

#   rule {
#     id     = "cleanup-incomplete-uploads"
#     status = "Enabled"

#     abort_incomplete_multipart_upload {
#       days_after_initiation = 7
#     }
#   }
# }



resource "aws_s3_bucket_lifecycle_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    id     = "cleanup-incomplete-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}