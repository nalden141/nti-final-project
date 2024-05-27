pipeline {
    agent any 

    environment {
        AWS_ACCESS_KEY_ID = credentials("aws_access_key_id")
        AWS_SECRET_ACCESS_KEY = credentials("aws_secret_access_key")
        REPO_SERVER = "730335189363.dkr.ecr.us-east-1.amazonaws.com/backend_repo"
        AWS_REGION = 'us-east-1'
        REPO_NAME_BACKEND = "${REPO_SERVER}/nti-project:backend"
        REPO_NAME_FRONTEND = "${REPO_SERVER}/nti-project:frontend"
    }

    stages {

        stage("build image") {
            steps {
                script {
                    echo "building docker images ..."
                    withCredentials([
                        usernamePassword(credentialsId: 'ecr-credentials', usernameVariable: 'USER', passwordVariable: 'PASS')
                    ]){
                        sh "docker login -u ${USER} -p ${PASS} ${REPO_SERVER}"
                        sh "docker build app/backend/. -t ${REPO_NAME_BACKEND}-${IMAGE_VERSION}"
                        sh "docker push ${REPO_NAME_BACKEND}-${IMAGE_VERSION}"
                        sh "docker build app/frontend/. -t ${REPO_NAME_FRONTEND}-${IMAGE_VERSION}"
                        sh "docker push ${REPO_NAME_FRONTEND}-${IMAGE_VERSION}"
                    }
                }
            }
        }

        stage("change image version") {
            steps {
                script {
                    echo "change image version .."
                    sh "sed -i \"s|image:.*|image: ${REPO_NAME_BACKEND}-${IMAGE_VERSION}|g\" k8s/back.yaml"
                    sh "sed -i \"s|image:.*|image: ${REPO_NAME_FRONTEND}-${IMAGE_VERSION}|g\" k8s/front.yaml"
                }
            }
        }

        stage('Deploy to eks cluster') {
            
            steps {
                echo 'Deploying to eks cluster ... '
                withCredentials([file(credentialsId:'kube-config', variable:'KUBECONFIG')]){
                    script{
                        sh 'kubectl apply -f k8s'
                    }
                }
            }
        }
    }
}