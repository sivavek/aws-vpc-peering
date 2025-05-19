provider "aws" {
  region = "us-east-1"
  alias  = "east1"
}

provider "aws" {
  region = "us-west-1"
  alias  = "west1"
}

# Random string for unique S3 bucket name
resource "random_string" "suffix" {
  length  = 8
  special = false
  lower   = true
  upper   = false
}

# S3 Bucket for VPC Flow Logs
resource "aws_s3_bucket" "flow_logs" {
  provider = aws.east1
  bucket   = "vpc-flow-logs-${random_string.suffix.result}"
}

# VPC in us-east-1 (A)
resource "aws_vpc" "vpc_east_1a" {
  provider             = aws.east1
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "VPC-East-1A"
  }
}

# VPC in us-east-1 (B)
resource "aws_vpc" "vpc_east_1b" {
  provider             = aws.east1
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "VPC-East-1B"
  }
}

# VPC in us-west-1
resource "aws_vpc" "vpc_west_1" {
  provider             = aws.west1
  cidr_block           = "10.2.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "VPC-West-1"
  }
}

# Internet Gateway (only for VPC East 1A for jump host)
resource "aws_internet_gateway" "igw_east_1a" {
  provider = aws.east1
  vpc_id   = aws_vpc.vpc_east_1a.id
  
  tags = {
    Name = "IGW-East-1A"
  }
}

# Public Subnet in VPC East 1A (for jump host)
resource "aws_subnet" "public_east_1a" {
  provider          = aws.east1
  vpc_id            = aws_vpc.vpc_east_1a.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "Public-East-1A"
  }
}

# Private Subnets
resource "aws_subnet" "private_east_1a" {
  provider          = aws.east1
  vpc_id            = aws_vpc.vpc_east_1a.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  
  tags = {
    Name = "Private-East-1A"
  }
}

resource "aws_subnet" "private_east_1b" {
  provider          = aws.east1
  vpc_id            = aws_vpc.vpc_east_1b.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "us-east-1b"
  
  tags = {
    Name = "Private-East-1B"
  }
}

resource "aws_subnet" "private_west_1" {
  provider          = aws.west1
  vpc_id            = aws_vpc.vpc_west_1.id
  cidr_block        = "10.2.2.0/24"
  availability_zone = "us-west-1b"
  
  tags = {
    Name = "Private-West-1"
  }
}

# Route Tables
resource "aws_route_table" "public_rt_east_1a" {
  provider = aws.east1
  vpc_id   = aws_vpc.vpc_east_1a.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_east_1a.id
  }
  
  tags = {
    Name = "Public-RT-East-1A"
  }
}

resource "aws_route_table" "private_rt_east_1a" {
  provider = aws.east1
  vpc_id   = aws_vpc.vpc_east_1a.id
  
  tags = {
    Name = "Private-RT-East-1A"
  }
}

resource "aws_route_table" "private_rt_east_1b" {
  provider = aws.east1
  vpc_id   = aws_vpc.vpc_east_1b.id
  
  tags = {
    Name = "Private-RT-East-1B"
  }
}

