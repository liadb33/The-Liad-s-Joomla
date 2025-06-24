# 📦 Joomla Docker Deployment Project

A full Joomla website deployment using Docker, with MySQL integration, backup/restore automation, and team content collaboration.

---

## 👤 Who We Are

> Developed by **Liad Barsheshet**, **Shlomi Haser**, and **Ben Noyman**  
> This project was submitted as part of a Docker + CMS assignment.

---

## 📌 Project Requirements

We were required to:

- Deploy a **Joomla-based website** using **Docker**
- Connect Joomla to a **MySQL database**
- Ensure **persistent data storage** using Docker volumes
- Automate backup and restore of:
  - MySQL database
  - Joomla site files
- Create users and content for each team member
- Write **automation scripts** in Bash
- Document everything in a Git repository

---

## 🛠️ What Was Done

- **Dockerized** Joomla and MySQL with a shared network
- Used named volumes for data persistence
- Created automation scripts:
  - `setup.sh`: builds and runs containers
  - `backup.sh`: performs volume + DB backup
  - `restore.sh`: restores the site from backup
  - `cleanup.sh`: stops and removes all containers/volumes
- Backups are stored with timestamps inside the `backups/` folder
- Joomla was fully configured and installed via the web interface

---

## 🔐 Credentials

### Joomla Admin
- URL: [http://localhost:8080/administrator](http://localhost:8080/administrator)
- **Username:** `demoadmin`  
- **Password:** `secretpassword`

### MySQL Database
- **Host:** `localhost`  
- **Port:** `3306`  
- **Root Username:** `root`  
- **Root Password:** `my-secret-pw`  
- **Database Name:** `joomla`  
- **User:** `joomlauser`  
- **User Password:** `joomlapass`

---

## 🚀 Step-by-Step: How to Restore the Website

> This guide shows exactly how to clone this project and restore the site (including Joomla configuration and articles).

### 1. 📥 Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPOSITORY_NAME.git
cd YOUR_REPOSITORY_NAME
```

### 2. 📁 Verify Project Structure

Make sure the following folders and files exist:

```
.
├── backups/
├── scripts/
│   ├── setup.sh
│   ├── backup.sh
│   ├── restore.sh
│   └── cleanup.sh
├── docker-compose.yml
└── README.md
```

### 3. 💾 Place Backup Files (if not already there)

If backup files aren't already in `backups/`, copy them there:

- A file like: `my-joomla-backup_YYYY-MM-DD_HH-MM-SS.sql.gz`
- A file like: `joomla_html_YYYY-MM-DD_HH-MM-SS.tar.gz`

---

### 4. ♻️ Run the Restore Script

```bash
cd scripts
./restore.sh
```

This will:

- Automatically detect the latest backup files in `../backups/`
- Restore the MySQL database
- Restore Joomla files into the Docker volume
- Restart the Joomla container

---

### 5. 🌐 Access the Restored Joomla Site

- Website: [http://localhost:8080](http://localhost:8080)
- Admin: [http://localhost:8080/administrator](http://localhost:8080/administrator)
- Login using the credentials listed above

---

## 🧩 Optional: Connect with MySQL Workbench

> You can use MySQL Workbench or another DB client to inspect the Joomla database.

### 🧾 Instructions:

1. Open **MySQL Workbench**
2. Click `+` to add a new connection
3. Use the following values:

```
Connection Name: Joomla-DB
Hostname: 127.0.0.1
Port: 3306
Username: root
Password: my-secret-pw
```

4. Click **Test Connection** → should say “Connected”
5. Click **OK** to save
6. Open the connection to explore the `joomla` database

> ⚠️ Make sure the MySQL container is running (`docker ps`)

---

## 🧹 Optional: Clean and Rebuild

If you want to reset everything:

```bash
./scripts/cleanup.sh
./scripts/setup.sh
```

---

## 💻 Environment

- Tested on Ubuntu-based Linux with Docker CLI
- Joomla official image used (~750MB)
- MySQL official image used (~632MB)

---

## 📂 Repository Structure

```
joomla-project/
├── backups/           # Automatically created backup files (.sql.gz, .tar.gz)
├── scripts/           # Bash scripts for automation
│   ├── setup.sh
│   ├── backup.sh
│   ├── restore.sh
│   └── cleanup.sh
├── docker-compose.yml
└── README.md
```

---

## ℹ️ Additional Notes

- Default MySQL root password is hardcoded for local testing only.
- Restore script auto-detects the newest backup files if no arguments are provided.

---

> ✅ Done according to project instructions. Built with care and clarity for reproducibility.
