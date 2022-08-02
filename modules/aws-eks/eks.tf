
resource "aws_eks_cluster" "eks-cluster" {

  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  enabled_cluster_log_types = ["api", "audit"]
  version  = "1.20"
  tags     = var.tags

  vpc_config {
    security_group_ids      = ["${aws_security_group.cluster.id}"]
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    subnet_ids              = var.private_subnet_ids #module.aws-vpc.private-subnet-ids

  }
  
  encryption_config {
    provider {
      key_arn = "arn:aws:kms:us-east-2:182560659941:key/0dddfc6d-00b1-49cf-8585-180468302cd5"
    }
    resources = ["secrets"]
  }
  
  kubernetes_network_config {
    service_ipv4_cidr = var.cluster_service_ipv4_cidr
  }


  depends_on = [
    aws_security_group_rule.cluster_egress_internet,
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy1,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController1,
    aws_cloudwatch_log_group.eks-log-group

  ]
}

resource "aws_cloudwatch_log_group" "eks-log-group" {
 
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.log_retention

}

resource "aws_security_group_rule" "cluster_private_access" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = var.cluster_endpoint_private_access_cidrs

  security_group_id = aws_security_group.cluster.id
}



resource "aws_security_group" "cluster" {

  name_prefix = var.cluster_name
  description = "EKS cluster security group."
  vpc_id      = var.vpc_id #module.aws-vpc.vpc-id
  tags = merge(
    var.tags,
    {
      "Name" = "${var.cluster_name}-eks_cluster_sg"
    },
  )
}

resource "aws_security_group_rule" "cluster_egress_internet" {
  description       = "Allow cluster egress access to the Internet."
  protocol          = "-1"
  security_group_id = aws_security_group.cluster.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  type              = "egress"
}


resource "aws_iam_role" "eks_cluster_role" {
  name                  = "${var.cluster_name}-cluster-role"
  description           = "Allow cluster to manage node groups, fargate nodes and cloudwatch logs"
  force_detach_policies = true
  assume_role_policy    = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "eks.amazonaws.com",
          "eks-fargate-pods.amazonaws.com"
          ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy1" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController1" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

#Node Profile
resource "aws_eks_node_group" "eks-node-group" {
  cluster_name    = aws_eks_cluster.eks-cluster.name
  node_group_name = "${var.cluster_name}-${var.environment}-node_group"
  node_role_arn   = aws_iam_role.eks-node-group-role.arn
  subnet_ids      = var.private_subnet_ids
  scaling_config {
    desired_size = var.node_group_desired
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  instance_types = var.eks_node_group_instance_types
}

resource "aws_iam_role" "eks-node-group-role" {
  name = "${var.cluster_name}-node-group_role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-node-group-role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-node-group-role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-node-group-role.name
}


#Fargate profile

data "aws_iam_policy_document" "assume-role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "pod-execustion-role" {
  for_each           = toset(var.namespaces)
  name               = format("%s-fargate-%s", var.cluster_name, each.value)
  assume_role_policy = data.aws_iam_policy_document.assume-role.json
  tags = merge(var.tags,
    { Namespace = each.value },
    { "kubernetes.io/cluster/${var.cluster_name}" = "owned" },
  { "k8s.io/cluster/${var.cluster_name}" = "owned" })
}

resource "aws_iam_role_policy_attachment" "attachment_main" {
  for_each   = toset(var.namespaces)
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.pod-execustion-role[each.value].name
}

resource "aws_eks_fargate_profile" "fargate-profile" {
  for_each               = toset(var.namespaces)
  cluster_name           = var.cluster_name
  fargate_profile_name   = format("%s-fargate-%s", var.cluster_name, each.value)
  pod_execution_role_arn = aws_iam_role.pod-execustion-role[each.value].arn
  subnet_ids             = var.private_subnet_ids

  tags = merge(var.tags,
    { Namespace = each.value },
    { "kubernetes.io/cluster/${var.cluster_name}" = "owned" },
  { "k8s.io/cluster/${var.cluster_name}" = "owned" })
  
  depends_on = [
    aws_eks_cluster.eks-cluster
  ] 
  selector {
    namespace = each.value
  }
}
