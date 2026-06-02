#!/bin/bash

export AWS_DEFAULT_REGION="us-east-1"

# THESE ARE THE SAME NAMES AS YOUR EC2 SETUP
CLUSTER_NAME="jenkins-test-ecs-cluster-dev"      # SAME cluster name
TASK_FAMILY="nginx-web"                          # SAME task family
SERVICE_NAME="myapp-nginx-app-service-dev"       # SAME service name

# Your existing VPC resources
SUBNET="subnet-07ad08c764de99943"
SECURITY_GROUP="sg-058edc7c938d1cde0"

echo "========================================="
echo "Converting to FARGATE (Keeping same names)"
echo "Cluster: $CLUSTER_NAME"
echo "Task Family: $TASK_FAMILY"
echo "Service: $SERVICE_NAME"
echo "========================================="

# Step 1: Delete the old EC2-based service (but keep cluster)
echo "Step 1: Removing EC2-based service..."
aws ecs delete-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --force 2>/dev/null || echo "Service may not exist"

# Wait for service deletion
sleep 10

# Step 2: Register NEW Fargate task definition with SAME family name
echo "Step 2: Registering Fargate task definition (same family name)..."
aws ecs register-task-definition \
    --family $TASK_FAMILY \
    --network-mode awsvpc \
    --requires-compatibilities FARGATE \
    --cpu 256 \
    --memory 512 \
    --execution-role-arn arn:aws:iam::334602886949:role/ecsTaskExecutionRole \
    --container-definitions '[
        {
            "name": "nginx",
            "image": "nginx:alpine",
            "essential": true,
            "portMappings": [{"containerPort": 80}],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "/ecs/nginx-fargate",
                    "awslogs-region": "us-east-1"
                }
            }
        }
    ]'

# Step 3: Create CloudWatch log group
aws logs create-log-group --log-group-name "/ecs/nginx-fargate" 2>/dev/null || true

# Step 4: Create NEW Fargate service with SAME name
echo "Step 3: Creating Fargate service (same service name)..."
aws ecs create-service \
    --cluster $CLUSTER_NAME \
    --service-name $SERVICE_NAME \
    --task-definition $TASK_FAMILY \
    --launch-type FARGATE \
    --desired-count 1 \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET],securityGroups=[$SECURITY_GROUP],assignPublicIp=ENABLED}"

# Step 5: Wait for service to be ready
echo "Step 4: Waiting for service to stabilize..."
sleep 15

# Step 6: Show status
echo ""
echo "=== FARGATE Service Status ==="
aws ecs describe-services \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --query 'services[0].{status:status,runningCount:runningCount,launchType:launchType,taskDefinition:taskDefinition}'

echo ""
echo "=== Running Tasks ==="
aws ecs list-tasks --cluster $CLUSTER_NAME

echo ""
echo "✅ SUCCESS! Same names, now running on FARGATE!"
echo "No EC2 instances needed!"