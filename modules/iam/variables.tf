variable "codestar_connection_arn" {
  description = "ARN of the CodeStar Connection to GitHub"
  default     = "arn:aws:codeconnections:ap-northeast-1:270573552412:connection/b834ac08-fcc4-4688-aa92-96394908d63f"
}

variable "artifact_bucket_arn" {
  type = string
  description = "ARN of artifact bucket"
}
