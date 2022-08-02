resource "aws_cloudfront_origin_access_identity" "access_identity" {
  comment = "aws_cloudfront_origin_access_identity"
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = var.patient_web_domain_name
  acl = "public-read"
  website {
    index_document = "index.html"
    error_document = "index.html"
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }   
    
}

# .deploy/terraform/static-site/iam.tf
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}


locals {
  s3_origin_id = "origin-${var.patient_web_domain_name}"
}


#cloudfront 

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
          s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.access_identity.cloudfront_access_identity_path
    }
    domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"


  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

#   # Cache behavior with precedence 0
#   ordered_cache_behavior {
#     path_pattern     = "/content/immutable/*"
#     allowed_methods  = ["GET", "HEAD", "OPTIONS"]
#     cached_methods   = ["GET", "HEAD", "OPTIONS"]
#     target_origin_id = local.s3_origin_id

#     forwarded_values {
#       query_string = false
#       headers      = ["Origin"]

#       cookies {
#         forward = "none"
#       }
#     }

#     min_ttl                = 0
#     default_ttl            = 86400
#     max_ttl                = 31536000
#     compress               = true
#     viewer_protocol_policy = "redirect-to-https"
#   }

#   # Cache behavior with precedence 1
#   ordered_cache_behavior {
#     path_pattern     = "/content/*"
#     allowed_methods  = ["GET", "HEAD", "OPTIONS"]
#     cached_methods   = ["GET", "HEAD"]
#     target_origin_id = local.s3_origin_id

#     forwarded_values {
#       query_string = false

#       cookies {
#         forward = "none"
#       }
#     }

#     min_ttl                = 0
#     default_ttl            = 3600
#     max_ttl                = 86400
#     compress               = true
#     viewer_protocol_policy = "redirect-to-https"
#   }

  price_class = "PriceClass_100"

   restrictions {
    geo_restriction {
      restriction_type = "none"
      locations = []

    }
  }

  tags = {
    environment = var.environment 
  }

  aliases = [var.patient_web_alias]

  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-east-1:182560659941:certificate/20090156-9f7e-4d5f-886a-83a66564836b"
    ssl_support_method  = "sni-only"
    minimum_protocol_version  = "TLSv1.2_2021"
  }

  custom_error_response {
      error_code = "403"
      response_code = "200"
      response_page_path = "/index.html"
      error_caching_min_ttl = "10"
  }

  custom_error_response {
      error_code = "404"
      response_code = "200"
      response_page_path = "/index.html"
      error_caching_min_ttl = "0"
  }
}
