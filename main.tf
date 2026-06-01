provider "aws" {
    region = "ap-south-1"
}

resource "aws_vpc" "aura-library_vpc" {
    cidr_block = "10.0.0.0/16"
    tags       = { Name = "aura-library-vpc" }
}

resource "aws_subnet" "aura-library_subnet" {
    vpc_id                  = aws_vpc.aura-library_vpc.id
    cidr_block              = "10.0.0.0/21"
    map_public_ip_on_launch = true
    availability_zone       = "ap-south-1a"
    tags                    = { Name = "aura-library-subnet" }
}

resource "aws_internet_gateway" "aura-library_ig" {
    vpc_id = aws_vpc.aura-library_vpc.id
}

resource "aws_route_table" "aura-library_rt" {
    vpc_id = aws_vpc.aura-library_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.aura-library_ig.id
    }
}

resource "aws_route_table_association" "aura-library-association" {
    subnet_id      = aws_subnet.aura-library_subnet.id
    route_table_id = aws_route_table.aura-library_rt.id
}

resource "aws_security_group" "aura-library_sg" {
    vpc_id = aws_vpc.aura-library_vpc.id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
        ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
        ingress {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
        ingress {
        from_port   = 30080
        to_port     = 30080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
        egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_key_pair" "aura-library_key" {
    key_name   = "aura-library-key-v1"
    public_key = file("f:/file/devops/aura-library-1/aura-library-key-v1.pub")
}

resource "aws_instance" "aura-library_key" {
    ami                    = "ami-05d2d839d4f73aafb"
    instance_type          = "m7i-flex.large"
    vpc_security_group_ids = [aws_security_group.aura-library_sg.id]
    subnet_id              = aws_subnet.aura-library_subnet.id
    key_name               = aws_key_pair.aura-library_key.key_name

    root_block_device {
        volume_size = 16
        volume_type = "gp3"
    }

    user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install openjdk-21-jre -y
    sudo apt install docker.io -y
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ubuntu
    
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null

    sudo apt update -y

    sudo apt install jenkins -y
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    sudo usermod -aG docker jenkins
    
    curl -sfL https://get.k3s.io | sh -s - --docker
    sudo chmod 644 /etc/rancher/k3s/k3s.yaml
    EOF

    tags = { Name = "aura-library-server" }
}

resource "aws_eip" "aura-library_eip" {
    instance = aws_instance.aura-library_key.id
    domain   = "vpc"
    tags     = { Name = "aura-library-eip" }
}

output "elastic_ip" {
    value       = aws_eip.aura-library_eip.public_ip
    description = "Fixed public IP - will never change on restart"
}
