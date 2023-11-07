# provider로 AWS 사용
provider "aws" {
  region = "ap-northeast-2" 
}


######################################################################
# VPC
######################################################################

resource "aws_vpc" "keem-vpc" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "keem-vpc"
  }
}


######################################################################
# Subnet
######################################################################

# Public Subnet
resource "aws_subnet" "keem-pub-sub" {
  vpc_id     = aws_vpc.keem-vpc.id
  cidr_block = "10.0.0.0/24" 
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true    # public ip를 할당하기 위해 true로 설정

  tags = {
    Name = "keem-pub-sub" # 서브넷 이름 설정
  }
}


# Private Web
resource "aws_subnet" "keem-pri-sub-web" {
  vpc_id     = aws_vpc.keem-vpc.id
  cidr_block = "10.0.10.0/24" 
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "keem-pri-sub-web" # 서브넷 이름 설정
  }
}

# Private WAS
resource "aws_subnet" "keem-pri-sub-was" {
  vpc_id     = aws_vpc.keem-vpc.id
  cidr_block = "10.0.20.0/24" 
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "keem-pri-sub-was" # 서브넷 이름 설정
  }
}

# Private DB
resource "aws_subnet" "keem-pri-sub-db" {
  vpc_id     = aws_vpc.keem-vpc.id
  cidr_block = "10.0.30.0/24" 
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "keem-pri-sub-db" # 서브넷 이름 설정
  }
}


######################################################################
# Internet Gateway
######################################################################

resource "aws_internet_gateway" "keem-igw" {
  vpc_id = aws_vpc.keem-vpc.id
  
  tags = {
    Name = "keem-igw"
  }
}


######################################################################
# NAT Gateway
######################################################################

resource "aws_eip" "keem-nip" {
  domain = "vpc"
  
  tags = {
    Name = "keem-nip"
  }
}

resource "aws_nat_gateway" "keem-ngw" {
  allocation_id = aws_eip.keem-nip.id
  subnet_id     = aws_subnet.keem-pub-sub.id
  
  tags = {
    Name = "keem-ngw"
  }
}


######################################################################
# Route Table
######################################################################

resource "aws_route_table" "keem-pub-rt" {
    vpc_id = aws_vpc.keem-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.keem-igw.id
    }
    tags = {
        Name = "keem-pub-rt"
    }
}

# public subnet을 public route table에 연결
resource "aws_route_table_association" "keem-pub-route"{
    subnet_id = aws_subnet.keem-pub-sub.id
    route_table_id = aws_route_table.keem-pub-rt.id
}




resource "aws_route_table" "keem-pri-rt"{
    vpc_id = aws_vpc.keem-vpc.id
    
    tags = {
       Name = "keem-pri-rt"
   }
}

resource "aws_route" "keem-pri-route"{
    route_table_id = aws_route_table.keem-pri-rt.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.keem-ngw.id
}

# private web subnet을 pirvate route table에 연결
resource "aws_route_table_association" "keem-pri-route-web"{
    subnet_id = aws_subnet.keem-pri-sub-web.id
    route_table_id = aws_route_table.keem-pri-rt.id
}

# private was subnet을 pirvate route table에 연결
resource "aws_route_table_association" "keem-pri-route-was"{
    subnet_id = aws_subnet.keem-pri-sub-was.id
    route_table_id = aws_route_table.keem-pri-rt.id
}

# private db subnet을 pirvate route table에 연결
resource "aws_route_table_association" "keem-pri-route-db"{
    subnet_id = aws_subnet.keem-pri-sub-db.id
    route_table_id = aws_route_table.keem-pri-rt.id
}


######################################################################
# Security Groups
######################################################################

# Bastion SG (Public)
resource "aws_security_group" "keem-sg-pub-bastion" {
  name = "keem-sg-pub-bastion"
  vpc_id = aws_vpc.keem-vpc.id

  ingress {
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
     Name = "keem-sg-pub-bastion"
  }
}

# Web SG (Private)
resource "aws_security_group" "keem-sg-pri-web" {
  name = "keem-sg-pri-web"
  vpc_id = aws_vpc.keem-vpc.id

  ingress {
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    security_groups = [aws_security_group.keem-sg-pub-bastion.id]
  }
  ingress {
    from_port   = var.http_port
    to_port     = var.http_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
     Name = "keem-sg-pri-web"
  }
}


