pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_REGION = 'us-east-1'
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/faisalganja/ec2-fargate.git',
                    branch: 'main',
                    credentialsId: 'github-pipeline'
            }
        }

        stage('Deploy') {
            steps {
                sh 'cd scripts && chmod +x deploy.sh && ./deploy.sh'
            }
        }
    }
}
