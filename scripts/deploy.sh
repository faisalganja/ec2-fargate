#!/bin/bash

set -e

CLUSTER_NAME="jenkins-test-ecs-cluster-dev"
SERVICE_NAME="jenkins-test-nginx-demo-service-dev"

echo "=== ECS Deployment Status ==="

# Check cluster
echo "Cluster status:"
aws ecs describe-clusters --clusters $CLUSTER_NAME

# Check services
echo "Service status:"
aws ecs describe-services \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME

# List running tasks
echo "Running tasks:"
aws ecs list-tasks --cluster $CLUSTER_NAME

# Check EC2 instance
echo "EC2 instance status:"
aws ec2 describe-instances --instance-ids i-061e5f495196bc411 \
    --query 'Reservations[0].Instances[0].State.Name'

echo "=== Deployment Complete ==="