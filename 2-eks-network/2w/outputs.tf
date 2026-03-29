output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${var.TargetRegion} update-kubeconfig --name ${var.ClusterBaseName}"
}

output "aws_load_balancer_controller_policy_arn" {
  description = "ARN of the IAM policy for the AWS Load Balancer Controller"
  value       = aws_iam_policy.aws_load_balancer_controller.arn
}

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the IRSA IAM role for the AWS Load Balancer Controller"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

output "aws_load_balancer_controller_role_name" {
  description = "Name of the IRSA IAM role for the AWS Load Balancer Controller"
  value       = aws_iam_role.aws_load_balancer_controller.name
}
