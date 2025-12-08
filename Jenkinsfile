pipeline {
    agent any

    stages {
        

        stage('Checkout') {
            steps {
                sh 'echo cloning repo'
                sh 'https://github.com/saivarun0509/ansible-task.git' 
            }
        }
        
        stage('Terraform Apply') {
            steps {
                script {
                    dir('ansible-task/terraform') {
                    sh 'terraform init'
                    sh 'terraform validate'
                    sh 'terraform plan'
                    }
                }
            }
        }
        
        stage('Ansible Deployment') {
            steps {
                script {
                   sleep '360'
                    ansiblePlaybook becomeUser: 'ec2-user', credentialsId: 'amazonlinux', disableHostKeyChecking: true, installation: 'ansible', inventory: '/var/lib/jenkins/workspace/challenge/terraform' , playbook: '/var/lib/jenkins/workspace/challenge/terraform', vaultTmpPath: ''
                    ansiblePlaybook become: true, credentialsId: 'ubuntuuser', disableHostKeyChecking: true, installation: 'ansible', inventory: '/var/lib/jenkins/workspace/challenge/terraform', playbook: '/var/lib/jenkins/workspace/challenge/terraform', vaultTmpPath: ''
                }
            }
        }
    }
}
