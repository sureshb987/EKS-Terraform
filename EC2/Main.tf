terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.90.1"
    }
  }
}

provider "aws" {
  region = ap-south-1
}

# STEP1: CREATE SG
resource "aws_security_group" "my-sg" {
  name        = "JENKINS-SERVER-SG"
  description = "Jenkins Server Ports"
  
  # Port 22 is required for SSH Access
  ingress {
    description     = "SSH Port"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Port 80 is required for HTTP
  ingress {
    description     = "HTTP Port"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Port 443 is required for HTTPS
  ingress {
    description     = "HTTPS Port"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Port 2379-2380 is required for etcd-cluster
  ingress {
    description     = "etc-cluster Port"
    from_port       = 2379
    to_port         = 2380
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  

  # Port 3000 is required for Grafana
  ingress {
    description     = "NPM Port"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  

  # Port 6443 is required for KubeAPIServer
  ingress {
    description     = "Kube API Server"
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  

  # Port 8080 is required for Jenkins
  ingress {
    description     = "Jenkins Port"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  

  # Port 9000 is required for SonarQube
  ingress {
    description     = "SonarQube Port"
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  
  # Port 9000 is required for SonarQube
  ingress {
    description     = "Nexus Port"
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  

  # Port 9090 is required for Prometheus
  ingress {
    description     = "Prometheus Port"
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  

  # Port 9100 is required for Prometheus metrics server
  ingress {
    description     = "Prometheus Metrics Port"
    from_port       = 9100
    to_port         = 9100
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 

  # Port 10250-10260 is required for K8s
  ingress {
    description     = "K8s Ports"
    from_port       = 10250
    to_port         = 10260
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  

  # Port 30000-32767 is required for NodePort
  ingress {
    description     = "K8s NodePort"
    from_port       = 30000
    to_port         = 32767
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  

  # Define outbound rules to allow all
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# STEP2: CREATE EC2 USING PEM & SG
resource "aws_instance" "my-ec2" {
  ami           = "ami-00bb6a80f01f03502"  
  instance_type = "t2.medium"
  key_name      = Devops project        
  vpc_security_group_ids = [aws_security_group.my-sg.id]
  
  root_block_device {
    volume_size = 28
  }
  
  tags = {
    Name = Jenkins_Server
  }
  
    # USING REMOTE-EXEC PROVISIONER TO INSTALL PACKAGES
  provisioner "remote-exec" {
    # ESTABLISHING SSH CONNECTION WITH EC2
    connection {
      type        = "ssh"
      private_key = file("./Devops project.pem") # replace with your key-name 
      user        = "ubuntu"
      host        = self.public_ip
    }

    inline = [
      # Install AWS CLI
# Ref: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
sudo apt install unzip -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Docker
# Ref: https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository

sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker ubuntu
sudo chmod 777 /var/run/docker.sock
sudo newgrp docker
docker --version


#install Jenkins
yum install java-17-amazon-corretto -y
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins
sudo systemctl start jenkins                         # to start jenkins service
# sudo systemctl status jenkins                        # to check the status if jenkins is running or not

#install Sonarqube
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community

#Install Nexus 
docker run -d --name nexux3 -p 8081:8081 sonatype/nexus3
 
 # Install ArgoCD
 # Ref: https://argo-cd.readthedocs.io/en/stable/cli_installation/
      "VERSION=$(curl -L -s https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)",
      "curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/v$VERSION/argocd-linux-amd64",
      "sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd",
      "rm argocd-linux-amd64", 

# Install Trivy
# Ref: https://aquasecurity.github.io/trivy/v0.18.3/installation/
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

#Install Kubectl
 curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
   chmod +x kubectl

# Get Jenkins_Public_IP
ip=$(curl ifconfig.me)
port1=8080
port2=9000
port3=8081

# Generate Jenkins initial login password
pass=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

echo "Access Jenkins Server here --> http://$ip:$port1"
echo "Jenkins Initial Password: $pass"
echo
echo "Access SonarQube Server here --> http://$ip:$port2"
echo "SonarQube Username & Password: admin"
echo
echo "Access Nexus Artifact here --> http://$ip:$port3"
echo "Nexus Artifact Username & Password: admin"
    ]
  }
}  

# STEP3: GET EC2 USER NAME AND PUBLIC IP 
output "SERVER-SSH-ACCESS" {
  value = "ubuntu@${aws_instance.my-ec2.public_ip}"
}

# STEP4: GET EC2 PUBLIC IP 
output "PUBLIC-IP" {
  value = "${aws_instance.my-ec2.public_ip}"
}

# STEP5: GET EC2 PRIVATE IP 
output "PRIVATE-IP" {
  value = "${aws_instance.my-ec2.private_ip}"
}
