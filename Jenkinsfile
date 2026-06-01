pipeline {
    agent any
    
    environment {
        // AWS Configuration
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '334602886949'
        
        // GitHub Repository
        GITHUB_REPO_URL = 'https://github.com/your-username/ecs-ec2-deployment.git'
        GITHUB_BRANCH = 'main'
        GITHUB_CREDENTIALS_ID = 'github-credentials'
        
        // Existing Infrastructure
        VPC_ID = 'vpc-0a50cc4ac4e8a35a2'
        SUBNET_ID = 'subnet-07ad08c764de99943'
        SECURITY_GROUP = 'sg-058edc7c938d1cde0'
        INSTANCE_ID = 'i-061e5f495196bc411'
        
        // ECS Configuration
        APP_CODE = 'jenkins-test'
        AWS_ENV = 'dev'
        VPC_CODE = 'project'
        S3_BUCKET = 'ec2-fargate'
        STACK_NAME = "${APP_CODE}-ecs-main"
        APP_NAME = 'nginx-demo'
    }
    
    stages {
        stage('Checkout from GitHub') {
            steps {
                echo 'Cloning repository from GitHub...'
                git branch: "${GITHUB_BRANCH}",
                    url: "${GITHUB_REPO_URL}",
                    credentialsId: "${GITHUB_CREDENTIALS_ID}"
                
                echo 'Repository contents:'
                sh 'ls -la'
            }
        }
        
        stage('Validate CloudFormation Templates') {
            steps {
                script {
                    sh '''
                        echo "Validating CloudFormation templates..."
                        
                        # Validate each template
                        for template in cloudformation/*.yml; do
                            echo "Validating $template"
                            aws cloudformation validate-template \
                                --template-body file://$template
                        done
                    '''
                }
            }
        }
        
        stage('Upload Templates to S3') {
            steps {
                script {
                    sh '''
                        echo "Uploading CloudFormation templates to S3..."
                        
                        # Create S3 bucket if it doesn't exist
                        if ! aws s3 ls "s3://${S3_BUCKET}" 2>&1 > /dev/null; then
                            aws s3 mb "s3://${S3_BUCKET}" \
                                --region ${AWS_DEFAULT_REGION}
                        fi
                        
                        # Upload templates
                        aws s3 sync cloudformation/ \
                            "s3://${S3_BUCKET}/cloudformation/" \
                            --exclude "*.swp"
                        
                        echo "Templates uploaded to s3://${S3_BUCKET}/cloudformation/"
                    '''
                }
            }
        }
        
        stage('Deploy ECS Cluster via CloudFormation') {
            steps {
                script {
                    sh '''
                        echo "Deploying ECS Cluster stack..."
                        
                        # Deploy main stack
                        aws cloudformation deploy \
                            --template-file cloudformation/ecs-main.yml \
                            --stack-name ${STACK_NAME} \
                            --parameter-overrides \
                                awsEnv=${AWS_ENV} \
                                appCode=${APP_CODE} \
                                vpcCode=${VPC_CODE} \
                                s3ArtifactPath=${S3_BUCKET}/cloudformation \
                            --capabilities CAPABILITY_IAM \
                            --no-fail-on-empty-changeset
                        
                        # Wait for stack completion
                        aws cloudformation wait stack-create-complete \
                            --stack-name ${STACK_NAME} || \
                        aws cloudformation wait stack-update-complete \
                            --stack-name ${STACK_NAME}
                        
                        echo "Stack deployment complete!"
                        
                        # Get outputs
                        aws cloudformation describe-stacks \
                            --stack-name ${STACK_NAME} \
                            --query 'Stacks[0].Outputs'
                    '''
                }
            }
        }
        
        stage('Deploy ECS Application') {
            steps {
                script {
                    sh '''
                        echo "Deploying ECS Application..."
                        
                        # Get ECR image (using nginx for testing)
                        IMAGE_URI="nginx:alpine"
                        
                        # Deploy app stack
                        aws cloudformation deploy \
                            --template-file cloudformation/ecs-app.yml \
                            --stack-name "${APP_CODE}-${APP_NAME}-app" \
                            --parameter-overrides \
                                awsEnv=${AWS_ENV} \
                                appCode=${APP_CODE} \
                                vpcCode=${VPC_CODE} \
                                appName=${APP_NAME} \
                                ecsImage=${IMAGE_URI} \
                                ecsDesiredCount=1 \
                                ecsContainerPort=80
                        
                        echo "Application deployed successfully!"
                    '''
                }
            }
        }
        
        stage('Verify ECS Task on EC2') {
            steps {
                script {
                    sh '''
                        echo "Verifying ECS task on EC2 instance..."
                        
                        # Get cluster name
                        CLUSTER_NAME="${APP_CODE}-ecs-cluster-${AWS_ENV}"
                        
                        # List tasks
                        echo "Tasks in cluster:"
                        aws ecs list-tasks --cluster ${CLUSTER_NAME}
                        
                        # Describe the service
                        echo "Service status:"
                        aws ecs describe-services \
                            --cluster ${CLUSTER_NAME} \
                            --services "${APP_CODE}-${APP_NAME}-service-${AWS_ENV}" \
                            --query 'services[0].{serviceName:serviceName,status:status,desiredCount:desiredCount,runningCount:runningCount}'
                        
                        # Get container instance details
                        CONTAINER_INSTANCE=$(aws ecs list-container-instances \
                            --cluster ${CLUSTER_NAME} \
                            --query 'containerInstanceArns[0]' \
                            --output text)
                        
                        if [ "${CONTAINER_INSTANCE}" != "None" ]; then
                            echo "Container instance: ${CONTAINER_INSTANCE}"
                            
                            aws ecs describe-container-instances \
                                --cluster ${CLUSTER_NAME} \
                                --container-instances ${CONTAINER_INSTANCE}
                        fi
                        
                        # Check if task is running on your specific EC2
                        echo "Checking if task is running on instance ${INSTANCE_ID}..."
                        echo "You can connect to the instance and run: docker ps"
                    '''
                }
            }
        }
        
        stage('Run Scripted Deployment') {
            steps {
                script {
                    sh '''
                        echo "Running deployment script..."
                        chmod +x scripts/deploy.sh
                        ./scripts/deploy.sh
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo '''
                ========================================
                DEPLOYMENT SUCCESSFUL!
                ========================================
                
                ECS Cluster: ${APP_CODE}-ecs-cluster-${AWS_ENV}
                Service: ${APP_CODE}-${APP_NAME}-service-${AWS_ENV}
                
                To check the deployment:
                1. Connect to your EC2 instance: ${INSTANCE_ID}
                2. Run: docker ps
                3. Check ECS console
                
                To test the application:
                ${INSTANCE_IP}:80 (if port 80 is exposed)
            '''
        }
        failure {
            echo 'Deployment failed! Check CloudFormation console for details.'
        }
    }
}