!/bin/bash
export ARM_SUBSCRIPTION_ID=$TERRAFORM_SP_SUBSCRIPTIONID
export ARM_TENANT_ID=$TERRAFORM_SP_TENANTID
export ARM_CLIENT_ID=$TERRAFORM_SP_APPLICATIONID
export ARM_CLIENT_SECRET=$MAPPED_TERRAFORM_SP_SECRET
export ARM_ACCESS_KEY=$MAPPED_TERRAFORM_ACCESS_KEY
cd ./terraform
terraform init
terraform destroy -var-file=./environment/dev.tfvars.json -auto-approve
