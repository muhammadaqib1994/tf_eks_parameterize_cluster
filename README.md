## Introduction 
Terraform is an infrastructure as code (IaC) tool that allows you to build, change, and version infrastructure safely and efficiently. This includes both low-level components like compute instances, storage, and networking, as well as high-level components like DNS entries and SaaS features.

We are creating AWS EKS cluster with terraform script.
Terraform help in deploy all resource at once and update as required.

## Instructions to run from terminal
1. download the terraform script file in your pc.
2. install terraform in a terminal
3. install awscli
4. run the script using terraform, commands are below
    terraform init
    terraform plan
    terraform apply

## Instruction to run on jenkins
1. download the terraform script file
2. push to file to git repository
3. run jenkins in EC2 instance 
4. create a Jenkins pipeline
5. add the git repositor url in Jenkins pipeline configuration
6. run Jenkins pipiline 

## changes need to done befor using terraform script 

 In variables.tf
 1. VPC_ID
 2. API_SUBNET
 3. WORKERS_SUBNETS
 4. bucket   
 5. bucket_key

 In eks/variables.tf
 1. map_user
 