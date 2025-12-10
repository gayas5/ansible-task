pipeline {
    agent any

    environment {
        TF_VAR_key_name = 'my-key'
    }

    stages {

        stage('Terraform Init & Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh '''
                    terraform init -input=false
                    terraform validate
                    terraform plan -out=tfplan -input=false
                    terraform apply -auto-approve -input=false
                    '''
                }
            }
        }

        stage('Wait for instances') {
            steps {
                sh 'sleep 30'
            }
        }

        stage('Run Ansible - Frontend') {
            steps {
                ansiblePlaybook(
                    credentialsId: 'my-key',
                    disableHostKeyChecking: true,
                    installation: 'ansible',
                    inventory: 'inventory.yaml',
                    playbook: 'amazon-playbook.yml',
                    extraVars: [
                        ansible_user: 'ec2-user'
                    ]
                )
            }
        }

        stage('Run Ansible - Backend') {
            steps {
                ansiblePlaybook(
                    credentialsId: 'my-key',
                    disableHostKeyChecking: true,
                    installation: 'ansible',
                    inventory: 'inventory.yaml',
                    playbook: 'ubuntu-playbook.yml',
                    extraVars: [
                        ansible_user: 'ubuntu'
                    ]
                )
            }
        }

        stage('Post-checks') {
            steps {
                script {
                    def backend_ip = sh(script: "terraform output -raw backend_public_ip", returnStdout: true).trim()
                    def frontend_ip = sh(script: "terraform output -raw frontend_public_ip", returnStdout: true).trim()

                    echo "Frontend IP: ${frontend_ip}"
                    echo "Backend IP: ${backend_ip}"

                    sh "curl -m 10 -I http://${frontend_ip} || true"
                    sh "curl -m 10 -I http://${backend_ip}:19999 || true"
                }
            }
        }
    }
}
