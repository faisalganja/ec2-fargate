#!/bin/bash

export AWS_DEFAULT_REGION="us-east-1"
CLUSTER_NAME="jenkins-test-ecs-cluster-dev"

echo "=== Registering Task Definition (No ECR needed) ==="

# Register task definition with public Nginx from Docker Hub
aws ecs register-task-definition \
    --family nginx-public-task \
    --network-mode bridge \
    --container-definitions '[
        {
            "name": "nginx",
            "image": "nginx:alpine",
            "memory": 256,
            "cpu": 128,
            "essential": true,
            "portMappings": [
                {
                    "containerPort": 80,
                    "hostPort": 80,
                    "protocol": "tcp"
                }
            ]
        }
    ]' \
    --requires-compatibilities EC2

echo "✅ Task definition registered: nginx-public-task"

# Check if EC2 instance is registered with cluster
CONTAINER_INSTANCE=$(aws ecs list-container-instances \
    --cluster $CLUSTER_NAME \
    --query 'containerInstanceArns[0]' \
    --output text)

if [ "$CONTAINER_INSTANCE" != "None" ] && [ -n "$CONTAINER_INSTANCE" ]; then
    echo "Found EC2 instance, running task..."
    
    # Run the task
    TASK_ARN=$(aws ecs run-task \
        --cluster $CLUSTER_NAME \
        --task-definition nginx-public-task \
        --count 1 \
        --query 'tasks[0].taskArn' \
        --output text)
    
    echo "✅ Task is running: $TASK_ARN"
    
    # Wait a few seconds for task to start
    sleep 5
    
    # Get task details
    echo ""
    echo "=== Task Details ==="
    aws ecs describe-tasks \
        --cluster $CLUSTER_NAME \
        --tasks $TASK_ARN \
        --query 'tasks[0].{status:lastStatus,container:containers[0].name,image:containers[0].image}'
    
else
    echo ""
    echo "⚠️  No EC2 instances registered with ECS cluster"
    echo ""
    echo "To fix this, SSH to your EC2 instance and run:"
    echo "================================================"
    echo "sudo amazon-linux-extras install ecs -y"
    echo "echo 'ECS_CLUSTER=$CLUSTER_NAME' | sudo tee -a /etc/ecs/ecs.config"
    echo "sudo start ecs"
    echo "sudo status ecs"
    echo "================================================"
fi

echo ""
echo "=== Deployment Complete ==="
