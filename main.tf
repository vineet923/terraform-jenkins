variable "ingressrules" {
  type    = list(number)
  default = [8080, 22]
}

resource "aws_security_group" "web_traffic" {
  name        = "Allow web traffic"
  description = "inbound ports for ssh and standard http and everything outbound"
  dynamic "ingress" {
    iterator = port
    for_each = var.ingressrules
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Terraform" = "true"
  }
}

# resource block

resource "aws_instance" "tomcat" {
  ami             = var.AMIS[var.REGION]
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.web_traffic.name]
  key_name        = "jenkins-server-key"

  provisioner "remote-exec" {
    inline = [
      #!/bin/bash
      "sudo apt update",
      "sudo apt install openjdk-8-jdk -y",
      "sudo apt install ca-certificates -y",
      "sudo apt install maven git wget unzip -y",
      "wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -",
      "sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'",
      "sudo apt-get update",
      "sudo apt-get install jenkins -y",
      ###
    ]
  }
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("${path.module}/jenkins-server-key.pem")
  }
  tags = {
    "Name" = "jenkins dashboard"
  }
}