resource "aws_route_table" "private_rt_west_1" {
  provider = aws.west1
  vpc_id   = aws_vpc.vpc_west_1.id
  
  tags = {
    Name = "Private-RT-West-1"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_rta_east_1a" {
  provider       = aws.east1
  subnet_id      = aws_subnet.public_east_1a.id
  route_table_id = aws_route_table.public_rt_east_1a.id
}

resource "aws_route_table_association" "private_rta_east_1a" {
  provider       = aws.east1
  subnet_id      = aws_subnet.private_east_1a.id
  route_table_id = aws_route_table.private_rt_east_1a.id
}

resource "aws_route_table_association" "private_rta_east_1b" {
  provider       = aws.east1
  subnet_id      = aws_subnet.private_east_1b.id
  route_table_id = aws_route_table.private_rt_east_1b.id
}

resource "aws_route_table_association" "private_rta_west_1" {
  provider       = aws.west1
  subnet_id      = aws_subnet.private_west_1.id
  route_table_id = aws_route_table.private_rt_west_1.id
}

# VPC Peering Connections
resource "aws_vpc_peering_connection" "peer_east_1a_east_1b" {
  provider    = aws.east1
  vpc_id      = aws_vpc.vpc_east_1a.id
  peer_vpc_id = aws_vpc.vpc_east_1b.id
  auto_accept = true
  
  tags = {
    Name = "VPC-Peer-East-1A-to-East-1B"
  }
}

resource "aws_vpc_peering_connection" "peer_east_1a_west_1" {
  provider    = aws.east1
  vpc_id      = aws_vpc.vpc_east_1a.id
  peer_vpc_id = aws_vpc.vpc_west_1.id
  peer_region = "us-west-1"
  
  tags = {
    Name = "VPC-Peer-East-1A-to-West-1"
  }
}

resource "aws_vpc_peering_connection_accepter" "peer_east_1a_west_1_accepter" {
  provider                  = aws.west1
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_east_1a_west_1.id
  auto_accept               = true
  
  tags = {
    Name = "VPC-Peer-East-1A-to-West-1-Accepter"
  }
}

resource "aws_vpc_peering_connection" "peer_east_1b_west_1" {
  provider    = aws.east1
  vpc_id      = aws_vpc.vpc_east_1b.id
  peer_vpc_id = aws_vpc.vpc_west_1.id
  peer_region = "us-west-1"
  
  tags = {
    Name = "VPC-Peer-East-1B-to-West-1"
  }
}

resource "aws_vpc_peering_connection_accepter" "peer_east_1b_west_1_accepter" {
  provider                  = aws.west1
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_east_1b_west_1.id
  auto_accept               = true
  
  tags = {
    Name = "VPC-Peer-East-1B-to-West-1-Accepter"
  }
}

# Add routes for VPC peering
# East 1A to East 1B
resource "aws_route" "east_1a_public_to_east_1b" {
  provider                  = aws.east1
  route_table_id            = aws_route_table.public_rt_east_1a.id
  destination_cidr_block    = aws_vpc.vpc_east_1b.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_east_1a_east_1b.id
}

resource "aws_route" "east_1a_private_to_east_1b" {
  provider                  = aws.east1
  route_table_id            = aws_route_table.private_rt_east_1a.id
  destination_cidr_block    = aws_vpc.vpc_east_1b.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_east_1a_east_1b.id
}

# East 1B to East 1A
resource "aws_route" "east_1b_to_east_1a" {
  provider                  = aws.east1
  route_table_id            = aws_route_table.private_rt_east_1b.id
  destination_cidr_block    = aws_vpc.vpc_east_1a.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_east_1a_east_1b.id
}

# East 1A to West 1
resource "aws_route" "east_1a_public_to_west_1" {
  provider                  = aws.east1
  route_table_id            = aws_route_table.public_rt_east_1a.id
  destination_cidr_block    = aws_vpc.vpc_west_1.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_east_1a_west_1.id
}

resource "aws_route" "east_1a_private_to_west_1" {
  provider                  = aws.east1
  route_table_id            = aws_route_table.private_rt_east_1a.id
  destination_cidr_block    = aws_vpc.vpc_west_1.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_east_1a_west_1.id
}

# East 1B to West 1
resource "aws_route" "east_1b_to_west_1" {
  provider                  = aws.east1
  route_table_id            = aws_route_table.private_rt_east_1b.id
  destination_cidr_block    = aws_vpc.vpc_west_1.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_east_1b_west_1.id
}

# West 1 to East 1A
resource "aws_route" "west_1_to_east_1a" {
  provider                  = aws.west1
  route_table_id            = aws_route_table.private_rt_west_1.id
  destination_cidr_block    = aws_vpc.vpc_east_1a.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_east_1a_west_1.id
}

# West 1 to East 1B
resource "aws_route" "west_1_to_east_1b" {
  provider                  = aws.west1
  route_table_id            = aws_route_table.private_rt_west_1.id
  destination_cidr_block    = aws_vpc.vpc_east_1b.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_east_1b_west_1.id
}

# VPC Endpoints for S3 access
resource "aws_vpc_endpoint" "s3_endpoint_east_1a" {
  provider        = aws.east1
  vpc_id          = aws_vpc.vpc_east_1a.id
  service_name    = "com.amazonaws.us-east-1.s3"
  route_table_ids = [aws_route_table.private_rt_east_1a.id]
  
  tags = {
    Name = "S3-Endpoint-East-1A"
  }
}

resource "aws_vpc_endpoint" "s3_endpoint_east_1b" {
  provider        = aws.east1
  vpc_id          = aws_vpc.vpc_east_1b.id
  service_name    = "com.amazonaws.us-east-1.s3"
  route_table_ids = [aws_route_table.private_rt_east_1b.id]
  
  tags = {
    Name = "S3-Endpoint-East-1B"
  }
}

resource "aws_vpc_endpoint" "s3_endpoint_west_1" {
  provider        = aws.west1
  vpc_id          = aws_vpc.vpc_west_1.id
  service_name    = "com.amazonaws.us-west-1.s3"
  route_table_ids = [aws_route_table.private_rt_west_1.id]
  
  tags = {
    Name = "S3-Endpoint-West-1"
  }
}

# VPC Flow Logs
resource "aws_flow_log" "flow_log_east_1a" {
  provider            = aws.east1
  log_destination     = aws_s3_bucket.flow_logs.arn
  log_destination_type = "s3"
  traffic_type        = "ALL"
  vpc_id              = aws_vpc.vpc_east_1a.id
  
  tags = {
    Name = "Flow-Log-East-1A"
  }
}

resource "aws_flow_log" "flow_log_east_1b" {
  provider            = aws.east1
  log_destination     = aws_s3_bucket.flow_logs.arn
  log_destination_type = "s3"
  traffic_type        = "ALL"
  vpc_id              = aws_vpc.vpc_east_1b.id
  
  tags = {
    Name = "Flow-Log-East-1B"
  }
}

resource "aws_flow_log" "flow_log_west_1" {
  provider            = aws.west1
  log_destination     = aws_s3_bucket.flow_logs.arn
  log_destination_type = "s3"
  traffic_type        = "ALL"
  vpc_id              = aws_vpc.vpc_west_1.id
  
  tags = {
    Name = "Flow-Log-West-1"
  }
}

# Security Groups
resource "aws_security_group" "jumphost_sg" {
  provider    = aws.east1
  name        = "jumphost-sg"
  description = "Security group for jump host"
  vpc_id      = aws_vpc.vpc_east_1a.id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # In production, restrict to your IP address
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "JumpHost-SG"
  }
}

