
Follow this documentation - https://www.jenkins.io/doc/tutorials/tutorial-for-installing-jenkins-on-AWS/#installing-and-configuring-jenkins


1. Add the Jenkins repo using the following command:

sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo

2. Import a key file from Jenkins-CI to enable installation from the package:

sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

3. Install Java (Amazon Linux 2023):

sudo dnf install java-17-amazon-corretto -y

4. Install Jenkins:

sudo yum install jenkins -y

5. Enable the Jenkins service to start at boot:

sudo systemctl enable jenkins

6. Start Jenkins as a service:

sudo systemctl start jenkins


http://34.207.55.164:8080/