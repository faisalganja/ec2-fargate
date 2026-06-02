#!/bin/bash

export AWS_DEFAULT_REGION="us-east-1"

# SAME names as your EC2 setup
CLUSTER_NAME="jenkins-test-ecs-cluster-dev"
TASK_FAMILY="nginx-web-fargate"  # Using slightly different name to avoid conflict
SUBNET="subnet-07ad08c764de99943"
SECURITY_GROUP="sg-058edc7c938d1cde0"

echo "========================================="
echo "Running FARGATE task (alongside EC2)"
echo "========================================="

# Step 1: Register Fargate task definition (with correct log config)
echo "Step 1: Registering Fargate task definition..."
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
                    "awslogs-region": "us-east-1",
                    "awslogs-stream-prefix": "nginx"
                }
            }
        }
    ]'

# Step 2: Create log group
aws logs create-log-group --log-group-name "/ecs/nginx-fargate" 2>/dev/null || true

# Step 3: Run a Fargate task (not a service)
echo "Step 2: Running Fargate task..."
TASK_ARN=$(aws ecs run-task \
    --cluster $CLUSTER_NAME \
    --task-definition $TASK_FAMILY \
    --launch-type FARGATE \
    --count 1 \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET],securityGroups=[$SECURITY_GROUP],assignPublicIp=ENABLED}" \
    --query 'tasks[0].taskArn' \
    --output text)

echo "Fargate Task ARN: $TASK_ARN"

# Step 4: Wait for task to start
echo "Step 3: Waiting for task to start..."
sleep 10

# Step 5: Show both EC2 and Fargate tasks
echo ""
echo "=== Current Tasks ==="
aws ecs list-tasks --cluster $CLUSTER_NAME

echo ""
echo "=== Task Details ==="
aws ecs describe-tasks \
    --cluster $CLUSTER_NAME \
    --tasks $TASK_ARN \
    --query 'tasks[0].{launchType:launchType,lastStatus:lastStatus,healthStatus:healthStatus}'

echo ""
echo "✅ Fargate task is running!"
echo "You now have BOTH EC2 and Fargate tasks in the same cluster!"