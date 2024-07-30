
## Creating a commit based JOB

1. Developer will write a docker file, commit it and push it to Github. 
2. We have created a jenkins pipeline with below script and selected build trigger as - GitHub hook trigger for GITScm polling

    node {
        stage('Git checkout'){
            git 'https://github.com/Adhanik/Kubernetes_Project.git'
        }
    }

When Jenkins receives a GitHub push hook, GitHub Plugin checks to see whether the hook came from a GitHub repository which matches the Git repository defined in SCM/Git section of this job. If they match and this option is enabled, GitHub Plugin triggers a one-time polling on GITScm. When GITScm polls GitHub, it finds that there is a change and initiates a build. The last sentence describes the behavior of Git plugin, thus the polling and initiating the build is not a part of GitHub plugin.

    a. Go to your Github Repo, click on Settings, select webhook option from left hand side.
    b. Click on Add webhook, give the Jenkins URL in Payload URL *
        Note - In URL, you need to add -github-webhook/ For e.g -> http://18.208.138.223:8080/github-webhook/

    c. Content type * choose --> application/json
    d. Go to jenkins. Click on Dashboard - your user (Admin) - API Token - Generate.
        Copy this token, and provide it in Secret. click ADD WEBHOOK

    e. Now whenever you will push anything to this repo, the webhook should trigger a build automatically. Make sure to disable ssl verification.


3. Once Github will get the new commit, Jenkins will automatically start to build the new commit. This is achieved with the help of webhook, which we have setup for our Git repo, where we have passed the jenkins url , and secret key, which helpls Jenkins automatically trigger the pipeline. 

You can find your build in jenkins server in - /var/lib/jenkins/workspace/pipeline-demo


## Connecting Jenkins to Ansible using ssh Agent

4. Next, for ansible to build our docker image, we need to push it to ansible server. We will make use of Jenkins, and set up ssh passwordless authentication  btw Jenkins and ansbile server.

   For this, we need two things to set in Jenkins

     a. Command that ssh to the Ansible IP
     b. Copy the private key and add it in jenkins so jenkins is able to ssh to ansible server

5. Go to plugins, install sshagent. Configure your pipeline, add new stage.
   Ensure that the credentials with the ID ansible_demo are correctly set up. The private key should be correctly pasted in the credentials section.

   Explanation:

    sshagent: This step wraps the SSH credentials, allowing subsequent sh steps to use the provided SSH key.
    -o StrictHostKeyChecking=no: This option in the scp command disables host key checking, preventing the command from failing if the server's key is not in the known_hosts file.

Update the Pipeline Script:

   node {
    stage('Git checkout'){
        git 'https://github.com/Adhanik/Kubernetes_Project.git'
    }
    stage('Copying docker file to ansible server over ssh'){
        sshagent (['ansible_demo']){
            sh 'ssh -o StrictHostKeyChecking=no ec2-user@54.197.198.208'
            sh 'scp -r /var/lib/jenkins/workspace/pipeline-demo/* ec2-user@54.197.198.208:/home/ec2-user'
        }
        
    }
    
}

Note - Include -r option in the scp command to recursively copy the contents of a directory. 
Verbose Output: If you want to see detailed output for debugging, you can add the -v flag to the scp command:

## How Ansible will build and tag the image

We will create one more stage, in which we will specify the build and tag command.

# Errors

    Got this error - + ssh -o StrictHostKeyChecking=no ec2-user@54.197.198.208 docker image build -t pipeline-demo:v1.12 .
    bash: line 1: docker: command not found

    Note - We have to install docker on our ansible server as well.

    ERROR: failed to solve: failed to read dockerfile: open Dockerfile: no such file or directory

# Error 2 came in jenkins pipeline. the path was not set correctly.

node {
    stage('Git checkout'){
        git 'https://github.com/Adhanik/Kubernetes_Project.git'
    }

    stage('Copying docker file to ansible server over ssh'){
        sshagent (['ansible_demo']){
            // Escape spaces in paths
            def srcPath = '/var/lib/jenkins/workspace/pipeline-demo/Building\\ docker\\ image\\ using\\ Jenkins/*'
            def destPath = '/home/ec2-user/Building\\ docker\\ image\\ using\\ Jenkins'
            
            sh "scp -o StrictHostKeyChecking=no -r ${srcPath} ec2-user@54.197.198.208:${destPath}"
        }
    }

    stage('Building the docker file'){
        sshagent(['ansible_demo']){
            def remotePath = '/home/ec2-user/Building\\ docker\\ image\\ using\\ Jenkins'
            sh "ssh -o StrictHostKeyChecking=no ec2-user@54.197.198.208 'cd ${remotePath} && docker image build -t $JOB_NAME:v1.$BUILD_ID .'"
        }
    }
}


