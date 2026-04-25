pipeline {
    agent any

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/Naveen145-ai/dev.git'
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                sh '''
                cd terraform
                terraform init
                terraform apply -auto-approve
                terraform output -raw instance_ip > ../ec2_ip.txt
                '''
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                sh '''
                docker build -t naveen-html-app .
                docker tag naveen-html-app:latest $DOCKER_REGISTRY/naveen-html-app:latest
                docker push $DOCKER_REGISTRY/naveen-html-app:latest
                '''
            }
        }

        stage('Deploy to EC2') {
            steps {
                sh '''
                EC2_IP=$(cat ec2_ip.txt)
                ssh -i $SSH_KEY_PATH ec2-user@$EC2_IP "docker pull $DOCKER_REGISTRY/naveen-html-app:latest && docker run -d -p 3000:80 naveen-html-app"
                echo "✓ Deployed at http://$EC2_IP:3000"
                '''
            }
        }
    }
}
