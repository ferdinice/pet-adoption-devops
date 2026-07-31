pipeline {
    agent any

    environment {
        APPLICATION_NAME = 'pet-adoption'
        IMAGE_TAG        = "build-${BUILD_NUMBER}"
    }

    options {
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
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

    stage('SonarQube Analysis') {
    steps {
        echo 'Analyzing source code quality and security with SonarQube'

        withSonarQubeEnv('SonarQube') {
            sh '''
                ./mvnw org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
                  -Dsonar.projectKey=pet-adoption \
                  -Dsonar.projectName="Pet Adoption"
            '''
        }
    }
}

stage('Quality Gate') {
    steps {
        echo 'Waiting for the SonarQube Quality Gate result'

        timeout(time: 5, unit: 'MINUTES') {
            waitForQualityGate abortPipeline: true
        }
    }
}

        stage('Verify Artifact') {
            steps {
                echo 'Confirming that Maven created the application WAR file'
                sh 'ls -lh target/spring-petclinic-2.4.2.war'
            }
        }
        stage('Archive Artifact') {
            steps {
                echo 'Saving the WAR file as a Jenkins build artifact'
                archiveArtifacts artifacts: 'target/spring-petclinic-2.4.2.war', fingerprint: true
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
stage('Trivy Image Scan') {
    steps {
        echo "Scanning Docker image ${APPLICATION_NAME}:${IMAGE_TAG} for vulnerabilities"

        sh '''
            trivy image \
              --severity HIGH,CRITICAL \
              --ignore-unfixed \
              --exit-code 0 \
              --no-progress \
              ${APPLICATION_NAME}:${IMAGE_TAG}
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