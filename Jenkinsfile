pipeline {
    agent any

    environment {
        DOCKER_HOST = "tcp://dind:2375"
        DOCKER_DRIVER = "overlay2"
        DOCKER_TLS_VERIFY = ""
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/shrutichaudhari33/aws-elastic-beanstalk-express-js-sample.git'
            }
        }

        stage('Install & Test (Node 16)') {
            steps {
                sh '''
                  docker pull node:16
                  docker run --rm -v $PWD:/app -w /app node:16 sh -c "npm install && npm test"
                '''
            }
        }

        stage('Security Scan (Snyk)') {
            steps {
                sh '''
                  docker run --rm -v $PWD:/app -w /app snyk/snyk:docker snyk test --docker myapp:latest || true
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t myapp:latest .'
            }
        }

        stage('Push Docker Image to Registry') {
            steps {
                sh '''
                  echo "$DOCKER_HUB_PASSWORD" | docker login -u "$DOCKER_HUB_USERNAME" --password-stdin
                  docker tag myapp:latest $DOCKER_HUB_USERNAME/myapp:latest
                  docker push $DOCKER_HUB_USERNAME/myapp:latest
                '''
            }
        }
    }
}
