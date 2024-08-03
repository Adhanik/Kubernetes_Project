
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
new image and tags are deleted after uploading to dockerhub

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

also check kubectl cluster-info


# Errors faced while running jenkins pipeline which triggers ansible playbook

    stage('Kubernetes Deployment using ansible'){
        sshagent(['ansible_demo']){
            def remotePath = '/home/ec2-user/Ansible/'
            sh "ssh -o StrictHostKeyChecking=no ec2-user@18.206.56.201 'cd ${remotePath} && ansible-playbook playbook.yml '"
        }
    }

When jenkins is triggering the ansible playbook, its failing with this error 

    TASK [Delete old deployment] ***************************************************
    fatal: [172.31.25.174]: FAILED! => {"changed": true, "cmd": ["kubectl", "delete", "-f", "/home/ec2-user/Kubernetes/Deployment.yml"], "delta": "0:00:00.076682", "end": "2024-07-30 13:21:33.842866", "msg": "non-zero return code", "rc": 1, "start": "2024-07-30 13:21:33.766184", "stderr": "E0730 13:21:33.840031   18580 memcache.go:265] couldn't get current server API group list: Get \"http://localhost:8080/api?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused\nerror: unable to recognize \"/home/ec2-user/Kubernetes/Deployment.yml\": Get \"http://localhost:8080/api?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused", "stderr_lines": ["E0730 13:21:33.840031   18580 memcache.go:265] couldn't get current server API group list: Get \"http://localhost:8080/api?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused", "error: unable to recognize \"/home/ec2-user/Kubernetes/Deployment.yml\": Get \"http://localhost:8080/api?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused"], "stdout": "", "stdout_lines": []}

The error message indicates that kubectl is unable to connect to the Kubernetes API server, likely because it's trying to connect to localhost:8080, which is not the correct API server endpoint for your Kubernetes cluster. This issue often arises if kubectl is not configured properly on the Ansible server or if the Kubernetes cluster's API server is not accessible from there.

Check kubectl Configuration:

    Ensure that kubectl is configured correctly on the Ansible server. The kubectl configuration is typically stored in ~/.kube/config.
    Verify that the configuration file has the correct context set and points to the correct Kubernetes API server.

So we did not have kubectl installed on our ansible server. We will install kubectl on our ansible server.

# Why do we need kubectl on ansible server?

If you want to manage a Kubernetes cluster using Ansible from a separate server (Ansible server), you need to have `kubectl` installed on the Ansible server along with a valid `kubeconfig` file. The `kubeconfig` file contains the necessary configurations and credentials to connect to the Kubernetes API server.

Here’s why and how to set it up:

### Why You Need `kubectl` and `kubeconfig` on the Ansible Server

1. **Communication with the Kubernetes Cluster**: `kubectl` is the command-line tool used to interact with the Kubernetes API server. Without `kubectl`, the Ansible server cannot issue commands to the Kubernetes cluster.
2. **Authentication and Authorization**: The `kubeconfig` file provides the necessary credentials and configuration details to authenticate and authorize commands against the Kubernetes API server.

### Setting Up `kubectl` and `kubeconfig` on the Ansible Server

1. **Install `kubectl`**: See section below - Installing kubectl on Ansible 

2. **Copy the `kubeconfig` File**:
   - Copy the `kubeconfig` file from the Kubernetes node (where Minikube is running) to the Ansible server. This file is typically located at `~/.kube/config` on the Kubernetes node.
   - On the Kubernetes node, you can find the file using:
     ```bash
     cat ~/.kube/config
     ```
   - Transfer this file to the Ansible server, ensuring it is placed in the `~/.kube/` directory. You can use `scp` or other secure methods to transfer the file.

   if dir doesnt exist, make dir using -  mkdir -p ~/.kube


3. **Ensure Correct Permissions**:
   - Ensure that the `kubeconfig` file on the Ansible server has the correct permissions and is accessible only by the user running the Ansible playbook:
     ```bash
     chmod 600 ~/.kube/config
     ```

4. **Test the Configuration**:
   - Once `kubectl` and the `kubeconfig` file are set up, test the setup by running `kubectl get nodes` from the Ansible server. This should list the nodes in your Kubernetes cluster, confirming that the server can communicate with the cluster.

By having `kubectl` and the appropriate configuration on your Ansible server, your Ansible playbooks can manage Kubernetes resources effectively, just as if they were running directly on the Kubernetes node.


## SOME PRECHECKS

I did  ansible -m ping 172.31.25.174 (private ip of KB) on ansible node, its success. also i did below commands on kube node

[ec2-user@ip-172-31-25-174 ~]$ kubectl cluster-info
Kubernetes control plane is running at https://192.168.49.2:8443
CoreDNS is running at https://192.168.49.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
[ec2-user@ip-172-31-25-174 ~]$ kubectl get all
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   15d
[ec2-user@ip-172-31-25-174 ~]$

The issue might be due to kubectl not being properly configured on the Ansible server or the API server being inaccessible from the Ansible server.

# Installing kubectl on Ansible 

curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.30.0/2024-05-12/bin/linux/amd64/kubectl
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.30.0/2024-05-12/bin/linux/amd64/kubectl.sha256
sha256sum -c kubectl.sha256    -- it should give ok
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH
echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc

