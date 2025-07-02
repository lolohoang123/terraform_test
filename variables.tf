variable "github_owner" {
  description = "GitHub username or org"
}

variable "github_repo" {
  description = "GitHub repository name"
}

variable "branch_name" {
  description = "Git branch"
  default     = "main"
}

variable "codestar_connection_arn" {
  description = "ARN of the CodeStar Connection to GitHub"
}