resource "aws_security_group" "private_sg_east_1a" {
  provider    = aws.east1
  name        = "private-sg-east-1a"
  description = "Security group for private instances in East 1A"
  vpc_id      = aws_vpc.vpc_east_1a.id
  
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jumphost_sg.id]
  }
  
  # Allow all traffic from other VPCs for inter-VPC communication
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpc_east_1b.cidr_block, aws_vpc.vpc_west_1.cidr_block]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "Private-SG-East-1A"
  }
}

resource "aws_security_group" "private_sg_east_1b" {
  provider    = aws.east1
  name        = "private-sg-east-1b"
  description = "Security group for private instances in East 1B"
  vpc_id      = aws_vpc.vpc_east_1b.id
  
  # Allow SSH from VPC East 1A (Jump Host)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc_east_1a.cidr_block]
  }
  
  # Allow all traffic from other VPCs for inter-VPC communication
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpc_east_1a.cidr_block, aws_vpc.vpc_west_1.cidr_block]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "Private-SG-East-1B"
  }
}

resource "aws_security_group" "private_sg_west_1" {
  provider    = aws.west1
  name        = "private-sg-west-1"
  description = "Security group for private instances in West 1"
  vpc_id      = aws_vpc.vpc_west_1.id
  
  # Allow SSH from VPC East 1A (Jump Host)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc_east_1a.cidr_block]
  }
  
  # Allow all traffic from other VPCs for inter-VPC communication
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpc_east_1a.cidr_block, aws_vpc.vpc_east_1b.cidr_block]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "Private-SG-West-1"
  }
}

# AWS Key Pair
resource "aws_key_pair" "ssh_key_east" {
  provider   = aws.east1
  key_name   = "ssh-key-east"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDrAvzDirPFMJ5Iw7gB8aBQpJgl+CelZYU7uXJSVgP0eup48C+QksoTNCFpCRHHuDmVHZCUv8Vdu4oe+WuKXuHIt2NSLzuJs+4G/V98w8uPDG8ofWzL4XqB/VUcz4/3f4Sq0w9mL1EnzaNTyx82NIRqJDEVpviJPA5VKdBgEEb7g0Xwa24SZntiEZDgFydaVzvmTIdXDRu628FUktzdrwZOI/4AyGQKNPxq9qaPhZP0NqPadRqvwLYwaH4qxda+Q8zj/VO6OYnHB3jwNW+zAiyHtcmtxl7P7rGizM48Ygx0AhB7gEuEBKu0pYQTFTXTuKmH/p8mX/MC2/o9jsfr+2g3AzdlA6TQ0XHrw8oHFFUMIyiSjX7FqhXsKUL/WF3P3V8CuatSN3S3z9fXtP0Ub3mwnC6usBU2XJ807HY4uZs9m9lt7ksiLe2BJnLQdr0bQdNXOwVUbc7pmzYunVvpL22YOKEhoW7GTOq0Z4hdlwGs7ACPhimkNzcuRFaa1UKGVbnrS1SFHX153+CcPuM4QZvH5ejHLgdZkoO0Rjpoc80c3HaUDhbtu08yThv28SK3WI0syMYBlIX9d8t+ot0Uj4r4yfr68cqA792O7GGzABjoT0U6EetFJiXIwOTxhHpOw4XfHyLmLliUX8I7N/EqGiriLaIW36waTdDpPyF/4BjQlw== vivekair@Viveks-MacBook-Air.local"  # Replace with your public key
  
  tags = {
    Name = "SSH-Key-East"
  }
}

