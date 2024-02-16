# Configure AWS provider with proper credentials
provider "aws" {
  region  = "us-east-1"
  profile = "Abdulhakeem"
}

# Use the existing VPC if one does not exist
resource "aws_vpc" "myAppp-vpc" {

  tags = {
    Name = "my-vpc"
  }
}

# Use the first public subnet from the module as the subnet for the EC2 instance
data "aws_subnet" "public_subnet" {
  count = length(module.myAppp-vpc.public_subnets)

  vpc_id     = module.myAppp-vpc.vpc_id
  cidr_block = module.myAppp-vpc.public_subnets[count.index]
}

# Create security group for the EC2 instance
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2 security group"
  description = "allow access on ports 8080, 22, 80, and 443"
  vpc_id      = module.myAppp-vpc.vpc_id

  # ... (rest of your security group configuration)
}

# Use data source to get a registered Amazon Linux 2 AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

# Launch the EC2 instance
resource "aws_instance" "ec2_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.small"
  subnet_id              = data.aws_subnet.public_subnet[0].id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  key_name               = "kim"
  tags = {
    Name = "mongodb_server"
  }
}

# Create an S3 bucket within the specified VPC
resource "aws_s3_bucket" "resource_name" {
  bucket = "atrihomes-mongo-db-backup" # Specify a unique S3 bucket name

  tags = {
    Name = "mongodb_backup"
  }
}

# Print the URL of the MongoDB server
output "website_url" {
  value = join("", ["http://", aws_instance.ec2_instance.public_ip])
}
