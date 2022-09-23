def tfCmd(String command, String options = '') {
    ACCESS = "export AWS_PROFILE=${params.PROFILE} && export TF_ENV_profile=${params.PROFILE}"
    sh ("cd $WORKSPACE/ && ${ACCESS} && terraform init")
    sh ("echo ${command} ${options}")
    sh ("ls && pwd")
    sh ("cd $WORKSPACE/ && ${ACCESS} && terraform init && terraform ${command} ${options} && terraform show -no-color > show-${ENV_NAME}.txt")
}

pipeline {
    agent any 

    environment {
        PROJECT_DIR = "eks_cluster/"
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    parameters {
        
        choice (name: 'AWS_REGION', choices: [ 'us-west-2', 'ap-northeast-1', 'us-east-2'], description: 'Pick a Region. Defaults to ap-northeast-1')
        
        choice (name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Run terraform plan / apply / destroy')

        string (name: 'PROFILE', defaultValue: 'saghiraws', description: 'Optional, Target AWS Profile')

        string (name: 'ENV_NAME', defaultValue: 'tf-AWS', description: 'Env name.')

        string (name: 'eks_cluster_name', defaultValue: 'EKS_CLUSTER', description: 'Name of EKS cluster.')

        choice (name: 'eks_cluster_version', choices: [ '1.20', '1.21', '1.19'], description: 'Kubernetes version in EKS.')

    }

    stages {

        stage('Set Environment Variable'){
            steps {
                script {
                    env.PROFILE = "${params.PROFILE}"
                    env.ACTION = "${params.ACTION}"
                    env.AWS_DEFAULT_REGION = "${params.AWS_REGION}"
                    env.ENV_NAME = "${params.ENV_NAME}"
                    env.eks_cluster_name = "${params.eks_cluster_name}"
                    env.eks_cluster_version = "${params.eks_cluster_version}"
                    
                }
            }
        }

        stage('Checkout & Environment Prep'){
            steps{
                script {
                    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']){
                        withCredentials([
                            [ $class: 'AmazonWebServicesCredentialsBinding',
                                accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
                                credentialsId: 'AWS_Access',

                            ]])
                        {
                            try {
                                currentBuild.displayName += "[$AWS_REGION]::[$ACTION]"
                                sh ("""
                                        aws configure --profile ${params.PROFILE} set aws_access_key_id ${AWS_ACCESS_KEY_ID}
                                        aws configure --profile ${params.PROFILE} set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
                                        aws configure --profile ${params.PROFILE} set region ${AWS_REGION}
                                        export AWS_PROFILE=${params.PROFILE}
                                        export TF_ENV_profile=${params.PROFILE}
                                """)
                                tfCmd('version')
                            } catch (ex) {
                                echo 'Err: Build Failed with Error: ' + ex.toString()
                                currentBuild.result = "UNSTABLE"
                            }
                        }
                        
                    }
                }
            }
        }
        stage('Terraform Plan'){
                when { anyOf
                            {
                                environment name: 'ACTION', value: 'plan';
                                environment name: 'ACTION', value: 'apply';
                            }

                }
                steps {

                        dir("${PROJECT_DIR}"){
                                script {
                                        wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
                                                withCredentials([
                                                    [ $class: 'AmazonWebServicesCredentialsBinding',
                                                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
                                                            credentialsId: 'AWS_Access'
                                                    ]])
                                                {
                                                    try {
                                                        sh ("""
                                                        touch $WORKSPACE/terraform.tfvars
                                                        echo 'eks_cluster_name = "${eks_cluster_name}"' >> $WORKSPACE/terraform.tfvars
                                                       
                                                        echo 'eks_cluster_version = "${eks_cluster_version}"' >> $WORKSPACE/terraform.tfvars
                                                        
                                                        cat $WORKSPACE/terraform.tfvars
                                                        """)
                                                        tfCmd('plan', '-detailed-exitcode -var AWS_REGION=${AWS_DEFAULT_REGION} -var-file=terraform.tfvars -out plan.out')
                                                    } catch (ex) {
                                                        if(ex == 2 && "${ACTION}" == 'apply'){
                                                            currentBuild.result = "UNSTABLE"
                                                        } else if (ex == 2 && "${ACTION}" == 'plan') {
                                                            echo "Update found in plan.out"
                                                        } else {
                                                            echo "Try Running terrafom in debug mode."
                                                        }
                                                    }
                                                }
                                        }
                                }
                        }
                }
        }

        stage('Terraform Apply'){
                when { anyOf
                            {
                                environment name: 'ACTION', value: 'apply';
                            }

                }

                steps {
                        dir("${PROJECT_DIR}") {
                                script {
                                        wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
                                                withCredentials([
                                                    [ $class: 'AmazonWebServicesCredentialsBinding',
                                                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
                                                        credentialsId: 'AWS_Access',
                                                        ]])
                                                    {
                                                    try {
                                                        tfCmd('apply', 'plan.out')
                                                    } catch (ex) {
                                                        currentBuild.result = "UNSTABLE"
                                                    }
                                                }
                                        }
                                }
                        }
                }
        }
        stage('Install Components'){
            when { anyOf
                {
                    environment name: 'ACTION', value: 'apply';
                }

            }
            steps {
                dir("${PROJECT_DIR}"){
                    script {
                        wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
                            withCredentials([
                                [ $class: 'AmazonWebServicesCredentialsBinding',
                                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
                                    credentialsId: 'AWS_Access',
                                ]]){
                                    try {
                                           
                                            sh("""
                                                aws eks --region ${AWS_REGION} update-kubeconfig --name ${eks_cluster_name}
                                                
                                                kubectl apply -f $WORKSPACE/deployment.yaml
                                                
                                            """)

                                            
                                    } catch (ex) {
                                        currentBuild.result = "UNSTABLE"
                                    }
                                }
                            }
                    }
                }
            }
        }
        stage('Terraform Destroy') {
                when { anyOf 
                            {
                                environment name: 'ACTION', value: 'destroy';
                            }
                }
                steps {
                        script {
                            def IS_APPROVED = input(
                                    message: "Destroy ${ENV_NAME} !?!",
                                    ok: 'Yes',
                                    parameters: [
                                        string(name: 'IS_APPROVED', defaultValue: 'No', description: 'Think again!!!')
                                    ]
                                )
                                if (IS_APPROVED != 'Yes') {
                                        currentBuild.result = "ABORTED"
                                        error "User cancelled"
                                }
                        }

                        dir("${PROJECT_DIR}") {
                            script {

                                    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
                                            withCredentials([
                                                [ $class: 'AmazonWebServicesCredentialsBinding',
                                                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
                                                    credentialsId: 'AWS_Access',
                                                    ]])
                                                {
                                                    try {
                                                        tfCmd('destroy', '-auto-approve')
                                                    } catch (ex) {
                                                        currentBuild.result = "UNSTABLE"
                                                    }
                                                }
                                        }
                                }
                        }
                }
        }
    }
    post { 
        always { 
            deleteDir()
        }
    }
}
