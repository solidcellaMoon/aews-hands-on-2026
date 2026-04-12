output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${var.TargetRegion} update-kubeconfig --name ${var.ClusterBaseName}"
}

output "workload_example_policy_arn" {
  description = "Shared IAM policy ARN attached to both the Pod Identity and IRSA example roles"
  value       = aws_iam_policy.workload_example_policy.arn
}

output "pod_identity_example_role_arn" {
  description = "IAM role ARN for the EKS Pod Identity example"
  value       = aws_iam_role.pod_identity_example.arn
}

output "pod_identity_example_association" {
  description = "Pod Identity association created between the EKS cluster, service account, and IAM role"
  value = {
    cluster_name    = aws_eks_pod_identity_association.pod_identity_example.cluster_name
    namespace       = aws_eks_pod_identity_association.pod_identity_example.namespace
    service_account = aws_eks_pod_identity_association.pod_identity_example.service_account
    role_arn        = aws_eks_pod_identity_association.pod_identity_example.role_arn
  }
}

output "irsa_example_role_arn" {
  description = "IAM role ARN for the IRSA example"
  value       = aws_iam_role.irsa_example.arn
}

output "irsa_service_account_annotation" {
  description = "Annotation that must be added to the IRSA service account"
  value = {
    namespace        = local.irsa_namespace
    service_account  = local.irsa_service_account
    annotation_key   = "eks.amazonaws.com/role-arn"
    annotation_value = aws_iam_role.irsa_example.arn
  }
}
