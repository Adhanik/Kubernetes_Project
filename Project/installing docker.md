
Follow the linux section from this document -
https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-docker.html#install-docker-instructions

STEPS 

    sudo yum update -y
    sudo yum install -y docker
    sudo service docker start
    sudo usermod -a -G docker ec2-user
    docker ps

If you face permission denied error, run below comand 

[ec2-user@ip-172-31-25-174 ~]$ docker ps
permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get "http://%2Fvar%2Frun%2Fdocker.sock/v1.24/containers/json": dial unix /var/run/docker.sock: connect: permission denied

[ec2-user@ip-172-31-25-174 ~]$ sudo chmod 666 /var/run/docker.sock

[ec2-user@ip-172-31-25-174 ~]$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
[ec2-user@ip-172-31-25-174 ~]$