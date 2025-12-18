#!/bin/bash

set -e  # Exit on any error
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/stacks_config.sh" 


# Validate TF backend bucket
if [ -z "$TF_STATE_BUCKET_NAME" ]; then
  echo "❌ ERROR: TF_STATE_BUCKET_NAME is required"; exit 1
fi

echo "Deploying realtime-trading-pipeline Infrastructure..."
echo "Backend region: $TF_STATE_BUCKET_REGION"
echo "Deployment region: ${AWS_REGION:-<not-set>}"

echo "Checking backend S3 bucket..."
if ! aws s3 ls "s3://$TF_STATE_BUCKET_NAME" --region "$TF_STATE_BUCKET_REGION" >/dev/null 2>&1; then
  echo "Creating backend bucket..."
  aws s3 mb "s3://$TF_STATE_BUCKET_NAME" --region "$TF_STATE_BUCKET_REGION"
  aws s3api put-bucket-versioning --bucket "$TF_STATE_BUCKET_NAME" --versioning-configuration Status=Enabled --region "$TF_STATE_BUCKET_REGION"
fi

# -----------------------------
# Function to deploy a stack
# -----------------------------
deploy_stack() {
  local stack="$1"
  echo "🟦 Deploying: $stack"

  terraform -chdir="stages/$stack" init -reconfigure -upgrade \
    -backend-config="bucket=$TF_STATE_BUCKET_NAME" \
    -backend-config="key=stages/$stack/terraform.tfstate" \
    -backend-config="region=$TF_STATE_BUCKET_REGION"

  terraform -chdir="stages/$stack" apply \
    ${STACK_VARS[$stack]} \
    -var aws_region=$AWS_REGION \
    -auto-approve

  echo "✅ Done: $stack"
}

# -----------------------------
# DEPLOY ORDER
# -----------------------------

echo "🚀 Starting Kinesis Trading System Deployment..."

deploy_stack "foundation"
deploy_stack "data-streaming"

echo "Pushing Docker images to ECR..."
./scripts/deployment-automation-scripts/pull-dockerhub-to-ecr.sh
ECR_IMAGE_URI=$(cat scripts/runtime/producer-ecr-image-uri)
STACK_VARS["producers"]+=" -var ecr_image_uri=$ECR_IMAGE_URI"

deploy_stack "producers"
deploy_stack "consumers"
deploy_stack "analytics"


echo "✅ Deployment Complete!"
