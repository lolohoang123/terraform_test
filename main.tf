# ✅ PROVIDER
provider "aws" {
  region = "ap-southeast-1"
}

# variable "github_owner" {}
# variable "github_repo" {}
# variable "branch_name" {
#   default = "main"
# }

# # ✅ GITHUB TOKEN
# variable "codestar_connection_arn" {}

# ✅ RANDOM S3 BUCKET ID
resource "random_id" "bucket_id" {
  byte_length = 4
}

# ✅ ARTIFACT BUCKET
resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "lambda-artifact-${random_id.bucket_id.hex}"
  force_destroy = true
}

# ✅ LAMBDA ROLE
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ✅ LAMBDA FUNCTION
resource "aws_lambda_function" "sum_function" {
  function_name = "sum_function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.handler"
  runtime       = "python3.12"
  filename      = "build/lambda.zip"
  source_code_hash = filebase64sha256("build/lambda.zip")
  timeout       = 10

  lifecycle {
    ignore_changes = [source_code_hash, filename]
  }
}

# ✅ CODEBUILD ROLE
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild_service_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "codebuild.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "codebuild_policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:*",
          "s3:*",
          "lambda:UpdateFunctionCode",
          "iam:PassRole"
        ],
        Resource = "*"
      }
    ]
  })
}

# ✅ CODEBUILD PROJECTS

resource "aws_codebuild_project" "terraform_build" {
  name         = "terraform-build"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-terraform.yml"
  }
}

resource "aws_codebuild_project" "lambda_build" {
  name         = "lambda-build"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }
}

# ✅ CODEPIPELINE ROLE
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline_service_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "codepipeline.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "codebuild:*",
        "s3:*",
        "iam:PassRole",
        "kms:Decrypt",
        "codestar-connections:UseConnection"
      ],
      Resource = "*"
    }]
  })
}

# ✅ CODEPIPELINE
resource "aws_codepipeline" "pipeline" {
  name     = "lambda-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifact_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo}"
        BranchName       = var.branch_name
      }
    }
  }

  stage {
    name = "TerraformBuild"

    action {
      name             = "Terraform"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["terraform_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.terraform_build.name
      }
    }
  }

  stage {
    name = "LambdaBuild"

    action {
      name             = "Lambda"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.lambda_build.name
      }
    }
  }
}
