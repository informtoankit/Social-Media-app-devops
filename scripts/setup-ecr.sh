#!/bin/bash
aws ecr create-repository \
  --repository-name instaclone-backend \
  --region ap-south-1 \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=AES256

aws ecr create-repository \
  --repository-name instaclone-frontend \
  --region ap-south-1 \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=AES256

echo "ECR repositories created successfully."
