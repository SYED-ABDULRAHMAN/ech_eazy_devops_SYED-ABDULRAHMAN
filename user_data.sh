#!/bin/bash
STAGE="Dev"
BUCKET_NAME="<<replace-during-terraform>>"

# Install packages
yum update -y
yum install -y git java-21-amazon-corretto maven

# Clone and build
cd /home/ec2-user
git clone https://github.com/Trainings-TechEazy/test-repo-for-devops
cd test-repo-for-devops
mvn clean package
nohup java -jar target/hellomvc-0.0.1-SNAPSHOT.jar > app.log 2>&1 &

# Schedule shutdown
shutdown -h +30

# Add shutdown log upload
cat << 'EOF' > /etc/systemd/system/upload-logs.service
[Unit]
Description=Upload logs to S3 on shutdown
DefaultDependencies=no
Before=shutdown.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/upload_logs.sh
RemainAfterExit=true

[Install]
WantedBy=shutdown.target
EOF

chmod 644 /etc/systemd/system/upload-logs.service
systemctl enable upload-logs.service

# Upload script
cat << EOF > /usr/local/bin/upload_logs.sh
#!/bin/bash
aws s3 cp /var/log/cloud-init.log s3://$BUCKET_NAME/system_logs/
aws s3 cp /home/ec2-user/test-repo-for-devops/app.log s3://$BUCKET_NAME/app/logs/
EOF

chmod +x /usr/local/bin/upload_logs.sh
