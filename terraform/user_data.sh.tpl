#!/bin/bash
# Log everything to a file for debugging
exec > /var/log/user-data.log 2>&1
set -e

echo "---- Updating package list ----"
sudo apt-get update -y

echo "---- Installing Java 21 ----"
sudo apt-get install -y wget gnupg2 software-properties-common

sudo mkdir -p /etc/apt/keyrings
wget -O- https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor | sudo tee /etc/apt/keyrings/adoptium.gpg > /dev/null

echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb jammy main" | sudo tee /etc/apt/sources.list.d/adoptium.list

sudo apt-get update -y
sudo apt-get install -y temurin-21-jdk

echo "---- Installing Maven and Git ----"
sudo apt-get install -y maven git

echo "---- Cloning Spring Boot App ----"
cd /home/ubuntu
git clone ${repo_url} app
cd app

echo "---- Building App with Maven ----"
mvn clean package

echo "---- Running Spring Boot App ----"
nohup java -jar target/hellomvc-0.0.1-SNAPSHOT.jar > springboot.log 2>&1 &
