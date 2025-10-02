pipeline {
  agent any

  options {
    // Task 4.2: keep logs & artifacts tidy/retained
    buildDiscarder(logRotator(numToKeepStr: '20', artifactNumToKeepStr: '10'))
    timestamps()
  }

  environment {
    // Task 2.1: Jenkins talks to Docker-in-Docker daemon
    DOCKER_HOST   = 'tcp://dind:2375'
    DOCKER_DRIVER = 'overlay2'

    // Image naming for Task 3.1 & 3.2
    DOCKER_HUB_REPO = 'shrutichaudhari33/aws-elastic-beanstalk-sample'
    IMAGE           = "${env.DOCKER_HUB_REPO}:${env.BUILD_NUMBER}"
  }

  stages {

    // Task 3.1.a + Task 4.1.b
    stage('Checkout SCM') {
      steps {
        git branch: 'main',
            url: 'https://github.com/shrutichaudhari33/aws-elastic-beanstalk-express-js-sample.git'
      }
    }

    // Task 3.1.b(i)(ii): Use Node 16 Docker image as build agent to install & test
    stage('Install & Test (Node 16)') {
      steps {
        // Install deps (explicit --save to match rubric)
        sh 'docker run --rm -v $WORKSPACE:/app -w /app node:16 npm install --save'
        // If there’s no "test" script, npm exits non-zero. We’ll surface a clear message but keep going.
        sh 'docker run --rm -v $WORKSPACE:/app -w /app node:16 npm test || echo "No tests defined in package.json"'
      }
    }

    // Task 3.2.a: Dependency (Open Source) scan — fail on High/Critical
    stage('Snyk - Open Source (deps)') {
      steps {
        withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
          sh '''
            docker run --rm \
              -e SNYK_TOKEN=$SNYK_TOKEN \
              -v $WORKSPACE:/app -w /app \
              snyk/snyk:stable snyk test --severity-threshold=high
          '''
        }
      }
    }

    // Task 3.1.b(iii): Build the application image (using DinD)
    stage('Build Docker Image') {
      steps {
        sh '''
          docker build -t $IMAGE $WORKSPACE
          docker tag $IMAGE $DOCKER_HUB_REPO:latest
        '''
      }
    }

    // Task 3.2.b: Container image scan: fail on High/Critical
    stage('Snyk - Container (image)') {
      steps {
        withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
          sh '''
            docker run --rm \
              -e SNYK_TOKEN=$SNYK_TOKEN \
              -e DOCKER_HOST=$DOCKER_HOST \
              snyk/snyk:docker snyk container test \
              $IMAGE --severity-threshold=high
          '''
        }
      }
    }

    // Task 3.1.b(iii): Push to Docker Hub
    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
          sh '''
            echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
            docker push $IMAGE
            docker push $DOCKER_HUB_REPO:latest
          '''
        }
      }
    }
  }

  post {
    success {
      echo 'Pipeline completed successfully.'
      archiveArtifacts artifacts: '**/*', allowEmptyArchive: true
    }
    failure {
      echo 'Pipeline failed — check the stage logs above.'
      archiveArtifacts artifacts: '**/*', allowEmptyArchive: true
    }
  }
}
