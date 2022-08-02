data "aws_vpc" "ovr-management-vpc" {
  tags = {
    Name = "management-vpc"
  }
}

locals {
  eks_public_subnet_tags  = var.cluster_name != "" ? { "kubernetes.io/cluster/${var.cluster_name}" : "shared", "kubernetes.io/role/elb" : "1" } : {}
  eks_private_subnet_tags = var.cluster_name != "" ? { "kubernetes.io/cluster/${var.cluster_name}" : "shared", "kubernetes.io/role/internal-elb" : "1" } : {}
}


resource "aws_vpc" "ovr-vpc" {
  cidr_block           = var.cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {

    Name        = "${var.name}-vpc"
    environment = var.environment
  }
}

resource "aws_internet_gateway" "ovr-igw" {
  vpc_id     = aws_vpc.ovr-vpc.id
  depends_on = [aws_vpc.ovr-vpc]

  tags = {
    Name        = "${var.name}-igw"
    environment = var.environment
  }
}

resource "aws_subnet" "public-subnet" {

  for_each          = var.public_subnets
  vpc_id            = aws_vpc.ovr-vpc.id
  cidr_block        = each.value
  availability_zone = each.key

  map_public_ip_on_launch = true



  tags = merge(
   
    local.eks_public_subnet_tags,
    {
    Name        = "${var.name}-${each.key}-public"
    environment = var.environment
  })

  depends_on = [aws_vpc.ovr-vpc]
}
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.ovr-vpc.id
  #propagating_vgws = [var.public_propagating_vgws]

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.ovr-igw.id
  }
 
  tags = {
    Name        = "${var.name}-public"
    environment = "${var.environment}"
  }

  lifecycle  {
  ignore_changes = [route]
  }

  depends_on = [aws_vpc.ovr-vpc, aws_internet_gateway.ovr-igw,aws_vpc_peering_connection.ovr-management-peering]

  
}

resource "aws_route_table_association" "public" {

  for_each       = var.public_subnets
  subnet_id      = aws_subnet.public-subnet[each.key].id
  route_table_id = aws_route_table.public-route-table.id

}

resource "aws_route" "peering-public" {

      route_table_id    = aws_route_table.public-route-table.id
      destination_cidr_block = data.aws_vpc.ovr-management-vpc.cidr_block
      vpc_peering_connection_id  = aws_vpc_peering_connection.ovr-management-peering.id
      depends_on = [aws_vpc_peering_connection.ovr-management-peering]
}

resource "aws_subnet" "private-subnet-app" {

  for_each          = var.private_subnets_app
  vpc_id            = aws_vpc.ovr-vpc.id
  cidr_block        = each.value
  availability_zone = each.key

  map_public_ip_on_launch = true


  tags = merge(
   
    local.eks_private_subnet_tags,
    {
    Name        = "${var.name}-${each.key}-app"
    environment = var.environment
  })

  depends_on = [aws_vpc.ovr-vpc]
}

resource "aws_route_table" "private-route-table-app" {

  for_each = var.private_subnets_app
  vpc_id   = aws_vpc.ovr-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name        = "${var.name}-${each.key}-private-app"
    environment = "${var.environment}"
  }
  
  lifecycle {
  ignore_changes = [route]
  }

  depends_on = [aws_vpc.ovr-vpc, aws_nat_gateway.nat]
  
}

resource "aws_route_table_association" "private-app" {

  for_each  = var.private_subnets_app
  subnet_id = aws_subnet.private-subnet-app[each.key].id
  route_table_id = aws_route_table.private-route-table-app[each.key].id
  depends_on = [aws_subnet.private-subnet-app, aws_route_table.private-route-table-app]
}

