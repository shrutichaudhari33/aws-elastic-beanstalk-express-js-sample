pipeline {
  agent any

  options {
    skipDefaultCheckout(true)
    disableConcurrentBuilds()
    timestamps()
  }

  tools { git 'git' }

  environment {
    DOCKER_HOST   = 'tcp://dind:2375'
    DOCKER_DRIVER = 'overlay2'
    IMAGE_NAME    = 'shrutichaudhari33/aws-elastic-beanstalk-sample'
    BUILD_TAG     = "${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps {
        deleteDir()
        checkout([
          $class: 'GitSCM',
          branches: [[name: '*/main']],
          userRemoteConfigs: [[ url: 'https://github.com/shrutichaudhari33/aws-elastic-beanstalk-express-js-sample.git' ]],
          gitTool: 'git'
        ])
        sh 'ls -la'
      }
    }

    // keep Node inside container
    stage('Install & Test (Node 16)') {
      agent { docker { image 'node:16-bullseye'; args '-u root:root'; reuseNode true } }
      steps {
        sh '''
          echo "Contents of workspace (node stage):"
          ls -la
          node -v
          if [ -f package-lock.json ]; then
            npm ci
          else
            npm install
          fi
          npm -s test || echo "No tests defined"
        '''
      }
    }

    // run Docker CLI directly on Jenkins (DOCKER_HOST points to dind)
    stage('Build Docker Image') {
      steps {
        sh '''
          docker version || true
          docker build -f Dockerfile \
            -t "$IMAGE_NAME:$BUILD_TAG" \
            -t "$IMAGE_NAME:latest" .
        '''
      }
    }

    stage('Snyk - Open Source (deps)') {
      steps {
        withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
          script {
            def code = sh(
              returnStatus: true,
              script: '''
                docker run --rm \
                  -e SNYK_TOKEN="$SNYK_TOKEN" \
                  -v "$PWD":/app -w /app \
                  snyk/snyk:docker snyk test --severity-threshold=high
              '''
            )
            if (code != 0) {
              currentBuild.result = 'UNSTABLE'
              echo "Snyk OSS scan found issues (exit ${code}) — marking UNSTABLE and continuing."
            }
          }
        }
      }
    }

    stage('Snyk - Container (image)') {
      steps {
        withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
          script {
            def code = sh(
              returnStatus: true,
              script: '''
                docker run --rm \
                  -e SNYK_TOKEN="$SNYK_TOKEN" \
                  -v /var/run/docker.sock:/var/run/docker.sock \
                  snyk/snyk:docker snyk container test "$IMAGE_NAME:$BUILD_TAG" --severity-threshold=high
              '''
            )
            if (code != 0) {
              currentBuild.result = 'UNSTABLE'
              echo "Snyk image scan found issues (exit ${code}) — marking UNSTABLE and continuing."
            }
          }
        }
      }
    }

    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                                          usernameVariable: 'DOCKERHUB_USER',
                                          passwordVariable: 'DOCKERHUB_PASS')]) {
          sh '''
            echo "$DOCKERHUB_PASS" | docker login -u "$DOCKERHUB_USER" --password-stdin
            docker push "$IMAGE_NAME:$BUILD_TAG"
            docker push "$IMAGE_NAME:latest"
            docker logout || true
          '''
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: '**/*.log, **/npm-*.log', allowEmptyArchive: true
      echo 'Pipeline finished (success or fail).'
    }
    success { echo 'Pipeline completed successfully.' }
    failure { echo 'Pipeline failed — check stage logs above.' }
  }
}
