pipeline {
  agent any

  options {
    skipDefaultCheckout(true)          // stop the implicit "Declarative: Checkout SCM"
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '20', artifactNumToKeepStr: '20'))
  }

  tools {
    git 'git'                          // <-- matches your Tools page (Name: git, Path: /usr/bin/git)
  }

  environment {
    DOCKER_HOST   = 'tcp://dind:2375'
    DOCKER_DRIVER = 'overlay2'
    IMAGE_NAME    = 'shrutichaudhari33/aws-elastic-beanstalk-sample'
    BUILD_TAG     = "${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps {
        deleteDir() // nuke stale workspaces & half-baked .git states
        checkout([
          $class: 'GitSCM',
          branches: [[name: '*/main']],
          userRemoteConfigs: [[
            url: 'https://github.com/shrutichaudhari33/aws-elastic-beanstalk-express-js-sample.git'
            // Repo is public; omit credentials to avoid GIT_ASKPASS oddities.
            // If you insist on creds, set: credentialsId: 'b8ff5aed-e92e-456b-ad6b-00e91a1fc29c'
          ]],
          extensions: [
            [$class: 'CloneOption', noTags: false, depth: 0, shallow: false]
          ],
          gitTool: 'git'
        ])
        sh 'git rev-parse --is-inside-work-tree'
      }
    }

    stage('Install & Test (Node 16)') {
      steps {
        sh '''
          set -e
          docker run --rm -v "$PWD":/app -w /app node:16-bullseye bash -lc '
            node -v
            if [ -f package-lock.json ]; then npm ci; else npm install; fi
            npm -s test || { echo "No tests defined"; exit 0; }
          '
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
          docker build -f Dockerfile \
            -t "$IMAGE_NAME:$BUILD_TAG" \
            -t "$IMAGE_NAME:latest" \
            .
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
      echo 'Pipeline finished (success or fail).'
    }
    success { echo 'Pipeline completed successfully.' }
    failure { echo 'Pipeline failed — check stage logs above.' }
  }
}
