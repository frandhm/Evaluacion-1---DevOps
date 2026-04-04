resource "aws_instance" "inovatech_frontend" {
  ami                    = "ami-0ec10929233384c7f"
  instance_type          = "t3.micro"
  key_name               = "inovatech-key"
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  subnet_id              = aws_subnet.public.id

  depends_on = [
    aws_nat_gateway.nat,
    aws_route_table_association.public_assoc
  ]

  user_data = <<-EOF
                #!/bin/bash
                set -e
                exec > /var/log/user-data.log 2>&1

                export DEBIAN_FRONTEND=noninteractive

                echo "=== Actualizando sistema ==="
                apt update -y

                echo "=== Instalando dependencias base ==="
                apt install -y nginx git ca-certificates curl gnupg lsb-release

                echo "=== Instalando Node.js 20 via NVM ==="
                curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | sudo -u ubuntu bash
                export NVM_DIR="/home/ubuntu/.nvm"
                source "$NVM_DIR/nvm.sh"
                sudo -u ubuntu bash -c 'source ~/.nvm/nvm.sh && nvm install 20 && nvm use 20 && nvm alias default 20'

                # Crear symlinks para que node y npm estén disponibles globalmente
                NODE_PATH=$(sudo -u ubuntu bash -c 'source ~/.nvm/nvm.sh && nvm which 20')
                NPM_PATH=$(dirname $NODE_PATH)/npm
                ln -sf $NODE_PATH /usr/local/bin/node
                ln -sf $NPM_PATH /usr/local/bin/npm

                node --version
                npm --version

                echo "=== Instalando Docker ==="
                install -m 0755 -d /etc/apt/keyrings
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
                chmod a+r /etc/apt/keyrings/docker.asc
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
                apt update -y
                apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                systemctl start docker
                systemctl enable docker
                usermod -aG docker ubuntu

                echo "=== Clonando repositorio ==="
                cd /home/ubuntu
                sudo -u ubuntu git clone https://github.com/frandhm/Evaluacion-1---DevOps.git
                chown -R ubuntu:ubuntu /home/ubuntu/Evaluacion-1---DevOps

                echo "=== Construyendo frontend ==="
                sudo -u ubuntu bash -c '
                  source ~/.nvm/nvm.sh
                  nvm use 20
                  cd ~/Evaluacion-1---DevOps/frontend
                  npm install
                  npm run build
                '

                echo "=== Copiando build a nginx ==="
                rm -rf /var/www/html/*
                cp -r /home/ubuntu/Evaluacion-1---DevOps/frontend/dist/* /var/www/html/
                ls /var/www/html/

                echo "=== Configurando nginx ==="
                printf 'server {\n    listen 80;\n    location / {\n        root /var/www/html;\n        try_files $uri $uri/ /index.html;\n    }\n    location /api/ {\n        proxy_pass http://10.0.2.20:8080/api/;\n        proxy_set_header Host $host;\n        proxy_set_header X-Real-IP $remote_addr;\n    }\n}\n' > /etc/nginx/sites-available/default

                nginx -t
                systemctl start nginx
                systemctl enable nginx
                systemctl restart nginx

                echo "=== Frontend listo ==="
                EOF

  tags = {
    Name = "inovatech-frontend"
  }
}

resource "aws_instance" "inovatech_backend" {
  ami                    = "ami-0ec10929233384c7f"
  instance_type          = "t3.micro"
  key_name               = "inovatech-key"
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  subnet_id              = aws_subnet.private.id
  private_ip             = "10.0.2.20"

  depends_on = [
    aws_nat_gateway.nat,
    aws_route_table_association.private_assoc
  ]

  user_data = <<-EOF
                #!/bin/bash
                set -e
                exec > /var/log/user-data.log 2>&1

                echo "=== Actualizando sistema ==="
                apt update -y
                apt upgrade -y

                echo "=== Instalando Java, Maven y Git ==="
                apt install -y openjdk-17-jdk maven git ca-certificates curl gnupg lsb-release
                java -version
                mvn -version

                echo "=== Instalando Docker ==="
                install -m 0755 -d /etc/apt/keyrings
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
                chmod a+r /etc/apt/keyrings/docker.asc
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
                apt update -y
                apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                systemctl start docker
                systemctl enable docker
                usermod -aG docker ubuntu

                echo "=== Clonando repositorio ==="
                cd /home/ubuntu
                sudo -u ubuntu git clone https://github.com/frandhm/Evaluacion-1---DevOps.git
                chown -R ubuntu:ubuntu /home/ubuntu/Evaluacion-1---DevOps

                echo "=== Esperando que la base de datos esté lista ==="
                apt install -y mysql-client
                until mysql -h 10.0.2.10 -u backend -propa ropitadb -e "SELECT 1;" > /dev/null 2>&1; do
                    echo "Esperando DB en 10.0.2.10..."
                    sleep 5
                done
                echo "Base de datos lista"

                echo "=== Compilando backend ==="
                cd /home/ubuntu/Evaluacion-1---DevOps/backend
                sudo -u ubuntu mvn clean package -DskipTests

                echo "=== Iniciando aplicación ==="
                sudo -u ubuntu nohup java -jar target/*.jar > /home/ubuntu/app.log 2>&1 &

                echo "=== Esperando que el backend levante ==="
                until curl -s http://localhost:8080/api/ropas > /dev/null 2>&1; do
                    echo "Esperando backend..."
                    sleep 5
                done

                echo "=== Backend listo ==="
                EOF

  tags = {
    Name = "inovatech-backend"
  }
}

resource "aws_instance" "inovatech_database" {
  ami                    = "ami-0ec10929233384c7f"
  instance_type          = "t3.micro"
  key_name               = "inovatech-key"
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  subnet_id              = aws_subnet.private.id
  private_ip             = "10.0.2.10"

  depends_on = [
    aws_nat_gateway.nat,
    aws_route_table_association.private_assoc
  ]

  user_data = <<-EOF
                #!/bin/bash
                set -e
                exec > /var/log/user-data.log 2>&1

                echo "=== Actualizando sistema ==="
                apt update -y

                echo "=== Instalando MySQL ==="
                DEBIAN_FRONTEND=noninteractive apt install -y mysql-server
                systemctl start mysql
                systemctl enable mysql

                echo "=== Configurando bind-address ==="
                sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
                systemctl restart mysql

                echo "=== Esperando que MySQL esté listo ==="
                until mysqladmin ping -h localhost --silent; do
                    echo "Esperando MySQL..."
                    sleep 2
                done

                echo "=== Configurando base de datos ==="
                mysql -e "CREATE DATABASE IF NOT EXISTS ropitadb;"
                mysql -e "CREATE USER IF NOT EXISTS 'backend'@'%' IDENTIFIED BY 'ropa';"
                mysql -e "ALTER USER 'backend'@'%' IDENTIFIED BY 'ropa';"
                mysql -e "GRANT ALL PRIVILEGES ON ropitadb.* TO 'backend'@'%';"
                mysql -e "FLUSH PRIVILEGES;"

                mysql ropitadb -e "CREATE TABLE IF NOT EXISTS ropa (
                    id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    nombre VARCHAR(255),
                    descripcion VARCHAR(255),
                    precio DOUBLE
                );"

                mysql ropitadb -e "INSERT IGNORE INTO ropa (id, nombre, descripcion, precio, imagen) VALUES
                (1, 'Polera básica', 'Polera de algodón', 9990, 'https://m.media-amazon.com/images/I/61dI1ura9YL.jpg'),
                (2, 'Jeans azul', 'Jeans clásico azul', 24990, 'https://fashionspark.com/cdn/shop/files/p-670692702-1.jpg?v=1751044303'),
                (3, 'Chaqueta', 'Chaqueta de invierno', 39990, 'https://gear.blizzard.com/cdn/shop/products/OVERMJ0005_A.jpg?v=1756835889&width=1445&logged_in_customer_id=&lang=es');"

                echo "=== Verificando datos ==="
                mysql ropitadb -e "SELECT * FROM ropa;"

                echo "=== Base de datos lista ==="
                EOF

  tags = {
    Name = "inovatech-database"
  }
}