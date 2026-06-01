pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/faisalganja/ec2-fargate.git',
                    branch: 'main',
                    credentialsId: 'github-pipeline'
            }
        }

        stage('Deploy Task to ECS') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-dev']]) {
                    sh '''
                        cd scripts
                        chmod +x deploy.sh
                        ./deploy.sh
                    '''
                }
            }
        }

        stage('Verify') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-dev']]) {
                    sh '''
                        echo "=== ECS Status ==="
                        aws ecs list-tasks --cluster jenkins-test-ecs-cluster-dev
                        aws ecs describe-clusters --clusters jenkins-test-ecs-cluster-dev \
                            --query 'clusters[0].{runningTasks:runningTasksCount,pendingTasks:pendingTasksCount}'
                    '''
                }
            }
        }
    }
}
