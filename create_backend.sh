#!/bin/bash
#
#

if [ -f /usr/local/bin/aws ] || [ $(which aws | wc -l | awk '{print$1}') -eq 1 ] ; then
   which aws
else
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.0.30.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  rm -rf aws rm awscliv2.zip
  aws version 
fi

aws s3api create-bucket \
  --bucket tf-state-pinf-bucket \
  --region us-east-1 \
  --profile terraform-admin

aws s3api head-bucket --bucket tf-state-pinf-bucket --region us-east-1 --profile terraform-admin

aws dynamodb create-table --profile terraform-admin \
  --table-name tf-pinf-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST 

aws dynamodb describe-table --table-name tf-pinf-locks --profile terraform-admin

