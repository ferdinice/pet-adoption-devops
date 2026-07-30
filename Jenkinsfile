pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build and Test') {
            steps {
                sh './mvnw clean package'
            }
        }

        stage('Verify Artifact') {
            steps {
                sh 'ls -lh target/*.war'
            }
        }
    }
}