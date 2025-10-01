pipeline {
    agent any

    environment {
        APP_IMAGE = "myapp"
        DOCKER_HOST = "tcp://dind:2375"  // use DinD container name
        DOCKER_TLS_VERIFY = "0"          // disable TLS
        DOCKER_CERT_PATH = ""             // ensure no TLS certs are used
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
                    docker.withServer("${DOCKER_HOST}") {
                        docker.image('node:16').inside {
                            sh 'npm install'
                            sh 'npm test || true'  // optional: continue even if tests fail
                        }
                    }
                }
            }
        }

        stage('Security Scan (Snyk)') {
            steps {
                script {
                    docker.withServer("${DOCKER_HOST}") {
                        docker.image('node:16').inside {
                            sh 'apt-get update -y && apt-get install -y jq || true'
                            sh 'npm install -g snyk || true'

                            withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
                                sh '''
                                    echo "$SNYK_TOKEN" | snyk auth || true
                                    snyk test --json > snyk.json || true

                                    if [ ! -s snyk.json ]; then
                                        echo "Snyk JSON output empty – failing build"
                                        exit 1
                                    fi

                                    if cat snyk.json | jq -r '.vulnerabilities[]?.severity' | grep -E 'high|critical'; then
                                        echo "High/Critical vulnerability detected – failing build"
                                        cat snyk.json
                                        exit 1
                                    else
                                        echo "No high/critical vulnerabilities found."
                                    fi
                                '''
                            }
                        }
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.withServer("${DOCKER_HOST}") {
                        sh "docker build -t ${APP_IMAGE}:${BUILD_NUMBER} ."
                    }
                }
            }
        }

        stage('Push Docker Image to Registry') {
            steps {
                script {
                    docker.withServer("${DOCKER_HOST}") {
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
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'snyk.json, **/test-results/*.xml', allowEmptyArchive: true
        }
    }
}
