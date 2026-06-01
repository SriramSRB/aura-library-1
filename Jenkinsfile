pipeline {
    agent any

    stages {
        stage ('1. Checkout scm') {
            steps {
                checkout scm
            }
        }
        stage ('2. Build Docker Image') {
            steps {
                sh 'docker build -t aura-library-1:latest .'
            }
        }
        stage ('3. Push docker image to dockerhub') {
            steps {
                withCredentials([string(credentialsId: 'dockerhub', variable: 'DOCKER_PWD')]) {
                    sh 'echo "$DOCKER_PWD" | docker login -u sriramsrb --password-stdin'
                    sh 'docker push sriramsrb/aura-library-1:latest'
                }
            }
        }
        stage ('4. Deploy to kubernetes') {
            steps {
                sh 'kubectl apply -f deployment.yml'
                sh 'kubectl rollout restart deployment aura-library-deployment'
            }
        }
    }
}