resource "aws_route" "peering-private-app" {
      
      for_each  = var.private_subnets_app
      route_table_id    = aws_route_table.private-route-table-app[each.key].id
      destination_cidr_block = data.aws_vpc.ovr-management-vpc.cidr_block
      vpc_peering_connection_id  = aws_vpc_peering_connection.ovr-management-peering.id
      depends_on = [aws_vpc_peering_connection.ovr-management-peering]

}

resource "aws_subnet" "private-subnet-db" {

  for_each          = var.private_subnets_db
  vpc_id            = aws_vpc.ovr-vpc.id
  cidr_block        = each.value
  availability_zone = each.key

  map_public_ip_on_launch = true


  tags = {
    Name        = "${var.name}-${each.key}-private-db"
    environment = "${var.environment}"
  }

  depends_on = [aws_vpc.ovr-vpc]
}

resource "aws_route_table" "private-route-table-db" {

  for_each = var.private_subnets_db
  vpc_id   = aws_vpc.ovr-vpc.id
  #propagating_vgws = ["${var.private_propagating_vgws}"]

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id 
  }

  tags = {
    Name        = "${var.name}-${each.key}-private-db"
    environment = "${var.environment}"
  }
  
  lifecycle {
  ignore_changes = [route]
  }

  depends_on = [aws_vpc.ovr-vpc, aws_nat_gateway.nat]
  
}

resource "aws_route_table_association" "private-db" {

  for_each  = var.private_subnets_db
  subnet_id = aws_subnet.private-subnet-db[each.key].id

  route_table_id = aws_route_table.private-route-table-db[each.key].id

  depends_on = [aws_subnet.private-subnet-db, aws_route_table.private-route-table-db]
}

resource "aws_route" "peering-private-db" {
      
      for_each  = var.private_subnets_db
      route_table_id    = aws_route_table.private-route-table-db[each.key].id
      destination_cidr_block = data.aws_vpc.ovr-management-vpc.cidr_block
      vpc_peering_connection_id  = aws_vpc_peering_connection.ovr-management-peering.id
      depends_on = [aws_vpc_peering_connection.ovr-management-peering]

}

resource "aws_eip" "aws-eip" {

  #for_each = var.public_subnets
  vpc      = true
}

resource "aws_nat_gateway" "nat" {
  
  #for_each      = var.public_subnets
  #allocation_id = aws_eip.aws-eip[each.key].idsample of tfc and it has created resources in TFC
  allocation_id  = aws_eip.aws-eip.id 
  #subnet_id     = aws_subnet.public-subnet[each.key].id
  subnet_id      = element(tolist([for subnet in aws_subnet.public-subnet : subnet.id]),0) 
  depends_on     = [aws_subnet.public-subnet]
}

resource "aws_vpc_peering_connection" "ovr-management-peering" {
  peer_vpc_id   = data.aws_vpc.ovr-management-vpc.id
  vpc_id        = aws_vpc.ovr-vpc.id
  auto_accept   = true

  tags = {
    Name = var.peering-name
  }
  depends_on = [aws_vpc.ovr-vpc]
}

resource "aws_route" "ovr-vpc-rt" {

      route_table_id    = aws_vpc.ovr-vpc.default_route_table_id
      destination_cidr_block = data.aws_vpc.ovr-management-vpc.cidr_block
      vpc_peering_connection_id  = aws_vpc_peering_connection.ovr-management-peering.id
      depends_on = [aws_vpc_peering_connection.ovr-management-peering]

}
resource "aws_flow_log" "flow_log" {
  iam_role_arn    = aws_iam_role.vpc-log-group-role.arn
  log_destination = aws_cloudwatch_log_group.vpc_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.ovr-vpc.id
}

resource "aws_cloudwatch_log_group" "vpc_log_group" {
  name              = "/aws/vpc/ovr-prod-vpc"
  retention_in_days = 7
}

resource "aws_iam_role" "vpc-log-group-role" {
  name = "vpc-log-group-role-prod"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "example" {
  name = "vpc-log-group-policy-prod"
  role = aws_iam_role.vpc-log-group-role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
