# ✅ PROVIDER

resource "random_id" "bucket_id" {
  byte_length = 4
}


module "s3" {
  source = "../modules/s3"
  bucket_name = "lambda-artifact-${random_id.bucket_id.hex}"
  codepipeline_role_arn = module.iam.codepipeline_role_arn
  codebuild_role_arn    = module.iam.codebuild_role_arn
}

module "iam" {
  source = "../modules/iam"
  artifact_bucket_arn = module.s3.artifact_bucket_arn
}

# variable "github_owner" {}
# variable "github_repo" {}
# variable "branch_name" {
#   default = "main"
# }

# # ✅ GITHUB TOKEN
# variable "codestar_connection_arn" {}

# ✅ LAMBDA FUNCTION
resource "aws_lambda_function" "sum_function" {
  function_name = "sum_function"
  role          = module.iam.lambda_execution_role_arn
  handler       = "lambda_function.handler"
  runtime       = "python3.12"
  filename      = "build/lambda.zip"
  source_code_hash = filebase64sha256("build/lambda.zip")
  timeout       = 10

  lifecycle {
    ignore_changes = [source_code_hash, filename]
  }
}

# ✅ CODEBUILD PROJECTS

resource "aws_codebuild_project" "terraform_build" {
  name         = "terraform-build"
  service_role = module.iam.codebuild_service_role_arn

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
  service_role = module.iam.codebuild_service_role_arn

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


resource "aws_iam_role_policy" "codepipeline_codebuild" {
  name = "codepipeline_codebuild"
  role = module.iam.codepipeline_service_role_id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ],
        Resource = [
          aws_codebuild_project.lambda_build.arn,
          aws_codebuild_project.terraform_build.arn
        ]
      }
    ]
  })
}



# ✅ CODEPIPELINE
resource "aws_codepipeline" "pipeline_1" {
  name     = "lambda-pipeline"
  role_arn = module.iam.codepipeline_service_role_arn

  artifact_store {
    location = "lambda-artifact-${random_id.bucket_id.hex}"
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




resource "aws_codepipeline" "pipeline_2" {
  name     = "infra-pipeline"
  role_arn = module.iam.codepipeline_service_role_arn

  artifact_store {
    location = "lambda-artifact-${random_id.bucket_id.hex}"
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

}
