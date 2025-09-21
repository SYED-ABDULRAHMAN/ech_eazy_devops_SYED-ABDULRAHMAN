#!/bin/bash
set -e
echo 'export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' >> /etc/profile
export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Update system packages
apt-get update -y
apt-get upgrade -y

# Install essential packages
apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    build-essential

# Install Node.js (LTS version)
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
apt-get install -y nodejs

# Install Python 3 and pip
apt-get install -y python3 python3-pip python3-venv

# Install Java 21 (OpenJDK 21)
apt-get install -y openjdk-21-jdk

# Set JAVA_HOME for Java 21
echo 'export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64' >> /etc/environment
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /etc/environment
source /etc/environment

# Install Docker (optional, in case the app needs it)
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install nginx for reverse proxy (optional)
apt-get install -y nginx

# Create application directory
mkdir -p /opt/app
cd /opt/app

# Clone the repository
git clone ${github_repo_url} .

# Set ownership to ubuntu user
chown -R ubuntu:ubuntu /opt/app

# Create log directory
mkdir -p /var/log/app
chown ubuntu:ubuntu /var/log/app

# Function to detect and setup the application
setup_application() {
    cd /opt/app
    
    # Check for different types of applications and set them up accordingly
    
    if [ -f "package.json" ]; then
        echo "Node.js application detected"
        # Install npm dependencies
        sudo -u ubuntu npm install
        
        # Check if there's a build script
        if npm run --silent | grep -q "build"; then
            sudo -u ubuntu npm run build
        fi
        
        # Create systemd service for Node.js app
        cat > /etc/systemd/system/app.service << EOF
[Unit]
Description=Node.js Application
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/app
Environment=NODE_ENV=production
Environment=PORT=${app_port}
ExecStart=/usr/bin/node \$(if [ -f "dist/index.js" ]; then echo "dist/index.js"; elif [ -f "build/index.js" ]; then echo "build/index.js"; elif [ -f "server.js" ]; then echo "server.js"; elif [ -f "app.js" ]; then echo "app.js"; else echo "index.js"; fi)
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=app

[Install]
WantedBy=multi-user.target
EOF
        
    elif [ -f "requirements.txt" ]; then
        echo "Python application detected"
        # Create virtual environment
        sudo -u ubuntu python3 -m venv venv
        # Install dependencies
        sudo -u ubuntu ./venv/bin/pip install -r requirements.txt
        
        # Try to detect the main Python file
        MAIN_FILE=""
        if [ -f "app.py" ]; then
            MAIN_FILE="app.py"
        elif [ -f "main.py" ]; then
            MAIN_FILE="main.py"
        elif [ -f "server.py" ]; then
            MAIN_FILE="server.py"
        elif [ -f "run.py" ]; then
            MAIN_FILE="run.py"
        else
            MAIN_FILE="app.py"  # Default
        fi
        
        # Create systemd service for Python app
        cat > /etc/systemd/system/app.service << EOF
[Unit]
Description=Python Application
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/app
Environment=PYTHONPATH=/opt/app
Environment=PORT=${app_port}
ExecStart=/opt/app/venv/bin/python $MAIN_FILE
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=app

[Install]
WantedBy=multi-user.target
EOF
        
    elif [ -f "pom.xml" ]; then
        echo "Maven Java application detected"
        # Install Maven
        apt-get install -y maven
        
        # Set JAVA_HOME for this session
        export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
        export PATH=$PATH:$JAVA_HOME/bin
        
        # Build the application
        sudo -u ubuntu -E JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 mvn clean package -DskipTests
        
        # Find the specific JAR file
        JAR_FILE="techeazy-devops-0.0.1-SNAPSHOT.jar"
        if [ ! -f "target/$JAR_FILE" ]; then
            # Fallback to any JAR file if the specific one doesn't exist
            JAR_FILE=$(find target -name "*.jar" -not -name "*-sources.jar" -not -name "*-original.jar" | head -1)
            if [ -n "$JAR_FILE" ]; then
                JAR_FILE=$(basename "$JAR_FILE")
            else
                echo "No JAR file found after build"
                exit 1
            fi
        fi
        
        echo "Using JAR file: $JAR_FILE"
        
        # Create systemd service for Java app
        cat > /etc/systemd/system/app.service << EOF
[Unit]
Description=TechEazy DevOps Spring Boot Application
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/app
Environment=JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
Environment=PATH=/usr/lib/jvm/java-21-openjdk-amd64/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=PORT=${app_port}
ExecStart=/usr/lib/jvm/java-21-openjdk-amd64/bin/java -jar target/$JAR_FILE --server.port=${app_port}
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=techeazy-app

[Install]
WantedBy=multi-user.target
EOF
        
    elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        echo "Gradle Java application detected"
        # Install Gradle
        wget https://services.gradle.org/distributions/gradle-8.4-bin.zip
        unzip gradle-8.4-bin.zip -d /opt/
        ln -s /opt/gradle-8.4/bin/gradle /usr/local/bin/gradle
        
        # Build the application
        sudo -u ubuntu gradle build -x test
        
        # Find the JAR file
        JAR_FILE=$(find build/libs -name "*.jar" | head -1)
        
        # Create systemd service for Java app
        cat > /etc/systemd/system/app.service << EOF
[Unit]
Description=Java Application
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/app
Environment=JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
Environment=PORT=${app_port}
ExecStart=/usr/lib/jvm/java-21-openjdk-amd64/bin/java -jar $JAR_FILE
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=app

[Install]
WantedBy=multi-user.target
EOF
        
    elif [ -f "Dockerfile" ]; then
        echo "Docker application detected"
        # Build and run with Docker
        sudo -u ubuntu docker build -t myapp .
        
        # Create systemd service for Docker app
        cat > /etc/systemd/system/app.service << EOF
[Unit]
Description=Docker Application
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/app
ExecStart=/usr/bin/docker run --rm -p ${app_port}:${app_port} myapp
ExecStop=/usr/bin/docker stop myapp
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=app

[Install]
WantedBy=multi-user.target
EOF
        
    else
        echo "Unknown application type. Creating a simple HTTP server"
        # Create a simple Python HTTP server as fallback
        cat > /opt/app/simple_server.py << EOF
#!/usr/bin/env python3
import http.server
import socketserver
import os

PORT = int(os.environ.get('PORT', ${app_port}))

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(b'''
            <!DOCTYPE html>
            <html>
            <head><title>Application Deployed Successfully</title></head>
            <body>
                <h1>🎉 Application Deployed Successfully!</h1>
                <p>Your lift and shift deployment is working.</p>
                <p>Repository contents are available in /opt/app</p>
                <p>Server running on port ${app_port}</p>
            </body>
            </html>
            ''')
        else:
            super().do_GET()

with socketserver.TCPServer(("", PORT), MyHTTPRequestHandler) as httpd:
    print(f"Server running on port {PORT}")
    httpd.serve_forever()
EOF
        
        chown ubuntu:ubuntu /opt/app/simple_server.py
        chmod +x /opt/app/simple_server.py
        
        # Create systemd service for simple server
        cat > /etc/systemd/system/app.service << EOF
[Unit]
Description=Simple HTTP Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/app
Environment=PORT=${app_port}
ExecStart=/usr/bin/python3 /opt/app/simple_server.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=app

[Install]
WantedBy=multi-user.target
EOF
    fi
    
    # Enable and start the application service
    systemctl daemon-reload
    systemctl enable app
    systemctl start app
    
    # Wait a moment and check if service is running
    sleep 5
    systemctl status app || true
}

