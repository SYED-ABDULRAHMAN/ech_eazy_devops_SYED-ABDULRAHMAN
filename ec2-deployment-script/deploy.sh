STAGE=$1
CONFIG_FILE="${STAGE,,}_config"

echo "Using config file: $CONFIG_FILE"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Config file $CONFIG_FILE not found!"
    exit 1
fi

# Load config values
source "$CONFIG_FILE"

# Set defaults if not present in config
INSTANCE_TYPE=${INSTANCE_TYPE:-"t2.micro"}
REPO_URL=${REPO_URL:-"https://github.com/Trainings-TechEazy/test-repo-for-devops"}
JAVA_VERSION=${JAVA_VERSION:-"21"}
PORT=${PORT:-"80"}
MY_IP=${MY_IP:-"0.0.0.0"}

echo "Starting EC2 deployment..."
echo "Instance Type: $INSTANCE_TYPE"
echo "Java Version: $JAVA_VERSION"
echo "Cloning Repo: $REPO_URL"
echo "App will be accessible at: http://$MY_IP:$PORT/hello"

# -----------------------------
# Example Setup Commands Below
# -----------------------------

echo "Installing Java..."
sudo apt update -y && sudo apt install openjdk-"$JAVA_VERSION"-jdk -y

echo "Cloning Repository..."
git clone "$REPO_URL" app
cd app || exit

echo "uilding App..."
# Example for a Java Maven project
./mvnw clean install

echo "Starting App..."
# Example for running a Spring Boot JAR
nohup java -jar target/*.jar --server.port="$PORT" > app.log 2>&1 &

echo "Scheduling instance auto-stop in 60 minutes..."
sudo shutdown -h +60

echo "App deployed successfully!"
echo "Access it here: http://$MY_IP:$PORT/hello"

