#!/bin/bash

BUCKET_NAME="mortgage-xpert-tfstate-$(aws sts get-caller-identity --query Account --output text)"
REGION="us-east-1"

echo "Creating S3 bucket for Terraform State: $BUCKET_NAME"

aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $REGION
