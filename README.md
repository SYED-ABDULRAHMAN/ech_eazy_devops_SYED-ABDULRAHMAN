# tech_eazy_DevOps
===============================================
## Floder sctuctre assumption --->
.
├── dev_config
├── prod_config
└── deploy.sh
==================================================
## How to use ?

chmod +x deploy.sh
./deploy.sh Dev
==================================================
## 2nd Assignment

1. Create 2 IAM Roles:

   Role A: S3 ReadOnly

   Role B: S3 write-only (create/upload, no read)

2. Attach Role B to EC2 (via instance profile)

3. Create private S3 bucket (name must be passed; fail if not)

4. Upload EC2 logs to S3 on shutdown

5. Upload Spring app logs (app.log) to /app/logs/

6. Set S3 lifecycle to delete logs after 7 days

7. Use Role A to list uploaded logs (validate access)
=================================================================

## To Verify with Role A:
Launch another EC2 with Role A attached.

Run:
aws s3 ls s3://your-bucket-name/app/logs/

================================================================




