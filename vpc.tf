provider "aws" {
  region = "ap-southeast-1"
}
resource "aws_vpc" "test-vpc" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "public-subnet" {
  vpc_id     = aws_vpc.test-vpc.id
  cidr_block = "10.0.0.0/24"
 
  tags = {
    Name = "Public-subnet"
  }
}
resource "aws_subnet" "private-subnet" {
  vpc_id     = aws_vpc.test-vpc.id
  cidr_block = "10.0.1.0/24"
 
  tags = {
    Name = "Private-subnet"#security group
}
}
 
resource "aws_key_pair" "terraform_key" {
  key_name   = "terraform.key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDGy7AIRcu5KFB7xYMGThJcvTV64Fbh6JWZ9QeqIoci8aIHd++9fCLNYmD/dDBaV94x2cyGVjB1kndFpx99JdTK/AcwLkwMJqzLW0gpNBXx6nB+n+lT+JBcbq3IR/+m3PvH/R9kkZonqHgW9auTQQ5yD6pfeL+YuBvkJiWVwYCz8Oijn+vmamoxYY3JU/5Ld7U1ydgGnyXG3rZoUkw5aKHbHwvagfWMrSGiCA1fTZRm1nK35Nrj3h4KGtnnpyvS3C30nmGyX06JnbsZ8JWzmcGF8hq4Ff44k5YBQQ+yLEIEYDXHpgN91hJrmo0vNU5QDkXFLLTIwYYzuiig0xqV1+BF8HeRuceqQUPBKN+hX2LGKkRBK150bWUFsVG9Ivj5CSNG6GRW3gvWDobuX8Bq/tQ0QKaPu47ygBR5AzH9qDrO42/IYkEUGjyNn3R8GidUri2nqf1W9kf5h+kTxf9BUMLWD7fcqifv9n93lgSjRA864JvX3C1M4OKhlYbhBUnA0mM= root@terraform"
}
 
 
#security group
resource "aws_security_group" "web_access" {
  name        = "web_access"
  vpc_id      = aws_vpc.test-vpc.id
  description = "allow ssh and http"
 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  ingress {
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
}
resource "aws_internet_gateway" "test-igw" {
  vpc_id = aws_vpc.test-vpc.id
 
  tags = {
    Name = "test-igw"
  }
}
#Public route table code
 
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.test-vpc.id
 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test-igw.id
  }
 
 
  tags = {
    Name = "public-rt"#route Tatable assosication code
}
}
resource "aws_route_table_association" "public-asso" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-rt.id
}
resource "aws_instance" "testing-server" {
  ami             = "ami-0e97ea97a2f374e3d"
  subnet_id       = aws_subnet.public-subnet.id
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.web_access.id}"]
  key_name        = "terraform.key"
  tags = {
    Name     = "test-server"
    Stage    = "testing"
    Location = "singapore"
  }
 
}
resource "aws_instance" "database-server" {
  ami             = "ami-0e97ea97a2f374e3d"
  subnet_id       = aws_subnet.private-subnet.id
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.web_access.id}"]
  key_name        = "terraform.key"
  tags = {
    Name     = "database-server"
    Stage    = "stage-base"
    Location = "singapore"
  }
}
##create a public ip for Nat gateway
resource "aws_eip" "nat-eip" {
}
### create Nat gateway
resource "aws_nat_gateway" "my-ngw" {
  allocation_id = "${aws_eip.nat-eip.id}"
  subnet_id     = "${aws_subnet.public-subnet.id}"
}
resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.test-vpc.id
 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.my-ngw.id}"
  }
 
 
  tags = {
    Name = "private-rt"
  }
}
##route Tatable assosication code
resource "aws_route_table_association" "private-asso" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private-rt.id
}
 
 
 
/*
#security group end here
 
 
resource "aws_instance" "server" {
  ami                    = "ami-0e97ea97a2f374e3d"
  availability_zone      = "ap-southeast-1a"
  instance_type          = "t2.micro"
  key_name               = "terraform.key"
  vpc_security_group_ids = [data.aws_security_group.previous-sg.id]
 
  tags = {
    Name     = "World"
    Stage    = "testing"
    Location = "INDIA"
  }
 
  root_block_device {
    volume_size           = "26"
    volume_type           = "gp2"
    delete_on_termination = true
  }
 
  #additional data disk
  ebs_block_device {
    device_name           = "/dev/xvdb"
    volume_size           = "10"
    volume_type           = "gp2"
    delete_on_termination = true
  }
  user_data = <<-EOF
        #!/bin/bash
        sudo yum install httpd -y
        sudo systemctl start httpd
        sudo systemctl enable httpd
        echo "<h1>sample webserver using terraform</h1>" | sudo tee /var/www/html/index.html
  EOF
}
 
*/
