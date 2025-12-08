pipeline {
    agent any

    stages {
        

        stage('Checkout') {
            steps {
                sh 'echo cloning repo'
                git branch: 'main' , url: 'https://github.com/saivarun0509/ansible-task.git' 
            }
        }
        
        stage('Terraform Apply') {
            steps {
                script {
                    dir("${WORKSPACE}") {
                    sh 'terraform init'
                    sh 'terraform validate'
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                        sh 'terraform plan'
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }
    }
        
        
        stage('Ansible Deployment') {
            steps {
                dir('ansible-task') { // move into the ansible-task folder
                    script {
                        ansiblePlaybook(
                            becomeUser: 'ec2-user',
                            credentialsId: 'amazonlinux',
                            disableHostKeyChecking: true,
                            installation: 'ansible',
                            inventory: 'inventory.yaml',
                            playbook: 'amazon-playbook.yml'
                        )
                        ansiblePlaybook(
                            become: true,
                            credentialsId: 'ubuntuuser',
                            disableHostKeyChecking: true,
                            installation: 'ansible',
                            inventory: 'inventory.yaml',
                            playbook: 'ubuntu-playbook.yml'
                        }
                    }
                }
            }
        }
    }
