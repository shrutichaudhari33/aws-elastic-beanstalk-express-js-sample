pipeline {
  agent any
  options { timestamps(); buildDiscarder(logRotator(numToKeepStr: '15')) }
  environment {
    // Jenkins container already has DOCKER_HOST from docker-compose,
    // but set again for clarity in shell steps:
    DOCKER_HOST = 'tcp://dind:2375'
    DOCKER_DRIVER = 'overlay2'
    // Image naming
    IMAGE_REPO = 'shrutichaudhari33/aws-elastic-beanstalk-sample'
    IMAGE_TAG  = "${env.BUILD_NUMBER}"
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
          # install deps in Node 16 container
          docker run --rm -v "$PWD":/app -w /app node:16 \
            sh -lc "npm install --save"

          # run tests if present, otherwise log and continue
          if grep -q '"test"' package.json; then
            docker run --rm -v "$PWD":/app -w /app node:16 \
              sh -lc "npm test"
          else
            echo "No tests defined in package.json"
          fi
        '''
      }
    }

    stage('Snyk - Open Source (deps)') {
      steps {
        withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
          sh '''
            docker run --rm \
              -e SNYK_TOKEN="$SNYK_TOKEN" \
              -v "$PWD":/app -w /app snyk/snyk:docker \
              snyk test --severity-threshold=high
          '''
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          # build app image (Dockerfile should be in repo root)
          docker build -t "$IMAGE_REPO:$IMAGE_TAG" -t "$IMAGE_REPO:latest" .
        '''
      }
    }

    stage('Snyk - Container (image)') {
      steps {
        withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
          sh '''
            # scan the built image (talks to local daemon via DOCKER_HOST)
            docker run --rm \
              -e SNYK_TOKEN="$SNYK_TOKEN" \
              -v /var/run/docker.sock:/var/run/docker.sock \
              snyk/snyk:docker \
              snyk container test "$IMAGE_REPO:$IMAGE_TAG" --severity-threshold=high
          '''
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
            docker push "$IMAGE_REPO:$IMAGE_TAG"
            docker push "$IMAGE_REPO:latest"
            docker logout
          '''
        }
      }
    }
  }

  post {
    success {
      echo "Pipeline succeeded. Pushed ${IMAGE_REPO}:${IMAGE_TAG} and :latest"
      archiveArtifacts artifacts: '**/npm-debug.log', allowEmptyArchive: true
    }
    failure {
      echo "Pipeline failed — check stage logs above."
      archiveArtifacts artifacts: '**/npm-debug.log', allowEmptyArchive: true
    }
  }
}
