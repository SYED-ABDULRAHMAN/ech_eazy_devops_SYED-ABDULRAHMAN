# EC2 Terraform Deployment Project

This project automates the deployment of a web application on an AWS EC2 instance using Terraform and a setup script. The application runs on port `8080` and can be accessed at `/hello`.

## Features

- Terraform IaC for AWS EC2 setup
- Auto-configuration of Node.js, Python, or Java applications
- Optional Docker and Nginx reverse proxy setup
- Health check script included
- Terraform state stored in AWS S3 backend

## Prerequisites

- AWS account
- GitHub repository with the following secrets set:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `EC2_SSH_PRIVATE_KEY` (if needed for SSH access)
- S3 bucket for Terraform state
- DynamoDB table (optional) for state locking

## S3 Backend Setup

1. Create an S3 bucket for Terraform state:
   ```bash
   aws s3 mb s3://my-terraform-state-bucket
(Optional) Create a DynamoDB table for state locking:

bash
Copy code
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
Update the backend "s3" block in terraform/main.tf with your bucket name, key, and region.

Setup & Deployment
Clone this repository:

bash
Copy code
git clone <your-repo-url>
cd <repo-folder>
Update terraform/variables.tf with your preferred configuration:

github_repo_url → your application repository

app_port → port number for the app (default: 8080)

Run the GitHub Actions workflow:

Push changes to the main branch.

The workflow will:

Initialize Terraform

Apply the infrastructure

Deploy the application on EC2

Check your application:

http://<EC2_PUBLIC_IP>:8080/hello