resource "aws_key_pair" "ssh_key_west" {
  provider   = aws.west1
  key_name   = "ssh-key-west"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCeosY3rYqt7xuycgUnXiCBdi590iqC4L3CYiB51LNEnjWCJ13/jYRA3ki49O9DU2ii+5udfxmBOaDlw8mOLULA0cppiW6ZZimvN3zoq2Ycm6gvL+5iYlvG3lc1FGxz8BCbGcnsSj159YzNU0+cLAQz9L+w169gCh1R2nwnHKNUrEygL9fjT5K9vAs3hMlQkMpop2oGS04EuXJeJ0n7kVXFuPT+3QKLdb9vShxyUx7MavKRGjN/UQtIsa2dGKjmFYJyrkO5l+HAu42sM6GHITp7HyCl5CbZuQqBxd0c7wdOXk5N6SQShhfqlBJjOxm+WtnaAF9F+sbMKhA1MS8KuQB/AdXnCYJJsp//ueR1RB2J5vwt6BFBUbpMeDF3jQ5Ply6cInJ6G2oSeeZx9awg+JAq7NGSlSHtFH7in9w1DEPb+1zRh5AqQOaRT6XuB0qGlp3FG6W1PELhgDR4ldGJeLVLH2ELojq8M+1s7b8pB/tWIK5dTSqciEkdF9uwBAVPZHeZNCHUevrRA1DWhJKD4lvDH4tb+nlfpaBoM+vsVqneVDBjWXIJ3aLdjZSLpUjdaupcAJlW9LCPB+SQ0pA3tKQ9Q/rI/mTaP74BLqQXFCexFzQUrE7wI+BNWHFmKLBYQTvIR7Y5E6UaAmKYxtXM6e+XWPCqMP41+QBHX9a7lRXvQQ== vivekair@Viveks-MacBook-Air.local"  # Replace with your public key
  
  tags = {
    Name = "SSH-Key-West"
  }
}

# EC2 Instances
# Jump Host in East 1A (Public Subnet)
resource "aws_instance" "jumphost" {
  provider               = aws.east1
  ami                    = "ami-0953476d60561c955"  # Amazon Linux 2 in us-east-1, update if needed
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.ssh_key_east.key_name
  subnet_id              = aws_subnet.public_east_1a.id
  vpc_security_group_ids = [aws_security_group.jumphost_sg.id]
  associate_public_ip_address = true
  
  tags = {
    Name = "Jump-Host"
  }
}

# Private Instance in East 1A
resource "aws_instance" "private_east_1a" {
  provider               = aws.east1
  ami                    = "ami-0953476d60561c955"  # Amazon Linux 2 in us-east-1, update if needed
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.ssh_key_east.key_name
  subnet_id              = aws_subnet.private_east_1a.id
  vpc_security_group_ids = [aws_security_group.private_sg_east_1a.id]
  
  tags = {
    Name = "Private-EC2-East-1A"
  }
}

# Private Instance in East 1B
resource "aws_instance" "private_east_1b" {
  provider               = aws.east1
  ami                    = "ami-0953476d60561c955"  # Amazon Linux 2 in us-east-1, update if needed
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.ssh_key_east.key_name
  subnet_id              = aws_subnet.private_east_1b.id
  vpc_security_group_ids = [aws_security_group.private_sg_east_1b.id]
  
  tags = {
    Name = "Private-EC2-East-1B"
  }
}

# Private Instance in West 1
resource "aws_instance" "private_west_1" {
  provider               = aws.west1
  ami                    = "ami-07706bb32254a7fe5"  # Amazon Linux 2 in us-west-1, update if needed
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.ssh_key_west.key_name
  subnet_id              = aws_subnet.private_west_1.id
  vpc_security_group_ids = [aws_security_group.private_sg_west_1.id]
  
  tags = {
    Name = "Private-EC2-West-1"
  }
}

