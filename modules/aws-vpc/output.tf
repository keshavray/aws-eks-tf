output "vpc_id" {

  value = aws_vpc.ovr-vpc.id

}

output "private_subnets_app_id" {

  value = toset([

    for subnet in aws_subnet.private-subnet-app : subnet.id
  ])
}

output "private_db_subnet_ids" {

  value = toset([

    for subnet in aws_subnet.private-subnet-db : subnet.id

  ])

}

output "public_subnet_ids" {

  value = toset([

    for subnet in aws_subnet.public-subnet : subnet.id

  ])


}

output "vpc-cidr" {
  value = var.cidr
}