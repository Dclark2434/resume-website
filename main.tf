resource "aws_s3_bucket" "resumeWebsiteBucket" {
    bucket = var.bucketName # "your-bucket-name"
}

resource "aws_s3_bucket_ownership_controls" "example" {  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls
  bucket = aws_s3_bucket.resumeWebsiteBucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "example" { # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
  bucket = aws_s3_bucket.resumeWebsiteBucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "example" { # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl
  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example,
  ]

  bucket = aws_s3_bucket.resumeWebsiteBucket.id
  acl    = "public-read"
}

resource "aws_s3_object" "index" { # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object
    bucket = aws_s3_bucket.resumeWebsiteBucket.id
    key    = "index.html"
    source = "index.html"
    acl    = "public-read"
    etag = filemd5("index.html") # Used to force a redeploy of the file if it changes (https://www.terraform.io/docs/language/functions/filemd5.html)
    content_type = "text/html"

    depends_on = [ aws_s3_bucket_acl.example ]
}

resource "aws_s3_object" "index-css" { 
    bucket = aws_s3_bucket.resumeWebsiteBucket.id
    key    = "index.css"
    source = "index.css"
    acl    = "public-read"
    etag = filemd5("index.css")
    content_type = "text/css"

    depends_on = [ aws_s3_bucket_acl.example ]
}

resource "aws_s3_object" "error" {
    bucket = aws_s3_bucket.resumeWebsiteBucket.id
    key    = "error.html"
    source = "error.html"
    acl    = "public-read"
    etag = filemd5("error.html")
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

resource "aws_s3_bucket_website_configuration" "website" { # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website
    bucket = aws_s3_bucket.resumeWebsiteBucket.id
    index_document {
        suffix = "index.html"
    }

    error_document {
        key = "error.html"
    }

    depends_on = [ aws_s3_bucket_acl.example ]
}

resource "aws_route53_zone" "primary" { # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone
  name = var.domain_name
}

resource "aws_acm_certificate" "cert" { # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" { # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record
  zone_id = aws_route53_zone.primary.zone_id
  name    = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_type
  records = [tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_value]
  ttl     = "60"
}

resource "aws_acm_certificate_validation" "cert" { # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}