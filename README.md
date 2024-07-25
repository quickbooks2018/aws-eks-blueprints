# Terraform Aws Eks Blue Print

- Eks Cluster Deployment in custom vpc

- Terraform Backend S3 by using aws cli and enabling versioning

```bash
aws s3api create-bucket --bucket cloudgeeks-ca-terraform --region us-east-1
```

```bash
terraform init 
terraform validate
terraform plan
terraform apply -auto-approve
```
