resource "aws_s3_bucket" "sina-bucket" {
  bucket = "pl-sina-bucket"
  tags = {
    Name        = "Sina bucket"
  }
}

resource "aws_s3_bucket_acl" "sina-bucket-acl" {
  bucket = aws_s3_bucket.sina-bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "read_bucket" {
  bucket = aws_s3_bucket.sina-bucket.id
  policy = data.aws_iam_policy_document.read_policy.json
}

data "aws_iam_policy_document" "read_policy" {
  statement {
    principals {
      type = "*"
      identifiers = ["*"]
    }

    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]
    

    resources = [
      "arn:aws:s3:::pl-sina-bucket/*"
    ]
  }
}