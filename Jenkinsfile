pipeline {
    agent any

    environment {
        REGISTRY = "docker.io/bhushanyadava"     // change to your DockerHub username
        IMAGE_NAME = "myapp"
        KUBECONFIG = "/root/.kube/config"        // path inside Jenkins pod
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/bhushan-yadava/k8s-jenkins-ansible.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                        docker build -t $REGISTRY/$IMAGE_NAME:${BUILD_NUMBER} .
                        docker tag $REGISTRY/$IMAGE_NAME:${BUILD_NUMBER} $REGISTRY/$IMAGE_NAME:latest
                    """
                }
            }
        }

        stage('Push Image to Registry') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push $REGISTRY/$IMAGE_NAME:${BUILD_NUMBER}
                        docker push $REGISTRY/$IMAGE_NAME:latest
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh """
                        kubectl apply -f k8s/deployment.yaml
                        kubectl apply -f k8s/service.yaml
                    """
                }
            }
        }

        stage('Run Ansible Playbook') {
            steps {
                script {
                    sh "kubectl apply -f k8s/ansible-inventory-cm.yaml"
                    sh "kubectl apply -f k8s/ansible-playbooks-cm.yaml"
                    sh "kubectl apply -f k8s/ansible-job.yaml"
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment pipeline finished successfully!"
        }
        failure {
            echo "❌ Deployment failed. Check logs in Jenkins console."
        }
    }
}