# Error 3 - ERROR: failed to solve: process "/bin/sh -c apt-get update &&     apt-get install python3 &&    
In our docker file we have to add  -y flag to the apt-get install command to automatically answer "yes" to the prompt. apt-get install -y python3 

Then our image is built successfully.

[ec2-user@ip-172-31-94-208 ~]$ docker image ls
REPOSITORY      TAG       IMAGE ID       CREATED         SIZE
pipeline-demo   v1.25     b645e7b055fe   8 minutes ago   112MB
[ec2-user@ip-172-31-94-208 ~]$

# Tag the image 

Prerequisite - You need to have a dockehub account. If you dont have one, create one.
command - docker image tag <image name>
    stage('Docker image tagging' ){
        sshagent(['ansible_demo']){
            def remotePath = '/home/ec2-user/Building\\ docker\\ image\\ using\\ Jenkins'
            sh "ssh -o StrictHostKeyChecking=no ec2-user@54.197.198.208 'cd ${remotePath}'"
            sh "ssh -o StrictHostKeyChecking=no ec2-user@54.197.198.208 'docker image tag $JOB_NAME:v1.$BUILD_ID adminnik/$JOB_NAME:v1.$BUILD_ID'"
            sh "ssh -o StrictHostKeyChecking=no ec2-user@54.197.198.208 'docker image tag $JOB_NAME:v1.$BUILD_ID adminnik/$JOB_NAME:latest'"
            
    }
    }


## Pushing Dockerimages to Dockerhub

Pre -  You should have your docker hub password

To login to docker hub from cli, we make use of docker login command. While passing through Jenkins, we will make use of withCredentials, where we will use secret text, and put our paassword in there
withCredentials makes it easy to pass password
sh "docker login -u adminnik -p ${dockerhub_password}"

Note - We dont need to go to the path here where we have our docker image. 

# Error - Here we kept facing the Groovy string interpolation issue and the syntax error, and after many tries what we did was pass the password directly in a way that avoids using Groovy string interpolation. Here's an updated version of your Push docker images to Docker Hub stage:

    stage('Push docker images to docker hub') {
        sshagent(['ansible_demo']) {
            withCredentials([string(credentialsId: 'dockerhub_password', variable: 'dockerhub_password')]) {
                sh "ssh -o StrictHostKeyChecking=no ec2-user@54.197.198.208 'docker login -u adminnik --password-stdin' <<< \"${dockerhub_password}\""
                sh "ssh -o StrictHostKeyChecking=no ec2-user@54.197.198.208 'docker image push adminnik/$JOB_NAME:v1.$BUILD_ID'"
                sh "ssh -o StrictHostKeyChecking=no ec2-user@54.197.198.208 'docker image push adminnik/$JOB_NAME:latest'"
            }
        }
    }

# How KB will pull latest image from docker, and create a container.

We will be creating a Deployment.yaml and Service.yaml file, which will be ensuring 2 containers are always running, and fetches the latest image from dockerhub.

When this deployment and service.yaml are ready, we will create a ansible playbook, which will run on the KB host, and this playbook will trigger the deployment and service.yaml files.

1. We have make ssh connectiong btw ansible and KB server now. You can mention IP of KB server in /etc/ansilbe/host file

  
  a. Log into your ansible node - ssh -i mykeypair.pem ec2-user@54.197.198.208
  b. Here we generate SSH Key Pair on Ansible Node using ssh-keygen . This would creates two files: ~/.ssh/id_rsa (private key) and ~/.ssh/id_rsa.pub (public key).
  c. copy the contents of id_rsa.pub, and Log into you KB node - ssh -i <key-pair> ec2-user@<publicIP>
  d. The public key should be appended to the ~/.ssh/authorized_keys file of the user you want to log in as on the KB node. We can do this using - echo "your-public-key-content" >> /home/ec2-user/.ssh/authorized_keys
  e. chmod 600 /home/ec2-user/.ssh/authorized_keys
  f. Then from ansible server if you do, ssh ec2-user@52.23.199.92(kube publicip), it will be reachable. once you have added the public key of ansible in authorised_keys of Kubernetes node, you can access the kubernetes node from Ansible server.

