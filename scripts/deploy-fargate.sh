#!/bin/bash
# BEFORE (EC2)
aws cloudformation deploy \
    --template-file fargate/ecs-main.yml \
    --parameter-overrides \
        awsEnv=dev \
        appCode=myapp \
        ecsEc2InstanceType=t3.micro \    # ← REMOVE for Fargate
        ecsDesiredCount=2 \               # ← REMOVE for Fargate
        ecsMaxCapacity=4                  # ← REMOVE for Fargate

# AFTER (Fargate - same script works)
aws cloudformation deploy \
    --template-file fargate/ecs-main.yml \
    --parameter-overrides \
        awsEnv=dev \
        appCode=myapp