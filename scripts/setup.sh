#!/bin/bash

# === Step 1: Create Docker network (if not exists) ===
docker network create joomla-network >/dev/null 2>&1 && echo "✅ Network created: joomla-network" || echo "ℹ️ Network already exists"

# === Step 2: Launch MySQL Container ===
echo "🚀 Launching MySQL container..."
docker run -d \
  --name joomla-mysql \
  --network joomla-network \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=my-secret-pw \
  -e MYSQL_DATABASE=joomla \
  -e MYSQL_USER=joomlauser \
  -e MYSQL_PASSWORD=joomlapass \
  -v joomla-mysql-data:/var/lib/mysql \
  mysql:8

# === Step 3: Launch Joomla Container ===
echo "🚀 Launching Joomla container..."
docker run -d \
  --name joomla \
  --network joomla-network \
  -p 8080:80 \
  -e JOOMLA_DB_HOST=joomla-mysql \
  -e JOOMLA_DB_USER=joomlauser \
  -e JOOMLA_DB_PASSWORD=joomlauser \
  -e JOOMLA_DB_NAME=joomla \
  -v joomla-html:/var/www/html \
  joomla

# === Wait for containers to be ready ===
echo "⏳ Waiting for containers to start..."
sleep 10

# === Check container status ===
echo "📋 Container status:"
if docker ps | grep -q "joomla-mysql"; then
  echo "✅ MySQL container is running"
else
  echo "❌ MySQL container failed to start"
  docker logs joomla-mysql
fi

if docker ps | grep -q "joomla"; then
  echo "✅ Joomla container is running"
else
  echo "❌ Joomla container failed to start"
  docker logs joomla
fi

# === Final Message ===
echo ""
echo "🎉 Setup completed!"
