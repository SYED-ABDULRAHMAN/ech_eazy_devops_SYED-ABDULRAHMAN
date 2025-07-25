#!/bin/bash

# Check input
STAGE=$1
if [[ -z "$STAGE" ]]; then
  echo "❌ Please provide the stage name: Dev or Prod"
  exit 1
fi

# Convert to lowercase and load config
CONFIG_FILE="${STAGE,,}_config"
if [[ -f "$CONFIG_FILE" ]]; then
  echo "📄 Loading config from $CONFIG_FILE"
  source "$CONFIG_FILE"
else
  echo "❌ Config file '$CONFIG_FILE' not found!"
  exit 1
fi

# Update and install Java and Maven
echo "🔧 Installing Java $JAVA_VERSION and Maven..."
sudo yum update -y
sudo amazon-linux-extras enable corretto$JAVA_VERSION
sudo yum install -y java-$JAVA_VERSION-amazon-corretto maven git

# Verify Java and Maven
java -version
mvn -version

# Clone GitHub repo
echo "📦 Cloning repository..."
git clone "$GITHUB_REPO"
REPO_DIR=$(basename "$GITHUB_REPO" .git)
cd "$REPO_DIR" || { echo "❌ Repo not found"; exit 1; }

# Build the app
echo "🔨 Building the project with Maven..."
mvn clean package

# Run the app
echo "🚀 Running the Spring Boot application..."
nohup java -jar "$APP_PATH" > app.log 2>&1 &

# Wait and check if app is up
echo "⏳ Waiting for app to start..."
sleep 15
EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

if curl -s --max-time 5 "http://$EC2_IP:$APP_PORT/hello" | grep -q "Hello from Spring MVC!"; then
  echo "✅ App is reachable at: http://$EC2_IP:$APP_PORT/hello"
else
  echo "❌ App is not responding on port $APP_PORT"
fi

# Schedule shutdown
echo "🕒 Scheduling instance to stop in $TIMEOUT_MIN minutes..."
sudo shutdown -h +$TIMEOUT_MIN
