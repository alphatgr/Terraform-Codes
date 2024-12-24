#Details of CLOUD Provider
provider "aws" {
    region = "ap-south-1"
}

# Availability Zones
data "aws_availability_zones" "available" {
    state = "available"
}

# Create the VPC
resource "aws_vpc" "project_vpc" {
    cidr_block = "10.0.0.0/25"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "Project-VPC"
    }
}


# #Create IPv6 CIDR Block for the VPC
# resource "aws_vpc_ipv6_cidr_block_association" "project_vpc_ipv6" {
#     vpc_id = aws_vpc.project_vpc.id
#     ipv6_cidr_block = "Amazon-Provided"
#  }

# Create the Public Subnets
resource "aws_subnet" "public_subnets" {
    count = 2
    vpc_id = aws_vpc.project_vpc.id
    cidr_block = cidrsubnet(aws_vpc.project_vpc.cidr_block,3,count.index)
    map_public_ip_on_launch = true
    availability_zone = element(data.aws_availability_zones.available.names,count.index)
    tags = {
        Name="Project-Public-Subnet-$(count.index+1)"
        Type="Public"
    }
}

# Create the Private Subnets
resource "aws_subnet" "private_subnets" {
    count = 2
    vpc_id = aws_vpc.project_vpc.id
    cidr_block = cidrsubnet(aws_vpc.project_vpc.cidr_block,3,count.index)
    availability_zone = element(data.aws_availability_zones.available.names,count.index)
    tags = {
        Name="Project-Private-Subnet-$(count.index+1)"
        Type="Private"
    }
}

# Internet Gateway for Public Subnet
resource "aws_internet_gateway" "project-igw" {
    vpc_id = aws_vpc.project_vpc.id
    tags = {
        Name="Project-IGW"
    }
}

# Route Table for Public Subnets
resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.project_vpc.id
    tags = {
        Name="Public-Route-Table"
    }
}

# Add route to the public route table
resource "aws_route" "public_route" {
    route_table_id=aws_route_table.public_route_table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project-igw.id
}

# Associate the Public subnets with the public route table
resource "aws_route_table_association" "public_route_table_asso" {
    count=2
    subnet_id = aws_subnet.public_subnets[count.index].id
    route_table_id = aws_route_table.public_route_table.id 
}

# Output Values

output "vpc_id" {
    description = "ID-of-VPC"
    value=aws_vpc.project_vpc.id
}

output "public_subnets" {
    description = "ID-of-Public-Subnets"
    value=aws_subnet.public_subnets[*].id
}

output "private_subnets" {
    description = "ID-of-Private-Subnets"
    value = aws_subnet.private_subnets[*].id
}