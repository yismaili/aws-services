#!/bin/bash

AWS_REGION="us-east-1"
PROJECT_NAME="vps"
ENVIRONMENT="dev"

ECR_REPOSITORY_URL=$(terraform output -raw ecr_repository_url)
ALB_DNS_NAME=$(terraform output -raw alb_dns_name)


# Get ECR login token
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPOSITORY_URL}

# Build Docker image
docker build -t ${PROJECT_NAME}:latest .

# Tag image
docker tag ${PROJECT_NAME}:latest ${ECR_REPOSITORY_URL}:latest

# Push image to ECR
docker push ${ECR_REPOSITORY_URL}:latest

#Update ECS service to use new image
 aws ecs update-service \
    --cluster vps-dev-cluster \
    --service vps-dev-service \
    --force-new-deployment \
    --region us-east-1

echo -e "Deployment complete!${NC}"
echo -e "Application URL: http://${ALB_DNS_NAME}${NC}"
echo -e "Note: It may take a few minutes for the service to be fully available.${NC}"