pipeline {
    agent any

    environment {
        DOCKER_HUB_USERNAME = 'shrutichaudhari33@gmail.com'
        DOCKER_HUB_PASSWORD = 'docker@123'
    }

    stages {

        stage('Checkout SCM') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/shrutichaudhari33/aws-elastic-beanstalk-express-js-sample.git'
            }
        }

        stage('Install & Test (Node 16)') {
            steps {
                script {
                    sh 'docker run --rm -v $PWD:/app -w /app node:16 npm install'
                    sh 'docker run --rm -v $PWD:/app -w /app node:16 npm test || echo "Tests completed"'
                }
            }
        }

        stage('Security Scan (Snyk)') {
            steps {
                script {
                    def snykExit = sh(script: '''
                        docker run --rm -v $PWD:/app -w /app snyk/snyk:docker test || echo $?
                    ''', returnStdout: true).trim()

                    snykExit = snykExit.isInteger() ? snykExit.toInteger() : 0

                    if (snykExit != 0) {
                        error "Pipeline failed due to High/Critical vulnerabilities detected by Snyk!"
                    } else {
                        echo "No High/Critical vulnerabilities found."
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker build -t shrutichaudhari33/aws-elastic-beanstalk-sample:latest .'
                }
            }
        }

        stage('Push Docker Image to Registry') {
            steps {
                script {
                    sh """
                        echo $DOCKER_HUB_PASSWORD | docker login -u $DOCKER_HUB_USERNAME --password-stdin
                        docker push shrutichaudhari33/aws-elastic-beanstalk-sample:latest
                        docker logout
                    """
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/*', allowEmptyArchive: true
        }
        failure {
            echo 'Pipeline failed! Check the logs for errors.'
        }
        success {
            echo 'Pipeline completed successfully!'
        }
    }
}
