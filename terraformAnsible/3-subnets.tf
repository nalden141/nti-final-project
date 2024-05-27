
resource "aws_subnet" "publicA" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    "Name"                       = "public-us-east-1a"
    "kubernetes.io/role/elb"     = "1"
    "kubernetes.io/cluster/demo" = "owned"
    "kubernetes.io/cluster/eks" = "shared"
  }
}

resource "aws_subnet" "publicB" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "110.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    "Name"                       = "public-us-east-1b"
    "kubernetes.io/role/elb"     = "1"
    "kubernetes.io/cluster/demo" = "owned"
    "kubernetes.io/cluster/eks" = "shared"
  }
}