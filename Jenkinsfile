pipeline {
    agent any

    environment {
        APPLICATION_NAME = 'pet-adoption'
        

        JAVA_HOME = '/usr/lib/jvm/java-17-openjdk-amd64'
        PATH      = "${JAVA_HOME}/bin:${env.PATH}"

        AWS_REGION     = 'eu-west-3'
        AWS_ACCOUNT_ID = '740994137090'
        ECR_REPOSITORY = 'enterprise-devops-platform/pet-adoption'
        ECR_REGISTRY   = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        

        GITOPS_REPO_URL = 'https://github.com/ferdinice/enterprise-devops-platform.git'
        GITOPS_BRANCH   = 'main'
        GITOPS_PATH     = 'gitops/pet-adoption/overlays/dev/kustomization.yaml'
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

        script {
            env.GIT_SHORT_SHA = sh(
                script: 'git rev-parse --short=7 HEAD',
                returnStdout: true
            ).trim()

            env.IMAGE_TAG = "build-${BUILD_NUMBER}-${env.GIT_SHORT_SHA}"
            env.ECR_IMAGE = "${env.ECR_REGISTRY}/${env.ECR_REPOSITORY}:${env.IMAGE_TAG}"

            echo "Git commit: ${env.GIT_SHORT_SHA}"
            echo "Image tag: ${env.IMAGE_TAG}"
        }
    }
}

        stage('Verify Build Environment') {
    steps {
        echo 'Confirming the Java build environment'
        sh '''
            java -version
            javac -version
            echo "JAVA_HOME=${JAVA_HOME}"
        '''
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
/*
        stage('Quality Gate') {
            steps {
                echo 'Waiting for the SonarQube Quality Gate result'

                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
*/
        stage('Verify Artifact') {
            steps {
                echo 'Confirming that Maven created the application WAR file'
                sh 'ls -lh target/spring-petclinic-2.4.2.war'
            }
        }

        stage('Archive Artifact') {
            steps {
                echo 'Saving the WAR file as a Jenkins build artifact'

                archiveArtifacts(
                    artifacts: 'target/spring-petclinic-2.4.2.war',
                    fingerprint: true
                )
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

        

        stage('Update GitOps Repository') {
    steps {
        echo "Updating GitOps desired state to ${IMAGE_TAG}"

        withCredentials([
            usernamePassword(
                credentialsId: 'github-gitops-credentials',
                usernameVariable: 'GIT_USERNAME',
                passwordVariable: 'GIT_TOKEN'
            )
        ]) {
            sh '''
                set -e

                rm -rf platform-gitops

                git clone \
                  --branch ${GITOPS_BRANCH} \
                  https://${GIT_USERNAME}:${GIT_TOKEN}@${GITOPS_REPO_URL#https://} \
                  platform-gitops

                cd platform-gitops

                git config user.name "jenkins"
                git config user.email "jenkins@enterprise-devops.local"

                sed -i \
                  "s/newTag: .*/newTag: ${IMAGE_TAG}/" \
                  ${GITOPS_PATH}

                echo "Updated image tag:"
                grep "newTag:" ${GITOPS_PATH}

                if git diff --quiet; then
                    echo "GitOps repository already references ${IMAGE_TAG}. No commit required."
                    exit 0
                fi

                git add ${GITOPS_PATH}

                git commit \
                  -m "Deploy pet-adoption ${IMAGE_TAG}"

                git push origin ${GITOPS_BRANCH}
            '''
        }
    }
}
        stage('Verify Docker Image') {
            steps {
                echo 'Confirming that the local Docker image exists'
                sh 'docker image inspect ${APPLICATION_NAME}:${IMAGE_TAG}'
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded. Image pushed to ECR: ${ECR_IMAGE}"
        }

        failure {
            echo 'Pipeline failed. Review the failed stage and Console Output.'
        }

        always {
            echo "Build completed with status: ${currentBuild.currentResult}"
        }
    }
}