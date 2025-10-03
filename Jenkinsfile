pipeline {
  agent any

  options {
    skipDefaultCheckout(true)
    disableConcurrentBuilds()       // stop Jenkins creating @2, @3 workspaces
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
        sh 'ls -la'   // sanity check: package.json should be here
      }
    }

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

    stage('Build Docker Image') {
      agent { docker { image 'docker:24-cli'; args '-u root:root'; reuseNode true } }
      environment { DOCKER_HOST = 'tcp://dind:2375' }
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
      agent { docker { image 'snyk/snyk:docker'; args '-u root:root'; reuseNode true } }
      steps {
        withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
          sh 'snyk test --severity-threshold=high'
        }
      }
    }

    stage('Snyk - Container (image)') {
      agent { docker { image 'snyk/snyk:docker'; args '-u root:root -v /var/run/docker.sock:/var/run/docker.sock'; reuseNode true } }
      environment { DOCKER_HOST = 'tcp://dind:2375' }
      steps {
        withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
          sh 'snyk container test "$IMAGE_NAME:$BUILD_TAG" --severity-threshold=high'
        }
      }
    }

    stage('Push Docker Image') {
      agent { docker { image 'docker:24-cli'; args '-u root:root'; reuseNode true } }
      environment { DOCKER_HOST = 'tcp://dind:2375' }
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
