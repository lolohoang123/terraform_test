variable "github_owner" {
  description = "GitHub username or org"
  default = "lolohoang123"
}

variable "github_repo" {
  description = "GitHub repository name"
  default= "terraform_test"
}

variable "branch_name" {
  description = "Git branch"
  default     = "main"
}

variable "codestar_connection_arn" {
  description = "ARN of the CodeStar Connection to GitHub"
  default     = "arn:aws:codeconnections:ap-northeast-1:270573552412:connection/b834ac08-fcc4-4688-aa92-96394908d63f"
}
