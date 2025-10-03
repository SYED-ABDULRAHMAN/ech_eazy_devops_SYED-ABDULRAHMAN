#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/cloud-init.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== Starting deployment: $(date) ==="

# ----------------------------
# 1. Update PATH safely
# ----------------------------
if ! grep -q "/usr/local/sbin" /etc/profile; then
    echo 'export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' >> /etc/profile
fi
export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# ----------------------------
# 2. Update system and install essentials
# ----------------------------
apt-get update -y
apt-get upgrade -y
apt-get install -y \
    curl wget git unzip software-properties-common apt-transport-https \
    ca-certificates gnupg lsb-release build-essential net-tools

# ----------------------------
# 3. Install Node.js LTS
# ----------------------------
if ! command -v node &>/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    apt-get install -y nodejs
fi

# ----------------------------
# 4. Install Python3
# ----------------------------
apt-get install -y python3 python3-pip python3-venv

# ----------------------------
# 5. Install OpenJDK 21
# ----------------------------
apt-get install -y openjdk-21-jdk
if ! grep -q "JAVA_HOME" /etc/environment; then
    echo 'export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64' >> /etc/environment
    echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /etc/environment
fi
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=$PATH:$JAVA_HOME/bin

# ----------------------------
# 6. Install Docker if not installed
# ----------------------------
if ! command -v docker &>/dev/null; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
        | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    usermod -aG docker ubuntu
fi

# ----------------------------
# 7. Install Nginx
# ----------------------------
apt-get install -y nginx

# ----------------------------
# 8. Prepare application directory
# ----------------------------
APP_DIR="/opt/app"
mkdir -p "$APP_DIR"
cd "$APP_DIR"

# Clone repo if empty
if [ -z "$(ls -A "$APP_DIR")" ]; then
    git clone "${github_repo_url}" .
fi
chown -R ubuntu:ubuntu "$APP_DIR"
mkdir -p /var/log/app
chown ubuntu:ubuntu /var/log/app

# ----------------------------
# 9. Application Setup Function
# ----------------------------
setup_application() {
    cd "$APP_DIR"

    # ------------------------
    # Node.js
    # ------------------------
    if [ -f "package.json" ]; then
        echo "Node.js application detected"
        sudo -u ubuntu npm install
        if npm run --silent | grep -q "build"; then
            sudo -u ubuntu npm run build
        fi
        ENTRY_FILE=$(find . -maxdepth 2 -type f \( -name "dist/index.js" -o -name "build/index.js" -o -name "server.js" -o -name "app.js" -o -name "index.js" \) | head -1)
        [ -z "$ENTRY_FILE" ] && ENTRY_FILE="index.js"
        cat > /etc/systemd/system/app.service <<EOF
[Unit]
Description=Node.js App
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=$APP_DIR
Environment=NODE_ENV=production
Environment=PORT=${app_port}
ExecStart=/usr/bin/node $ENTRY_FILE
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=app

[Install]
WantedBy=multi-user.target
EOF

    # ------------------------
    # Python
    # ------------------------
    elif [ -f "requirements.txt" ]; then
        echo "Python application detected"
        sudo -u ubuntu python3 -m venv venv
        sudo -u ubuntu ./venv/bin/pip install -r requirements.txt
        MAIN_FILE=$(ls | grep -E "app.py|main.py|server.py|run.py" | head -1)
        [ -z "$MAIN_FILE" ] && MAIN_FILE="app.py"
        cat > /etc/systemd/system/app.service <<EOF
[Unit]
Description=Python App
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=$APP_DIR
Environment=PYTHONPATH=$APP_DIR
Environment=PORT=${app_port}
ExecStart=$APP_DIR/venv/bin/python $MAIN_FILE
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=app

[Install]
WantedBy=multi-user.target
EOF

    # ------------------------
    # Java Maven/Gradle
    # ------------------------
    elif [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        echo "Java application detected"
        apt-get install -y maven unzip
        if [ -f "pom.xml" ]; then
            sudo -u ubuntu -E JAVA_HOME=$JAVA_HOME mvn clean package -DskipTests
            JAR_FILE=$(find target -name "*.jar" | grep -vE "sources|original" | head -1)
        else
            # Gradle
            wget -q https://services.gradle.org/distributions/gradle-8.4-bin.zip
            unzip -o gradle-8.4-bin.zip -d /opt/
            ln -sf /opt/gradle-8.4/bin/gradle /usr/local/bin/gradle
            sudo -u ubuntu gradle build -x test
            JAR_FILE=$(find build/libs -name "*.jar" | head -1)
        fi
        [ -z "$JAR_FILE" ] && echo "No JAR found" && exit 1
        cat > /etc/systemd/system/app.service <<EOF
[Unit]
Description=Java App
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=$APP_DIR
Environment=JAVA_HOME=$JAVA_HOME
Environment=PATH=$JAVA_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=PORT=${app_port}
ExecStart=$JAVA_HOME/bin/java -jar $JAR_FILE --server.port=${app_port}
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=app

[Install]
WantedBy=multi-user.target
EOF

    # ------------------------
    # Docker
    # ------------------------
    elif [ -f "Dockerfile" ]; then
        echo "Docker application detected"
        sudo -u ubuntu docker build -t myapp .
        cat > /etc/systemd/system/app.service <<EOF
[Unit]
Description=Docker App
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/docker run --rm -p ${app_port}:${app_port} --name myapp myapp
ExecStop=/usr/bin/docker stop myapp || true
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=app

[Install]
WantedBy=multi-user.target
EOF

    # ------------------------
    # Fallback: Simple Python HTTP server
    # ------------------------
    else
        echo "Unknown app type: using fallback HTTP server"
        cat > $APP_DIR/simple_server.py <<EOF
#!/usr/bin/env python3
import http.server, socketserver, os
PORT=int(os.environ.get('PORT', ${app_port}))
class MyHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path=='/':
            self.send_response(200)
            self.send_header('Content-type','text/html')
            self.end_headers()
            self.wfile.write(b"<h1>App Deployed Successfully</h1>")
        else:
            super().do_GET()
with socketserver.TCPServer(("", PORT), MyHandler) as httpd:
    print(f"Server running on port {PORT}")
    httpd.serve_forever()
EOF
        chmod +x $APP_DIR/simple_server.py
        cat > /etc/systemd/system/app.service <<EOF
[Unit]
Description=Simple HTTP Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=$APP_DIR
Environment=PORT=${app_port}
ExecStart=/usr/bin/python3 $APP_DIR/simple_server.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=app

[Install]
WantedBy=multi-user.target
EOF
    fi

    # ------------------------
    # Enable and start app
    # ------------------------
    systemctl daemon-reload
    systemctl enable app
    systemctl restart app
    echo "Application service setup complete."
}

# Run setup
setup_application

# ----------------------------
# 10. Configure Nginx
# ----------------------------
NGINX_SITE="/etc/nginx/sites-available/app"
cat > "$NGINX_SITE" <<EOF
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
ln -sf "$NGINX_SITE" /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx
systemctl enable nginx

echo "=== Deployment completed successfully: $(date) ==="
