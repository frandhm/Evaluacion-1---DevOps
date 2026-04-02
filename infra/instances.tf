resource "aws_instance" "inovatech_frontend" {
  ami = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  
  key_name = "inovatech-key"

  vpc_security_group_ids = [aws_security_group.frontend_sg.id]

  subnet_id = aws_subnet.public.id

  user_data = <<-EOF
                #!/bin/bash
                apt update -y
                apt upgrade -y
                apt install nginx docker.io -y
                systemctl start nginx
                systemctl enable nginx
                systemctl start docker
                systemctl enable docker
                EOF

    tags = {
        Name = "inovatech-frontend"
    }
}

resource "aws_instance" "inovatech_backend" {
  ami = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"

  key_name = "inovatech-key"

  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  subnet_id = aws_subnet.private_app.id

  user_data = <<-EOF
                #!/bin/bash
                apt update -y
                apt upgrade -y
                apt install docker.io -y
                systemctl start docker
                systemctl enable docker
                EOF

    tags = {
        Name = "inovatech-backend"
    }
}

resource "aws_instance" "inovatech_database" {
  ami = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"

  key_name = "inovatech-key"

  vpc_security_group_ids = [aws_security_group.db_sg.id]

  subnet_id = aws_subnet.private_app.id

  user_data = <<-EOF
                #!/bin/bash
                apt update -y
                apt upgrade -y
                apt install mysql-server -y
                systemctl start mysql
                systemctl enable mysql
                EOF

    tags = {
        Name = "inovatech-database"
    }
}