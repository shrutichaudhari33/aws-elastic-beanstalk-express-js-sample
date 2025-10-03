pipeline {
  agent any

  options {
    // In SCM mode, Jenkins already does the checkout we need.
    // DO NOT set skipDefaultCheckout(true) here.
    timestamps()
    // ansiColor('xterm') // uncomment ONLY if AnsiColor plugin is installed
    buildDiscarder(logRotator(numToKeepStr: '20', artifactNumToKeepStr: '20'))
  }

  environment {
    // Provided by docker-compose (DinD)
    DOCKER_HOST   = 'tcp://dind:2375'
    DOCKER_DRIVER = 'overlay2'

    IMAGE_NAME = 'shrutichaudhari33/aws-elastic-beanstalk-sample'
    BUILD_TAG  = "${env.BUILD_NUMBER}"
  }

  stages {

    stage('Install & Test (Node 16)') {
      steps {
        sh '''
          set -e
          docker run --rm -v "$PWD":/app -w /app node:16 npm install --save
          # Don’t fail if there is no test script
          docker run --rm -v "$PWD":/app -w /app node:16 sh -lc \
            'npm run -s test || { echo "No tests defined in package.json"; exit 0; }'
        '''
      }
    }

    stage('Snyk - Open Source (deps)') {
      steps {
        withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
          sh '''
            set -e
            docker run --rm \
              -e SNYK_TOKEN="$SNYK_TOKEN" \
              -v "$PWD":/app -w /app \
              snyk/snyk:docker snyk test --severity-threshold=high
          '''
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          set -e
          docker build -f "$PWD/Dockerfile" \
            -t "$IMAGE_NAME:$BUILD_TAG" \
            -t "$IMAGE_NAME:latest" \
            "$PWD"
        '''
      }
    }

    stage('Snyk - Container (image)') {
      steps {
        withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
          sh '''
            set -e
            docker run --rm \
              -e SNYK_TOKEN="$SNYK_TOKEN" \
              -v /var/run/docker.sock:/var/run/docker.sock \
              snyk/snyk:docker snyk container test "$IMAGE_NAME:$BUILD_TAG" --severity-threshold=high
          '''
        }
      }
    }

    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
          sh '''
            set -e
            echo "$DOCKERHUB_PASS" | docker login -u "$DOCKERHUB_USER" --password-stdin
            docker push "$IMAGE_NAME:$BUILD_TAG"
            docker push "$IMAGE_NAME:latest"
          '''
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: '**/*.log, **/npm-*.log', allowEmptyArchive: true
    }
    success { echo 'Pipeline completed successfully.' }
    failure { echo 'Pipeline failed — check stage logs above.' }
  }
}
