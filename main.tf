pipeline {
  agent any

  environment {
    AWS_DEFAULT_REGION = "us-east-1"
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Terraform Init & Apply') {
      steps {
        withCredentials([
          string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
          string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          sh '''
            terraform init -input=false
            terraform validate
            terraform apply -auto-approve
          '''
        }
      }
    }

    stage('Wait for EC2') {
      steps {
        sleep 60
      }
    }

    stage('Run Ansible - Frontend') {
      steps {
        sh '''
          FRONTEND_IP=$(terraform output -raw frontend_ip)
          KEY=$(terraform output -raw ssh_key_path)

          ansible-playbook -i "$FRONTEND_IP," \
            --private-key "$KEY" \
            -u ec2-user \
            ansible/frontend.yml
        '''
      }
    }

    stage('Run Ansible - Backend (Netdata)') {
      steps {
        sh '''
          BACKEND_IP=$(terraform output -raw backend_ip)
          KEY=$(terraform output -raw ssh_key_path)

          ansible-playbook -i "$BACKEND_IP," \
            --private-key "$KEY" \
            -u ubuntu \
            ansible/backend.yml
        '''
      }
    }
  }

  post {
    always {
      echo "Pipeline completed"
    }
  }
}
