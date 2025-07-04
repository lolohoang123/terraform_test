resource "aws_s3_bucket" "artifact_bucket" {
  bucket = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.artifact_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "artifact_policy" {
  bucket = aws_s3_bucket.artifact_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        AWS =[var.codepipeline_role_arn,
            var.codebuild_role_arn]  
      },
      Action = [
        "s3:GetObject",
        "s3:PutObject"
      ],
      Resource = [
        "${aws_s3_bucket.artifact_bucket.arn}/*"
      ]
    }]
  })
}
