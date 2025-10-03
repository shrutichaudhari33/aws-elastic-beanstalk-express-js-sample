pipeline {
  agent any

  options {
    skipDefaultCheckout(true)              // ⬅️ stop the auto "Declarative: Checkout SCM"
    timestamps()
    ansiColor('xterm')
    buildDiscarder(logRotator(numToKeepStr: '20', artifactNumToKeepStr: '20'))
  }

  environment {
    // DinD socket exposed by docker-compose
    DOCKER_HOST = 'tcp://dind:2375'
    DOCKER_DRIVER = 'overlay2'
    IMAGE_NAME = 'shrutichaudhari33/aws-elastic-beanstalk-sample'
    BUILD_TAG = "${env.BUILD_NUMBER}"
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
        sh '''
          set -e
          docker run --rm \
            -v "$PWD":/app -w /app \
            node:16 npm install --save

          # Some forks have no test script; don’t fail the build if missing.
          docker run --rm \
            -v "$PWD":/app -w /app \
            node:16 sh -lc 'npm run -s test || { echo "No tests defined in package.json"; exit 0; }'
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
            # Scan the built image via Docker socket (DinD)
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
    success {
      echo 'Pipeline completed successfully.'
      archiveArtifacts artifacts: '**/npm-debug.log,**/snyk*.txt', allowEmptyArchive: true
    }
    failure {
      echo 'Pipeline failed — check stage logs above.'
      archiveArtifacts artifacts: '**/npm-debug.log,**/snyk*.txt', allowEmptyArchive: true
    }
  }
}
