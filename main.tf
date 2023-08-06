resource "aws_s3_bucket" "resumeWebsiteBucket" {
    bucket = var.bucketName
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.resumeWebsiteBucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.resumeWebsiteBucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example,
  ]

  bucket = aws_s3_bucket.resumeWebsiteBucket.id
  acl    = "public-read"
}

resource "aws_s3_object" "index" {
    bucket = aws_s3_bucket.resumeWebsiteBucket.id
    key    = "index.html"
    source = "index.html"
    acl    = "public-read"
    content_type = "text/html"

    depends_on = [ aws_s3_bucket_acl.example ]
}

resource "aws_s3_object" "index-css" {
    bucket = aws_s3_bucket.resumeWebsiteBucket.id
    key    = "index.css"
    source = "index.css"
    acl    = "public-read"
    content_type = "text/css"

    depends_on = [ aws_s3_bucket_acl.example ]
}

resource "aws_s3_object" "error" {
    bucket = aws_s3_bucket.resumeWebsiteBucket.id
    key    = "error.html"
    source = "error.html"
    acl    = "public-read"
    content_type = "text/html"

    depends_on = [ aws_s3_bucket_acl.example ]
}

resource "aws_s3_object" "eva-error" {
    bucket = aws_s3_bucket.resumeWebsiteBucket.id
    key    = "eva.jpg"
    source = "eva.jpg"
    acl    = "public-read"
    content_type = "image/jpeg"

    depends_on = [ aws_s3_bucket_acl.example ]
}

resource "aws_s3_object" "nerv" {
    bucket = aws_s3_bucket.resumeWebsiteBucket.id
    key    = "eva.png"
    source = "eva.png"
    acl    = "public-read"
    content_type = "image/png"

    depends_on = [ aws_s3_bucket_acl.example ]
}

resource "aws_s3_bucket_website_configuration" "website" {
    bucket = aws_s3_bucket.resumeWebsiteBucket.id
    index_document {
        suffix = "index.html"
    }

    error_document {
        key = "error.html"
    }

    depends_on = [ aws_s3_bucket_acl.example ]
}