# Remedy on how to resolve

Ensure that the kubectl configuration file (~/.kube/config or specified by the KUBECONFIG environment variable) on the Ansible server is pointing to the correct API server endpoint (https://192.168.49.2:8443 as shown in your output).
The kubectl configuration file on the Ansible server should be the same or equivalent to the one on the Kubernetes node.

[ec2-user@ip-172-31-25-174 ~]$ kubectl cluster-info
Kubernetes control plane is running at https://192.168.49.2:8443
CoreDNS is running at https://192.168.49.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy


We see that the Kube API server endpoit is https://192.168.49.2:8443, lets look at ansible kube config file is pointing to same or not.

We have copied the config file from kube node to ansible node, and we can see inside the config file that it is pointing to correct API server endpoint.

server: https://192.168.49.2:8443

If we now do kubectl get nodes, we get below error

Error in configuration:
* unable to read client-cert /home/ec2-user/.minikube/profiles/minikube/client.crt for minikube due to open /home/ec2-user/.minikube/profiles/minikube/client.crt: no such file or directory
* unable to read client-key /home/ec2-user/.minikube/profiles/minikube/client.key for minikube due to open /home/ec2-user/.minikube/profiles/minikube/client.key: no such file or directory
* unable to read certificate-authority /home/ec2-user/.minikube/ca.crt for minikube due to open /home/ec2-user/.minikube/ca.crt: no such file or directory

The error indicates that the kubeconfig file is referencing certificate files (client.crt, client.key, ca.crt) that are not present on the Ansible server. These certificate files are required for authenticating and securing the communication with the Kubernetes cluster. We will copy these from kkube node inside ansible cluster in specified path only as shown in error

# Copying cert keys from kube node to ansbile node

To ensure your Ansible server can connect to the Kubernetes cluster, you'll need to copy specific certificate and key files referenced by the kubeconfig file. The necessary files usually include:

    Client Certificate (client.crt or similar): Used to identify the user.
    Client Key (client.key or similar): The private key for the client certificate.
    CA Certificate (ca.crt or similar): Used to verify the identity of the API server.

    Given your kubeconfig file, you should locate the exact files it references. The files you're likely looking for in the .minikube directory on your Kubernetes server are:

    ca.crt: Certificate authority file, typically used to verify the server's identity.
    client.crt: Client certificate file.
    client.key: Private key for the client certificate.

    mkdir -p /home/ec2-user/.minikube/profiles/minikube
    copy certs on these path
    change file permissions
        [ec2-user@ip-172-31-94-208 minikube]$ chmod 600 client.key
        [ec2-user@ip-172-31-94-208 minikube]$ ls -ltr
        total 8
        -rw-------. 1 ec2-user ec2-user 1147 Aug  1 11:45 client.crt
        -rw-------. 1 ec2-user ec2-user 1679 Aug  1 11:46 client.key
 

# Ansible not able to build kb maifest files

TASK [Create new Deployment] *******************************************************************************************************************************************************************************
fatal: [172.31.25.174]: FAILED! => {"changed": true, "cmd": ["kubectl", "apply", "-f", "/home/ec2-user/Kubernetes/Deployment.yml"], "delta": "0:00:00.070843", "end": "2024-08-02 13:40:52.919665", "msg": "non-zero return code", "rc": 1, "start": "2024-08-02 13:40:52.848822", "stderr": "error: error validating \"/home/ec2-user/Kubernetes/Deployment.yml\": error validating data: failed to download openapi: Get \"http://localhost:8080/openapi/v2?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused; if you choose to ignore these errors, turn validation off with --validate=false", "stderr_lines": ["error: error validating \"/home/ec2-user/Kubernetes/Deployment.yml\": error validating data: failed to download openapi: Get \"http://localhost:8080/openapi/v2?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused; if you choose to ignore these errors, turn validation off with --validate=false"], "stdout": "", "stdout_lines": []}

PLAY RECAP *************************************************************************************************************************************************************************************************
172.31.25.174              : ok=1    changed=0    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0


we have tried to update kube config file in ansible server to point to kb node , still this is not solving. we installed kubectl on ansible, copied same certs from KB node to  ansible node, and tried to do kubectl get all, but it does not seems to be working. 

Jenkins error

TASK [Create new Deployment] ***************************************************
fatal: [172.31.25.174]: FAILED! => {"changed": true, "cmd": ["kubectl", "apply", "-f", "/home/ec2-user/Kubernetes/Deployment.yml"], "delta": "0:00:00.062642", "end": "2024-08-02 13:59:00.857563", "msg": "non-zero return code", "rc": 1, "start": "2024-08-02 13:59:00.794921", "stderr": "error: error validating \"/home/ec2-user/Kubernetes/Deployment.yml\": error validating data: failed to download openapi: Get \"http://localhost:8080/openapi/v2?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused; if you choose to ignore these errors, turn validation off with --validate=false", "stderr_lines": ["error: error validating \"/home/ec2-user/Kubernetes/Deployment.yml\": error validating data: failed to download openapi: Get \"http://localhost:8080/openapi/v2?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused; if you choose to ignore these errors, turn validation off with --validate=false"], "stdout": "", "stdout_lines": []}
