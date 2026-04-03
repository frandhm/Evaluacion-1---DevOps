resource "aws_instance" "inovatech_frontend" {
  ami = "ami-0ec10929233384c7f"
  instance_type = "t3.micro"
  
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
  ami = "ami-0ec10929233384c7f"
  instance_type = "t3.micro"

  key_name = "inovatech-key"

  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  subnet_id = aws_subnet.private.id

  private_ip = "10.0.2.20"

  user_data = <<-EOF
                #!/bin/bash

                apt update -y
                apt upgrade -y

                apt install openjdk-17-jdk maven git docker.io -y

                systemctl start docker
                systemctl enable docker

                usermod -aG docker ubuntu

                cd /home/ubuntu

                git clone https://github.com/frandhm/Evaluacion-1---DevOps.git


                cd Evaluacion-1---DevOps/backend

                mvn clean package -DskipTests

                sleep 30

                nohup java -jar target/*.jar > /home/ubuntu/app.log 2>&1 &
                EOF

    tags = {
        Name = "inovatech-backend"
    }
}

resource "aws_instance" "inovatech_database" {
  ami = "ami-0ec10929233384c7f"
  instance_type = "t3.micro"

  key_name = "inovatech-key"

  vpc_security_group_ids = [aws_security_group.db_sg.id]

  subnet_id = aws_subnet.private.id

  private_ip = "10.0.2.10"

  user_data = <<-EOF
                #!/bin/bash
                apt update -y

                DEBIAN_FRONTEND=noninteractive apt install mysql-server -y

                systemctl start mysql
                systemctl enable mysql

                sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
                systemctl restart mysql

                until mysqladmin ping -h "localhost" --silent; do
                    sleep 2
                done

                mysql -e "CREATE DATABASE IF NOT EXISTS ropitadb;"
                mysql -e "CREATE USER IF NOT EXISTS 'backend'@'%' IDENTIFIED BY 'ropa';"
                mysql -e "ALTER USER 'backend'@'%' IDENTIFIED BY 'ropa';"
                mysql -e "GRANT ALL PRIVILEGES ON ropitadb.* TO 'backend'@'%';"
                mysql -e "FLUSH PRIVILEGES;"

                mysql -e "USE ropitadb; CREATE TABLE IF NOT EXISTS ropa (
                    id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    nombre VARCHAR(255),
                    descripcion VARCHAR(255),
                    precio DOUBLE
                );"

                mysql -e "USE ropitadb;
                INSERT INTO ropa (nombre, descripcion, precio)
                SELECT 'Polera básica', 'Polera de algodón', 9990
                WHERE NOT EXISTS (SELECT 1 FROM ropa LIMIT 1);"

                mysql -e "USE ropitadb;
                INSERT INTO ropa (nombre, descripcion, precio)
                SELECT 'Jeans azul', 'Jeans clásico azul', 24990
                WHERE NOT EXISTS (SELECT 1 FROM ropa LIMIT 1);"

                mysql -e "USE ropitadb;
                INSERT INTO ropa (nombre, descripcion, precio)
                SELECT 'Chaqueta', 'Chaqueta de invierno', 39990
                WHERE NOT EXISTS (SELECT 1 FROM ropa LIMIT 1);"
                EOF

    tags = {
        Name = "inovatech-database"
    }
}