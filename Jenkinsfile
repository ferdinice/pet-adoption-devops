pipeline {
    agent any

    environment {
    APPLICATION_NAME = 'pet-adoption'
    IMAGE_TAG        = "build-${BUILD_NUMBER}"

    AWS_REGION       = 'eu-west-3'
    AWS_ACCOUNT_ID   = '740994137090'
    ECR_REPOSITORY   = 'enterprise-devops-platform/pet-adoption'
    ECR_REGISTRY     = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    ECR_IMAGE        = "${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
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

stage('Push Image to ECR') {
    steps {
        echo "Authenticating to Amazon ECR and pushing ${ECR_IMAGE}"

        sh '''
            aws ecr get-login-password \
              --region ${AWS_REGION} \
            | docker login \
              --username AWS \
              --password-stdin ${ECR_REGISTRY}

            docker tag \
              ${APPLICATION_NAME}:${IMAGE_TAG} \
              ${ECR_IMAGE}

            docker push ${ECR_IMAGE}
        '''
    }
}

stage('Verify Image in ECR') {
    steps {
        echo "Confirming that ${IMAGE_TAG} exists in Amazon ECR"

        sh '''
            aws ecr describe-images \
              --repository-name ${ECR_REPOSITORY} \
              --image-ids imageTag=${IMAGE_TAG} \
              --region ${AWS_REGION}
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