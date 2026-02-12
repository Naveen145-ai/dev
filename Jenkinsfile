pipeline {
    agent any

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Naveen145-ai/dev.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t naveen-html-app .'
            }
        }

        stage('Stop Old Container') {
            steps {
                sh '''
                docker stop html-container || true
                docker rm html-container || true
                '''
            }
        }

        stage('Run New Container') {
            steps {
                sh 'docker run -d -p 3000:80 --name html-container naveen-html-app'
            }
        }
    }
}
