# TODO: update variable and resource names to be consistent style. Snake case is best practice stick to it.  This is what you get for trying to learn multiple languages...
resource "aws_s3_bucket" "resumeWebsiteBucket" {
  bucket = var.bucketName # "your-bucket-name" 
}

# TODO: Ditch the example names.
resource "aws_s3_bucket_ownership_controls" "example" { # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls
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
  bucket       = aws_s3_bucket.resumeWebsiteBucket.id
  key          = "index.html"
  source       = "index.html"
  acl          = "public-read"
  etag         = filemd5("index.html") # Used to force a redeploy of the file if it changes (https://www.terraform.io/docs/language/functions/filemd5.html)
  content_type = "text/html"

  depends_on = [aws_s3_bucket_acl.example]
}

resource "aws_s3_object" "index-css" {
  bucket       = aws_s3_bucket.resumeWebsiteBucket.id
  key          = "index.css"
  source       = "index.css"
  acl          = "public-read"
  etag         = filemd5("index.css")
  content_type = "text/css"

  depends_on = [aws_s3_bucket_acl.example]
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.resumeWebsiteBucket.id
  key          = "error.html"
  source       = "error.html"
  acl          = "public-read"
  etag         = filemd5("error.html")
  content_type = "text/html"

  depends_on = [aws_s3_bucket_acl.example]
}

resource "aws_s3_object" "eva-error" {
  bucket       = aws_s3_bucket.resumeWebsiteBucket.id
  key          = "eva.jpg"
  source       = "eva.jpg"
  acl          = "public-read"
  content_type = "image/jpeg"

  depends_on = [aws_s3_bucket_acl.example]
}

resource "aws_s3_object" "nerv" {
  bucket       = aws_s3_bucket.resumeWebsiteBucket.id
  key          = "eva.png"
  source       = "eva.png"
  acl          = "public-read"
  content_type = "image/png"

  depends_on = [aws_s3_bucket_acl.example]
}

resource "aws_s3_bucket_website_configuration" "website" { # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website
  bucket = aws_s3_bucket.resumeWebsiteBucket.id
  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  depends_on = [aws_s3_bucket_acl.example]
}

resource "aws_route53_zone" "primary" { # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone
  name = var.domain_name
}

resource "aws_acm_certificate" "cert" { # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate
  domain_name       = var.domain_name
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  count   = 2 # TODO: change to for_each probably.
  zone_id = aws_route53_zone.primary.zone_id

  name    = tolist(aws_acm_certificate.cert.domain_validation_options)[count.index].resource_record_name
  type    = tolist(aws_acm_certificate.cert.domain_validation_options)[count.index].resource_record_type
  records = [tolist(aws_acm_certificate.cert.domain_validation_options)[count.index].resource_record_value]
  ttl     = "300"
}

resource "aws_route53_record" "root_domain_alias" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_domain_alias" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}


resource "aws_acm_certificate_validation" "cert" { # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = aws_route53_record.cert_validation[*].fqdn
}

resource "aws_cloudfront_distribution" "s3_distribution" { # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution

  aliases     = [var.domain_name, "www.${var.domain_name}"]
  price_class = "PriceClass_100"

  origin {
    connection_attempts = 3
    connection_timeout  = 10
    domain_name         = "www.${var.domain_name}.s3-website-us-east-1.amazonaws.com"
    origin_id           = "www.${var.domain_name}.s3-website-us-east-1.amazonaws.com"
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "http-only"
      origin_read_timeout      = 30
      origin_ssl_protocols     = ["TLSv1.2"]

    }
  }

  enabled         = true
  is_ipv6_enabled = true

  default_root_object = "index.html"

  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 403
    response_code         = 403
    response_page_path    = "/error.html"
  }

  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 404
    response_code         = 404
    response_page_path    = "/error.html"
  }

  default_cache_behavior { # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution#default_cache_behavior
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "www.${var.domain_name}.s3-website-us-east-1.amazonaws.com"
    compress               = true
    default_ttl            = 3600
    max_ttl                = 86400
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }
  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.cert.arn
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}
