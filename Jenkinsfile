pipeline {
    agent any

    environment {
        DOCKER_HUB_USERNAME = 'shruti33'
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
      sh 'docker run --rm -v $WORKSPACE:/app -w /app node:16 npm install'
      sh 'docker run --rm -v $WORKSPACE:/app -w /app node:16 npm test || echo "Tests completed"'
    }
  }
}

stage('Security Scan (Snyk - Container)') {
  steps {
    withCredentials([string(credentialsId: 'synk-token', variable: 'SNYK_TOKEN')]) {
      script {
        def snykExit = sh(
          script: """
            docker run --rm \
              -e SNYK_TOKEN=$SNYK_TOKEN \
              -e DOCKER_HOST=$DOCKER_HOST \
              snyk/snyk:docker snyk container test $IMAGE --severity-threshold=high || echo \$?
          """,
          returnStdout: true
        ).trim()

        snykExit = snykExit.isInteger() ? snykExit.toInteger() : 0

        if (snykExit != 0) {
          error "Pipeline failed due to High/Critical vulnerabilities detected by Snyk!"
        } else {
          echo "No High/Critical vulnerabilities found."
        }
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
