resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Internet Gateway (para el frontend)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# Elastic IP para NAT
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# NAT Gateway (permite salida a Internet desde subred privada)
resource "aws_nat_gateway" "nat" {
  depends_on = [aws_internet_gateway.igw]
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id
}

# Route Table pública
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
}

# Ruta a Internet
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Asociación subnet pública
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# Route Table privada
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
}

# Ruta hacia NAT 
resource "aws_route" "private_nat_access" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# Asociación subnet privada
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_app.id
  route_table_id = aws_route_table.private_rt.id
}