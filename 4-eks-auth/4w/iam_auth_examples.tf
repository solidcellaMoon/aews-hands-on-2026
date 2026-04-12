########################
# Pod Identity vs IRSA #
########################

locals {
  pod_identity_namespace       = "default"
  pod_identity_service_account = "pod-identity-demo"

  irsa_namespace       = "default"
  irsa_service_account = "irsa-demo"
}

# 두 방식 모두 동일한 권한 정책을 재사용할 수 있다.
# 차이는 "누가 role 을 assume 하는가"를 정의하는 trust policy 와
# EKS 와 서비스어카운트를 연결하는 방법에 있다.
resource "aws_iam_policy" "workload_example_policy" {
  name        = "${var.ClusterBaseName}WorkloadExamplePolicy"
  description = "Shared example policy used by both EKS Pod Identity and IRSA examples"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListBuckets"
        Effect   = "Allow"
        Action   = ["s3:ListAllMyBuckets"]
        Resource = "*"
      }
    ]
  })
}

################
# Pod Identity #
################

# Pod Identity 는 OIDC 공급자 대신 EKS Pod Identity 서비스 주체를 신뢰한다.
data "aws_iam_policy_document" "pod_identity_assume_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "pod_identity_example" {
  name               = "${var.ClusterBaseName}-pod-identity-demo"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role.json

  tags = {
    Name        = "${var.ClusterBaseName}-pod-identity-demo"
    AuthType    = "pod-identity"
    Environment = "cloudneta-lab"
    Terraform   = "true"
  }
}

resource "aws_iam_role_policy_attachment" "pod_identity_example" {
  role       = aws_iam_role.pod_identity_example.name
  policy_arn = aws_iam_policy.workload_example_policy.arn
}

# Pod Identity 는 IAM role 과 Kubernetes service account 연결을
# aws_eks_pod_identity_association 리소스로 정의한다.
resource "aws_eks_pod_identity_association" "pod_identity_example" {
  cluster_name    = module.eks.cluster_name
  namespace       = local.pod_identity_namespace
  service_account = local.pod_identity_service_account
  role_arn        = aws_iam_role.pod_identity_example.arn
}

# pod_identity_association는 wildcard 사용 가능할까? # 결과: X
# resource "aws_eks_pod_identity_association" "pod_identity_example_2" {
#   cluster_name    = module.eks.cluster_name
#   namespace       = "*"
#   service_account = "pod*"
#   role_arn        = aws_iam_role.pod_identity_example.arn
# }

# IRSA용 role 도 pod identity association 가능할까?
resource "aws_eks_pod_identity_association" "pod_identity_example_3" {
  cluster_name    = module.eks.cluster_name
  namespace       = local.pod_identity_namespace
  service_account = local.irsa_service_account # IRSA 서비스어카운트로 매핑.
  #role_arn        = aws_iam_role.irsa_example.arn # IRSA role 을 pod identity association 해보자 # 그대로 사용하는건 실패
  role_arn        = aws_iam_role.pod_identity_example.arn # 이건 애초에 Pod Idnentity role 이므로 association 가능.
}


########
# IRSA #
########

# IRSA 는 클러스터별 OIDC 공급자와 서비스어카운트 subject 조건을 trust policy 에 넣어야 한다.
data "aws_iam_policy_document" "irsa_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:${local.irsa_namespace}:${local.irsa_service_account}"]
    }
  }
}

resource "aws_iam_role" "irsa_example" {
  name               = "${var.ClusterBaseName}-irsa-demo"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume_role.json

  tags = {
    Name        = "${var.ClusterBaseName}-irsa-demo"
    AuthType    = "irsa"
    Environment = "cloudneta-lab"
    Terraform   = "true"
  }
}

resource "aws_iam_role_policy_attachment" "irsa_example" {
  role       = aws_iam_role.irsa_example.name
  policy_arn = aws_iam_policy.workload_example_policy.arn
}
