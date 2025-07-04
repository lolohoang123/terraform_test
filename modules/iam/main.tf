
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "codebuild_service_role" {
  name = "codebuild_service_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "codebuild_policy"
  role = aws_iam_role.codebuild_service_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:*",
          "s3:*",
          "lambda:UpdateFunctionCode",
          "iam:PassRole",
          "iam:GetRole",
          "iam:ListRolePolicies",
          "iam:ListRoles",
          "iam:GetPolicy",
          "iam:GetPolicyVersion"
        ],
        Resource = "*"
      }
    ]
  })
}




resource "aws_iam_role" "codepipeline_service_role" {
  name = "codepipeline_service_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codepipeline.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline_codestar_policy" {
  name = "codepipeline_codestar_policy"
  role = aws_iam_role.codepipeline_service_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "codestar-connections:UseConnection"
        ],
        Resource = var.codestar_connection_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline_s3_policy" {
  name = "codepipeline_s3_policy"
  role = aws_iam_role.codepipeline_service_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
        Resource = var.artifact_bucket_arn
      }
    ]
  })
}




output "lambda_execution_role_arn" {
  value = aws_iam_role.lambda_execution_role.arn
}

output "codebuild_service_role_arn" {
  value = aws_iam_role.codebuild_service_role.arn
}

output "codepipeline_service_role_arn" {
  value = aws_iam_role.codepipeline_service_role.arn
}

output "codepipeline_service_role_id" {
  value = aws_iam_role.codepipeline_service_role.id
}





