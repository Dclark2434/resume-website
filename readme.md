# Terraform AWS S3 Website Deployment

This repository contains Terraform code to deploy a static website on AWS S3, using CloudFront for CDN distribution and Route53 for domain management. It sets up necessary permissions, caching, SSL certificate handling, and more.

I have done my best to leave out anything specific pertaining to my website in the TF code. If you plan to reuse the terraform code here and are cloning the repository it is recommend you replace the html and css files with your own. You would also want to make sure you add any/remove any s3 objects from the terraform code.

## Resources Created

- **S3 Bucket**: Used to store the website's static content.
- **S3 Bucket Ownership Controls**: Sets ownership rules for the S3 bucket.
- **S3 Bucket Public Access Block**: Controls the public access permissions for the S3 bucket.
- **S3 Bucket ACL**: Configures the access control list for the bucket to set it to `public-read`.
- **S3 Objects**: Several static files like HTML, CSS, and images are uploaded to S3.
- **S3 Bucket Website Configuration**: Defines the index and error documents for the website.
- **Route53 Zone**: Represents the DNS zone for the domain.
- **ACM Certificate**: SSL certificate for domain verification and encryption.
- **Route53 Record**: DNS records for domain validation and aliasing the domain to CloudFront.
- **CloudFront Distribution**: CDN distribution for serving the website, with caching, SSL, error handling, and other configurations.

## Prerequisites

- AWS Account
- Terraform installed
- AWS CLI configured with necessary permissions

## Variables

You'll need to set the following variables:

- `bucketName`: The name for your S3 bucket.
- `domain_name`: Your website's domain name (e.g., `example.com`).

## Deployment Steps

1. **Clone the repository**:
```
git clone https://github.com/Dclark2434/www-dustinshapesclouds-com
```

2. **Navigate to the directory**:
```
cd www-dustinshapesclouds-com
```
3. **Replace HTML/CSS Files**

4. **Review and Update Variables:**

Create a terraform.tfvars file and define the following:
```
bucketName = "choose a unique bucket name here"
domain_name = "this should be your domain name without www. (example.com)"
```
5. **Review Resources and Configuraiton**

- Ensure all resources and configurations match their desired AWS setup.  
- You may want to adjust Cloudfront, s3 bucket and route53 settings to better suit your needs.

6. **Initialize Terraform**:
```
terraform init
```

7. **Review plan**:
```
terraform plan
```

8. **Apply**:
```
terraform apply
```

9. **Access Website**  

Once the deployment is successful, you **should** be able to access your website.

10. **Iterate**  

Iterate
Iterate
Iterate

## Cleanup

To destroy the resources created by Terraform:

```
terraform destroy
```

## Additional Notes

- Ensure that your AWS account has the necessary permissions to create the above resources.
- For detailed documentation on each Terraform AWS resource, visit the provided comment links in the code.
- This setup sets the S3 bucket and objects to public-read, but restricts direct bucket access using CloudFront's Origin Access Identity.