# WAS SG (Private)
resource "aws_security_group" "keem-sg-pri-was" {
  name = "keem-sg-pri-was"
  vpc_id = aws_vpc.keem-vpc.id

  ingress {
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    security_groups = [aws_security_group.keem-sg-pub-bastion.id]
  }
  ingress {
    from_port   = var.https_port
    to_port     = var.https_port
    protocol    = "tcp"
    cidr_blocks = ["10.0.10.0/24", "10.0.20.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
     Name = "keem-sg-pri-was"
  }
}


# DB SG (Private)
resource "aws_security_group" "keem-sg-pri-db" {
  name = "keem-sg-pri-db"
  vpc_id = aws_vpc.keem-vpc.id

  ingress {
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    security_groups = [aws_security_group.keem-sg-pub-bastion.id]
  }
  ingress {
    from_port   = var.mysql_port
    to_port     = var.mysql_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
     Name = "keem-sg-pri-db"
  }
}


######################################################################
# Key Pair
######################################################################

# RSA 알고리즘을 이용해 private 키 생성
resource "tls_private_key" "keem-pri-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# private 키를 가지고 keypair 파일 생성
resource "aws_key_pair" "keem-key-pair" {
  key_name   = "keem-key-pair" # 키 페어 이름 설정
  public_key = tls_private_key.keem-pri-key.public_key_openssh
}

# 키 파일을 생성하고 로컬에 다운로드 (테라폼 실행 시 현재 경로에 .pem 파일 다운로드)
#resource "local_file" "ssh_key" {
#  filename = "${aws_key_pair.keem-key-pair.key_name}.pem"
#  content = tls_private_key.keem-pri-key.private_key_pem
#}


######################################################################
# EC2
######################################################################

# Bastion Server (Public)
resource "aws_instance" "keem-pub-bastion" {
  ami = "ami-0bcb37eab443e2f5b"
  instance_type = var.instance_type
  availability_zone = "ap-northeast-2a"
  
  subnet_id = aws_subnet.keem-pri-sub-web.id
  vpc_security_group_ids = [aws_security_group.keem-sg-pub-bastion.id]
  key_name = aws_key_pair.keem-key-pair.key_name # 사용할 키 페어 설정

  tags = {
    Name = "keem-pub-bastion" # 인스턴스 이름 설정
  }
}

# Web Server (Private)
resource "aws_instance" "keem-pri-web" {
  ami = "ami-0bcb37eab443e2f5b"
  instance_type = var.instance_type
  availability_zone = "ap-northeast-2a"
  
  subnet_id = aws_subnet.keem-pub-sub.id
  vpc_security_group_ids = [aws_security_group.keem-sg-pri-web.id]
  key_name = aws_key_pair.keem-key-pair.key_name # 사용할 키 페어 설정

  tags = {
    Name = "keem-pri-web" # 인스턴스 이름 설정
  }
}

# WAS Server (Private)
resource "aws_instance" "keem-pri-was" {
  ami = "ami-0bcb37eab443e2f5b"
  instance_type = var.instance_type
  availability_zone = "ap-northeast-2a"
  
  subnet_id = aws_subnet.keem-pri-sub-was.id
  vpc_security_group_ids = [aws_security_group.keem-sg-pri-was.id]
  key_name = aws_key_pair.keem-key-pair.key_name # 사용할 키 페어 설정

  tags = {
    Name = "keem-pri-was" # 인스턴스 이름 설정
  }
}

# DB Server (Private)
resource "aws_instance" "keem-pri-db" {
  ami = "ami-0bcb37eab443e2f5b"
  instance_type = var.instance_type
  availability_zone = "ap-northeast-2a"
  
  subnet_id = aws_subnet.keem-pri-sub-db.id
  vpc_security_group_ids = [aws_security_group.keem-sg-pri-db.id]
  key_name = aws_key_pair.keem-key-pair.key_name # 사용할 키 페어 설정

  tags = {
    Name = "keem-pri-db" # 인스턴스 이름 설정 
  }
}
