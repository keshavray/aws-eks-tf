resource "aws_iam_role_policy" "s3_full_access_policy" {
name = "${var.redshift_cluster_name}_policy"
role = "${aws_iam_role.redshift_role.id}"
policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "redshift_role" {
name = "${var.redshift_cluster_name}_role"
assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "redshift.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_redshift_subnet_group" "rs_subnet_group" {
  name       = "${var.redshift_cluster_name}-subnet-group"
  subnet_ids = var.private_subnets_db
  tags = {
    environment = var.redshift_env
  }
}

resource "aws_security_group" "redshit-sg" {
  name   = "${var.redshift_cluster_name}-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.redshift_cluster_name}-subnet-group"
  }
}

resource "aws_eip" "rs-cluster-eip" {
  vpc = true
}

resource "aws_redshift_cluster" "redshift_cluster" {
  cluster_identifier        = var.redshift_cluster_name
  database_name             = var.redshift_db_name
  master_username           = var.redshift_username
  master_password           = var.redshift_password
  node_type                 = var.redshift_node_type
  cluster_type              = var.redshift_cluster_type
  number_of_nodes           = var.number_of_nodes
  vpc_security_group_ids    = [aws_security_group.redshit-sg.id]
  cluster_subnet_group_name = aws_redshift_subnet_group.rs_subnet_group.id
  elastic_ip                = aws_eip.rs-cluster-eip.public_ip
  iam_roles                 = [aws_iam_role.redshift_role.arn]
  skip_final_snapshot       = true
  depends_on                = [aws_eip.rs-cluster-eip, aws_redshift_subnet_group.rs_subnet_group, aws_security_group.redshit-sg, aws_iam_role.redshift_role]
}