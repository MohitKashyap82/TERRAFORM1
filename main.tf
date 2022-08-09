#  Provide configuration and provide required keys 

provider "aws" {
  region     = "us-east-1"

}

# 2 Create vpc  

resource "aws_vpc" "my_vpc_terraform" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "tf-vpc-example"
  }
}

# 3 Create subnet 
resource "aws_subnet" "my_subnet_terraform" {
  vpc_id            = aws_vpc.my_vpc_terraform.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "tf-subnet-example"
  }
}

# 4 Create internet gateway

resource "aws_internet_gateway" "internet_gw_terraform" {
  vpc_id = aws_vpc.my_vpc_terraform.id

  tags = {
    Name = "internet gateway terraform"
  }
}

# 4 Create route table 

resource "aws_route_table" "route_table_terraform" {
  vpc_id = aws_vpc.my_vpc_terraform.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gw_terraform.id
  }



  tags = {
    Name = "route table terraform"
  }
}

# 5 Associate subnet with route table 

resource "aws_route_table_association" "route_association_terraform" {
  subnet_id      = aws_subnet.my_subnet_terraform.id
  route_table_id = aws_route_table.route_table_terraform.id
}

# 6 Create a security group 

resource "aws_security_group" "security_group_terraform" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.my_vpc_terraform.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    Name = "allow_tls"
  }
}

# 7 Create a network interface with an ip in the subnet that was created in step 4. 

resource "aws_network_interface" "network_interface_terraform" {
  subnet_id       = aws_subnet.my_subnet_terraform.id
  private_ips     = ["172.16.10.50"]
  security_groups = [aws_security_group.security_group_terraform.id]
}

# 8 Assign an elastic  IP to the internet interface created in step 7. 
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.network_interface_terraform.id
  associate_with_private_ip = "172.16.10.50"
  depends_on = [
    aws_internet_gateway.internet_gw_terraform
  ]

}

# 9 . Create Ubuntu server and install / enable apache 2 
resource "aws_instance" "web_server_terraform" {
  ami               = "ami-052efd3df9dad4825"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "default-ec2"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.network_interface_terraform.id

  }
  user_data = <<-EOF
  sudo apt update -y
  sudo apt install apache2 -y
  sudo systemctl start apache2
  sudo bash -c 'echo your very first web server > /var/www/html/index.html'
  EOF

}

# Youutube video link : https://www.youtube.com/watch?v=SLB_c_ayRMo&t=11s
