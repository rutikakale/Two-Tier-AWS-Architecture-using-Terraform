terraform {
  backend "s3" {
    bucket = "rutikakale15"
    key = "terraform.tfstate"
    region = "ap-south-1" #remote backend
  }
}
provider "aws" {
    region = var.region
  
}
# create a vpc
resource "aws_vpc" "my_vpc" {
    cidr_block = var.vpc_cidr
    tags = {
      Name = "${var.project_name}-vpc"
    }
}
# create a private subnet
resource "aws_subnet" "private-subnet" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = var.private_cidr
    availability_zone = var.az1
    tags = {
      Name = "${var.project_name}-private-subnet"
    }
}

# create a public subnet
resource "aws_subnet" "public-subnet" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = var.public_cidr
    availability_zone = var.az2
    tags = {
      Name = "${var.project_name}-public-subnet"
    }
}
# create a internet gateway
resource "aws_internet_gateway" "my-IGW" {
    vpc_id = aws_vpc.my_vpc.id
    tags = {
        Name = "${var.project_name}-IGW"
    }
}
#create a default RT
resource "aws_default_route_table" "main-RT" {
    default_route_table_id = aws_vpc.my_vpc.default_route_table_id
    tags = {
      Name = "${var.project_name}-main-RT"
    }
}
# add route in main route table
resource "aws_route" "aws_route" {
  route_table_id = aws_default_route_table.main-RT.id
  destination_cidr_block = var.IGW_cidr
  gateway_id = aws_internet_gateway.my-IGW.id
}
# create security group
resource "aws_security_group" "my-sg" {
    vpc_id = aws_vpc.my_vpc.id
    name = "${var.project_name}-sg"
    # SSH
  ingress {
    description = "Allow SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS (optional)
  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
depends_on = [ aws_vpc.my_vpc ] # explicite depedancy
}
# create a public server
resource "aws_instance" "public-server" {
    subnet_id = aws_subnet.public-subnet.id
    ami = var.ami
    instance_type = var.instance
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.my-sg.id]
    tags = {
      Name = "${var.project_name}-app-server"
    }
    depends_on = [ aws_security_group.my-sg ]
  
}
# create a private server
resource "aws_instance" "private-server" {
    subnet_id = aws_subnet.private-subnet.id
    ami = var.ami
    instance_type = var.instance
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.my-sg.id]
    tags = {
      Name = "${var.project_name}-db-server"
    }
    depends_on = [ aws_security_group.my-sg ]
  
}