Secondly, you can create a group under /etc/ansible/hosts in ansible server and add Kubernetes host Private IP  in /etc/ansible/host under that group, and run ansible -m ping node. (assuming node is group name). It should be success.

Note - Whenever you stop start a instance, the public ip changes always. The private IP remains the same.

OR u can run ansible -m ping <private-IP-of-KB-node>

O/P

    [ec2-user@ip-172-31-94-208 ~]$ sudo vi /etc/ansible/hosts
    [ec2-user@ip-172-31-94-208 ~]$ ansible -m ping node

    172.31.25.174 | SUCCESS => {
        "ansible_facts": {
            "discovered_interpreter_python": "/usr/bin/python3.9"
        },
        "changed": false,
        "ping": "pong"
    }
    [ec2-user@ip-172-31-94-208 ~]$


2. We will create a playbook which consist command to trigger deployment and service yaml files. To trigger this playbook, we will make use of command - 

    ansible-playbook -i <inventory_path> <playbook.yml> -vvv

3. Jenkins will be transferring ansible file along with deployment and service yaml files so that ansible can execute the kubectl command from deployment.yml and service.yml 

For this transfer to happen, we will update our pipeline script 

    stage('Copying docker file to ansible server over ssh'){
        sshagent (['ansible_demo']){
            // Escape spaces in paths
            // Define source and destination paths in a map
            def paths = [
                'Building\\ docker\\ image\\ using\\ Jenkins/' : '/home/ec2-user/Building\\ docker\\ image\\ using\\ Jenkins',
                'Ansible' : '/home/ec2-user/Ansible/',
                'Kubernetes' : '/home/ec2-user/Kubernetes/'

            ]
            // Iterate over the map and copy files
            paths.each { srcFolder, destPath ->
               def srcPath = "/var/lib/jenkins/workspace/pipeline-demo/${srcFolder}/*"
               sh "ssh -o StrictHostKeyChecking=no ec2-user@18.206.56.201 'mkdir -p ${destPath}'"
               sh "scp -o StrictHostKeyChecking=no -r ${srcPath} ec2-user@18.206.56.201:${destPath}"
            
            }
        }
    }

we will iterate over this path, so all these dir are copied over to our Ansible server.
Previously we were doing like this, where we had only one dir, which consisted of Dockerfile, which was being copied over to ansible server.

    stage('Copying docker file to ansible server over ssh'){
        sshagent (['ansible_demo']){
            // Escape spaces in paths
            def srcPath = '/var/lib/jenkins/workspace/pipeline-demo/Building\\ docker\\ image\\ using\\ Jenkins/*'
            def destPath = '/home/ec2-user/Building\\ docker\\ image\\ using\\ Jenkins'
            
            sh "scp -o StrictHostKeyChecking=no -r ${srcPath} ec2-user@54.197.198.208:${destPath}"
        }
    }

4. After this, we will write the pipeline to copy these files from Jenkins to Kubenertes server. Note - We should not copy the files from ansible server to KB server, jenkins will copy to ansible, and jenkins can copy the same to KB server as well. We have written the code above, where Jenkins iterates through all the dir and also copies kb manifest file to ansible server, but it is not needed.


Ansible server should only have the playbook, and ansible can trigger the playbook to invoke those mainfest files in KB server.

we have to make use of sshAgent, since we are making use of same private key, we can continue with sshagent (['ansible_demo'])

    stage('Copying kb manifest files to KB server over ssh from jenkins'){
        sshagent (['ansible_demo']){
            def srcPath = '/var/lib/jenkins/workspace/pipeline-demo/Kubernetes/'
            def destPath = '/home/ec2-user/Kubernetes/'
            sh "scp -o StrictHostKeyChecking=no -r ${srcPath} ec2-user@184.73.133.183:${destPath}"

        }
    }

Put public ip of kube node in ec2-user@<ip>

Once u run the pipeline, you should be able to see the files present in KB server as well, which jenkins copies over.

[ec2-user@ip-172-31-25-174 Kubernetes]$ ls -ltr
total 8
-rw-r--r--. 1 ec2-user ec2-user 222 Jul 30 11:44 Services.yml
-rw-r--r--. 1 ec2-user ec2-user 399 Jul 30 11:44 Deployment.yml
[ec2-user@ip-172-31-25-174 Kubernetes]$