# Setup the application
setup_application

# Configure nginx as reverse proxy (optional)
cat > /etc/nginx/sites-available/app << EOF
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://localhost:${app_port};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable the nginx site
ln -sf /etc/nginx/sites-available/app /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration and restart
nginx -t && systemctl restart nginx

# Enable nginx to start on boot
systemctl enable nginx

# Create a health check script
cat > /opt/app/health_check.sh << 'EOF'
#!/bin/bash
echo "=== Application Health Check ==="
echo "Date: $(date)"
echo "System Uptime: $(uptime)"
echo ""

echo "=== Service Status ==="
systemctl is-active app || echo "App service not running"
systemctl is-active nginx || echo "Nginx service not running"
echo ""

echo "=== Port Status ==="
netstat -tlnp | grep :80 || echo "Port 80 not listening"
netstat -tlnp | grep :${app_port} || echo "Port ${app_port} not listening"
echo ""

echo "=== Application Logs (last 10 lines) ==="
journalctl -u app -n 10 --no-pager
EOF

chmod +x /opt/app/health_check.sh
chown ubuntu:ubuntu /opt/app/health_check.sh

# Log completion
echo "$(date): Application setup completed" >> /var/log/cloud-init.log

# Final health check
/opt/app/health_check.sh >> /var/log/cloud-init.log
