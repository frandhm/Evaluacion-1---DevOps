resource "aws_instance" "inovatech_server" {
  ami = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"

  key_name = "inovatech-key"

  security_groups = [aws_security_group.web_sg.name]

  user_data = <<-EOF
                #!/bin/bash
                apt update -y
                apt install nginx -y
                systemctl start nginx
                systemctl enable nginx
                EOF

    tags = {
        name = "inovatech-frontend"
    }
}

resource "aws_instance" "inovatech_server" {
  ami = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"

  key_name = "inovatech-key"

  security_groups = [aws_security_group.web_sg.name]

  user_data = <<-EOF
                #!/bin/bash
                apt update -y
                apt install nginx -y
                systemctl start nginx
                systemctl enable nginx
                EOF

    tags = {
        name = "inovatech-backend"
    }
}