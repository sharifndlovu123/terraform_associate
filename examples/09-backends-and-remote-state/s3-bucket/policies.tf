# Sample bucket policies as data.aws_iam_policy_document.
# The first three are attached in main.tf. The rest are alternatives: add one
# to source_policy_documents to use it. 111122223333 is a fake account ID.

# 1. Deny any request not made over HTTPS
data "aws_iam_policy_document" "https_only" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.demo.arn, "${aws_s3_bucket.demo.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# 2. Deny uploads that do not ask for server-side encryption
data "aws_iam_policy_document" "deny_unencrypted_uploads" {
  statement {
    sid       = "DenyUnencryptedUploads"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.demo.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["AES256"]
    }
  }
}

# 3. Read-only access for one IAM role
data "aws_iam_policy_document" "read_only_role" {
  statement {
    sid       = "ReadOnlyForAppRole"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [aws_s3_bucket.demo.arn, "${aws_s3_bucket.demo.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::111122223333:role/app-reader"]
    }
  }
}

# 4. Alternative: only allow requests from an office IP range
data "aws_iam_policy_document" "office_ip_only" {
  statement {
    sid       = "DenyOutsideOffice"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.demo.arn, "${aws_s3_bucket.demo.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "NotIpAddress"
      variable = "aws:SourceIp"
      values   = ["203.0.113.0/24"] # documentation range
    }
  }
}

# 5. Alternative: another AWS account may upload, only under one prefix
data "aws_iam_policy_document" "cross_account_upload" {
  statement {
    sid       = "PartnerUploads"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.demo.arn}/incoming/*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::444455556666:root"]
    }
  }
}

# 6. Alternative: write the JSON yourself with jsonencode (same result, no data source)
locals {
  cloudfront_read_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontRead"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.demo.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = "arn:aws:cloudfront::111122223333:distribution/EXAMPLE"
        }
      }
    }]
  })
}
