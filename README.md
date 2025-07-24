# 🚀 EC2 Deployment Automation - DevOps Assignment 1 - Pratik Kumbhar

This project automates the deployment of a web application on an AWS EC2 instance using a simple bash script.

---

## 📁 Files Included

* `deploy.sh` – Automates EC2 instance creation, app setup, logging, and optional auto-stop.
* `dev_config` – Configuration file to define:

  * Instance type
  * Java version
  * GitHub repo URL
  * Port to run the app
  * Public IP to access the app

---

## ⚙️ Usage

### 1⃣️ Clone the repo

```bash
git clone https://github.com/Trainings-TechEazy/test-repo-for-devops.git
cd test-repo-for-devops
```

### 2⃣️ Update the config

Edit `dev_config` to match your setup:

```bash
INSTANCE_TYPE="t3.micro"
REPO_URL="https://github.com/Trainings-TechEazy/test-repo-for-devops"
JAVA_VERSION="21"
PORT="80"
MY_IP="65.0.107.95"
```

### 3⃣️ Deploy!

```bash
chmod +x deploy.sh
./deploy.sh
```

---

## 🌐 Output

Once deployed, open your browser:

```
http://65.0.107.95/hello
```

---

## 💡 Features

* 📦 Installs system updates, Java, Git
* 📁 Clones custom repo
* 🚀 Starts HTTP server on defined port
* 📃 Logs everything to `deploy.log`
* 💰 Optional EC2 auto-stop for cost saving

---

## 👍 Cost Saving

The script includes logic to auto-stop the EC2 instance after a successful run to avoid extra charges. You can disable it by setting:

```bash
AUTO_STOP="false"
```

---

## ✅ Tested On

* EC2 Type: `t3.micro`
* Public IP: `65.0.107.95`
* OS: Amazon Linux 2023
