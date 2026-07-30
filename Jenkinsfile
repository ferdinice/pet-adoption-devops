pipeline {
    agent any

    environment {
        APPLICATION_NAME = 'pet-adoption'
        IMAGE_TAG        = "build-${BUILD_NUMBER}"
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Downloading the application source code from GitHub'
                checkout scm
            }
        }

        stage('Build and Test') {
            steps {
                echo 'Compiling the application, running tests, and creating the WAR file'
                sh 'chmod +x mvnw'
                sh './mvnw clean package'
            }
        }

        stage('Verify Artifact') {
            steps {
                echo 'Confirming that Maven created the application WAR file'
                sh 'ls -lh target/spring-petclinic-2.4.2.war'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image ${APPLICATION_NAME}:${IMAGE_TAG}"
                sh '''
                    docker build \
                      -t ${APPLICATION_NAME}:${IMAGE_TAG} \
                      .
                '''
            }
        }

        stage('Verify Docker Image') {
            steps {
                echo 'Confirming that the Docker image exists'
                sh 'docker image inspect ${APPLICATION_NAME}:${IMAGE_TAG}'
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded. Image created: ${APPLICATION_NAME}:${IMAGE_TAG}"
        }

        failure {
            echo 'Pipeline failed. Review the failed stage and Console Output.'
        }

        always {
            echo "Build completed with status: ${currentBuild.currentResult}"
        }
    }
}