If you get some error, make sure you do docker login in your ansible server once.

# Clearing the local images

Additionaly we want to make sure that the images that are being built are cleared from our local machine, as we are storing all the versions. we will include this in our push docker images to docker hub section

    stage('Push docker images to docker hub') {
        sshagent(['ansible_demo']) {
            withCredentials([string(credentialsId: 'dockerhub_password', variable: 'dockerhub_password')]) {
                sh "ssh -o StrictHostKeyChecking=no ec2-user@54.197.198.208 'docker login -u adminnik --password-stdin' <<< \"${dockerhub_password}\""
                sh "ssh -o StrictHostKeyChecking=no ec2-user@54.197.198.208 'docker image push adminnik/$JOB_NAME:v1.$BUILD_ID'"
                sh "ssh -o StrictHostKeyChecking=no ec2-user@54.197.198.208 'docker image push adminnik/$JOB_NAME:latest'"

                sh "ssh -o StrictHostKeyChecking=no ec2-user@54.197.198.208 'docker image rm adminnik/$JOB_NAME:v1.$BUILD_ID adminnik/$JOB_NAME:latest $JOB_NAME:v1.$BUILD_ID'"

                
            }
            
        }
        
    }

Go to your ansible server, do docker image ls.

Previous result 
    [ec2-user@ip-172-31-94-208 ~]$ docker image ls
    REPOSITORY               TAG       IMAGE ID       CREATED       SIZE
    adminnik/pipeline-demo   latest    b645e7b055fe   11 days ago   112MB
    adminnik/pipeline-demo   v1.28     b645e7b055fe   11 days ago   112MB
    adminnik/pipeline-demo   v1.29     b645e7b055fe   11 days ago   112MB
    adminnik/pipeline-demo   v1.31     b645e7b055fe   11 days ago   112MB
    adminnik/pipeline-demo   v1.32     b645e7b055fe   11 days ago   112MB
    adminnik/pipeline-demo   v1.33     b645e7b055fe   11 days ago   112MB
    adminnik/pipeline-demo   v1.34     b645e7b055fe   11 days ago   112MB
    adminnik/pipeline-demo   v1.35     b645e7b055fe   11 days ago   112MB
    adminnik/pipeline-demo   v1.36     b645e7b055fe   11 days ago   112MB
    adminnik/pipeline-demo   v1.37     b645e7b055fe   11 days ago   112MB

After result

# Building KB deployment using ansible

Now once the connection btw Jenkins and KB server has been configured, and files are there in KB server, we want to ssh to ansible server so that we can execute our playbook.

    stage('Kubernetes Deployment using ansible')
        sshagent(['ansible_demo']){
            def remotePath = '/home/ec2-user/Ansible/'
            sh "ssh -o StrictHostKeyChecking=no ec2-user@18.206.56.201 'cd ${remotePath} && ansible-playbook playbook.yml '"
        }

1. Test your plabyook is working fine    
[ec2-user@ip-172-31-94-208 Ansible]$ ansible-playbook playbook.yml --check
It should give success

2. [ec2-user@ip-172-31-94-208 ~]$ ansible -m ping 172.31.25.174
[WARNING]: Platform linux on host 172.31.25.174 is using the discovered Python interpreter at /usr/bin/python3.9, but future installation of another Python interpreter could change the meaning of that
path. See https://docs.ansible.com/ansible-core/2.15/reference_appendices/interpreter_discovery.html for more information.
172.31.25.174 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.9"
    },
    "changed": false,
    "ping": "pong"
}
[ec2-user@ip-172-31-94-208 ~]$


3. If we stop start instance, we can see our pods are not up.

[ec2-user@ip-172-31-25-174 Kubernetes]$ kubectl get all
E0730 12:58:05.194589    9815 memcache.go:265] couldn't get current server API group list: Get "https://192.168.49.2:8443/api?timeout=32s": dial tcp 192.168.49.2:8443: i/o timeout

So we have to do minikube start

[ec2-user@ip-172-31-25-174 Kubernetes]$ minikube start
😄  minikube v1.33.1 on Amazon 2023.5.20240701 (xen/amd64)

Then if we run the same command again, 

    [ec2-user@ip-172-31-25-174 Kubernetes]$ kubectl get all
    NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
    service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   15d
    [ec2-user@ip-172-31-25-174 Kubernetes]$

