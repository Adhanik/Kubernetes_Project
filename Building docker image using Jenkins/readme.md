
# Creating a commit based JOB

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

    e. Now whenever you will push anything to this repo, the webhook should trigger a build automatically.


3. Once Github will get the new commit, Jenkins will automatically start to build the new commit. This is achieved with the help of webhook, which we have setup for our Git repo, where we have passed the jenkins url , and secret key, which helpls Jenkins automatically trigger the pipeline. 

You can find your build in jenkins server in - /var/lib/jenkins/workspace/pipeline-demo


# Connecting Jenkins to Ansible using ssh Agent

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

# How Ansible will build and tag the image

We will create one more stage, in which we will specify the build and tag command.

# Errors

    Got this error - + ssh -o StrictHostKeyChecking=no ec2-user@54.197.198.208 docker image build -t pipeline-demo:v1.12 .
    bash: line 1: docker: command not found

    Note - We have to install docker on our ansible server as well.

    ERROR: failed to solve: failed to read dockerfile: open Dockerfile: no such file or directory