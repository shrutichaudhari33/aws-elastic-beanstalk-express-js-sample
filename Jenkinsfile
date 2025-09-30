pipeline {
  agent any

  environment {
    APP_IMAGE = "myapp"   
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Install & Test (Node 16)') {
      steps {
        script {
          docker.image('node:16').inside {
            sh 'npm install --save'
            sh 'npm test || true'   
          }
        }
      }
    }

    stage('Security Scan (Snyk)') {
      steps {
        script {
          docker.image('node:16').inside {
            sh 'apt-get update -y && apt-get install -y jq || true'
            sh 'npm install -g snyk || true'

            withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
              sh '''
                echo "$SNYK_TOKEN" | snyk auth || true
                snyk test --json > snyk.json || true

                if [ ! -s snyk.json ]; then
                  echo "snyk.json missing -> failing"
                  exit 1
                fi

                if cat snyk.json | jq -r '.vulnerabilities[]?.severity' | grep -E 'high|critical'; then
                  echo "High/Critical vulnerability detected!"
                  exit 1
                else
                  echo "No high/critical vulnerabilities."
                fi
              '''
            }
          }
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build -t ${APP_IMAGE}:${BUILD_NUMBER} .'
      }
    }

    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker tag ${APP_IMAGE}:${BUILD_NUMBER} ${DOCKER_USER}/${APP_IMAGE}:latest
            docker push ${DOCKER_USER}/${APP_IMAGE}:latest
          '''
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'snyk.json, **/test-results/*.xml', allowEmptyArchive: true
    }
  }
}
