# Deployment 3: Deploying a Web Application (gunicorn, nginx, Flask stack) to a Custom VPC via Jenkins Agent

#### Assignment instructions can be found here: [Deployment3_Instructions.pdf](https://github.com/cadenhong/kl_wk14_deployment3_forked/blob/main/Deployment-3_Assignment%20(1).pdf)

## Tasks
- Complete the deployment based on provided instructions
- Include additions made from Deployment 2 to the pipeline
- Document steps taken and any observations made (see [Deployment3_Documentation.pdf](https://github.com/cadenhong/kl_wk14_deployment3/blob/main/Deployment3_Documentation.pdf))
- Diagram the deployment pipeline and software stacks used (see [Deployment3_Diagram.png](https://github.com/cadenhong/kl_wk14_deployment3/blob/main/Deployment3_Diagram.png))

## Deployment Prerequisites
Set up a custom VPC - see [Deployment3_Prereq_VPC_Setup.pdf](https://github.com/cadenhong/kl_wk14_deployment3/blob/main/Deployment3_Prereq_VPC_Setup.pdf) for details on how to set up VPC for this specific deployment.

## Deployment Steps
1. Spin up an EC2 instance with Ubuntu AMI and ports 22, 80, and 8080
2. SSH into the EC2 and run [setup_jenkins.sh](https://github.com/cadenhong/kl_wk14_deployment3/blob/main/setup_jenkins.sh) to install Jenkins
3. Create an EC2 on a public subnet of Kura VPC (custom VPC) with Ubuntu AMI and ports 22 and 5000
4. SSH into the Kura VPC's EC2 and run [setup_VPC_pub_ec2.sh](https://github.com/cadenhong/kl_wk14_deployment3/blob/main/setup_VPC_pub_ec2.sh) 
5. Back on the Jenkins EC2, configure and connect a Jenkins agent with Host as the Kura VPC's EC2
<img width="470" alt="image" src="https://user-images.githubusercontent.com/83370640/194993622-1ddf45b2-68ad-4c56-bd7f-5cd46e19954f.png">

6. Connect [this GitHub repository](https://github.com/cadenhong/kl_wk14_deployment3_forked) to Jenkins server via Multibranch build
7. Install "Pipeline Keep Running Step" plugin on Jenkins server 
<img width="470" alt="image" src="https://user-images.githubusercontent.com/83370640/195619075-e8e25f64-45bd-48a2-89dc-f6e4bded5760.png">

8. SSH back into the Kura VPC's EC2 and change configurations inside `/etc/nginx/sites-enabled/default` file to the following:
```
server {
  listen 5000;
  listen [::]:5000 default_server;
...

location / {
  proxy_pass http://127.0.0.1:8000;
  proxy_set_header Host $host;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
```
9. Edit Jenkinsfile in the GitHub repo to include a Clean and Deploy stage:
```
stage ('Clean') {
      agent{label 'awsDeploy'}
      steps {
        sh '''#!/bin/bash
        if [[ $(ps aux | grep -i "gunicorn" | tr -s " " | head -n 1 | cut -d " " -f 2) != 0 ]]
        then
          ps aux | grep -i "gunicorn" | tr -s " " | head -n 1 | cut -d " " -f 2 > pid.txt
          kill $(cat pid.txt)
          exit 0
        fi
        '''
  }
}
     
stage ('Deploy') {
      agent{label 'awsDeploy'}
      steps {
        sh '''#!/bin/bash
        git clone https://github.com/kura-labs-org/kuralabs_deployment_2.git
        cd ./kuralabs_deployment_2
        python3 -m venv test3
        source test3/bin/activate
        pip install -r requirements.txt
        pip install gunicorn
        gunicorn -w 4 application:app -b 0.0.0.0 --daemon
        '''
  }
}
```
See the difference between the [original Jenkinsfile](https://github.com/kura-labs-org/kuralabs_deployment_3/blob/main/Jenkinsfile) vs. [edited Jenkinsfile](https://github.com/cadenhong/kl_wk14_deployment3/blob/main/Jenkinsfile)

10. Build and deploy:
<img width="470" alt="image" src="https://user-images.githubusercontent.com/83370640/194993733-2eef8a9f-1ead-498c-ac9a-5a55b4432cf3.png">


## Modifications Made (from Deployment 2)
#### - Webhook to automate the deployment - changes pushed to the code are picked up by Jenkins via the webhook and redeployed in Jenkins pipeline's Build stage

#### - Installed Slack plugin on Jenkins to set up notifications based on status of build for each stage in the pipeline:

Code added inside Jenkinsfile:
```
  post {
    success {
      slackSend (message: "INFO: Build Number ${env.BUILD_NUMBER} - ${STAGE_NAME} Stage completed successfully!")
    }
    failure {
      slackSend (message: "WARNING: Build Number ${env.BUILD_NUMBER} - ${STAGE_NAME} Stage has failed!")
    }
  }
```

## nginx-gunicorn-Flask Stack
My understanding of the stack:

<img width="447" alt="Screen Shot 2022-10-13 at 6 41 58 PM" src="https://user-images.githubusercontent.com/83370640/195716408-4ebe3ac6-80be-401a-870f-9a9553c71aa6.png">



## Files and Folders
- [.gitignore](https://github.com/cadenhong/kl_wk14_deployment3/blob/main/.gitignore): Contains files to ignore when pushing to GitHub repository
- [Deployment3_Diagram.png](https://github.com/cadenhong/kl_wk14_deployment3/blob/main/Deployment3_Diagram.png): Diagram of the pipeline
- [Deployment3_Documentation.docx](https://github.com/cadenhong/kl_wk14_deployment3/blob/main/Deployment3_Documentation.docx): Word file of notes and observations made during deployment
- [Deployment3_Documentation.pdf](https://github.com/cadenhong/kl_wk14_deployment3/blob/main/Deployment3_Documentation.pdf): PDF of notes and observations made during deployment
- [Deployment3_Prereq_VPC_Setup.pdf](https://github.com/cadenhong/kl_wk14_deployment3/blob/main/Deployment3_Prereq_VPC_Setup.pdf): PDF of VPC creation required prior to doing this deployment
- [setup_VPC_pub_ec2.sh](https://github.com/cadenhong/kl_wk14_deployment3/blob/main/setup_VPC_pub_ec2.sh): Bash script to setup and install required packages on Kura VPC's EC2
- [setup_jenkins.sh](https://github.com/cadenhong/kl_wk14_deployment3/blob/main/setup_jenkins.sh): Bash script to setup and install Jenkins

## Tools
- Jenkins (CI/CD pipeline management, Jenkins agent)
- GitHub (repository, webhook, access tokens)
- Software Application Stack: Python, Flask, Gunicorn, nginx
- AWS VPC (VPC, subnets, internet gateway, route tables)
- AWS EC2
- Diagrams.net
- Slack
