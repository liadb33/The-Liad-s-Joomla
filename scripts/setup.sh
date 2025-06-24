#!/bin/bash

# Create Docker network (if it doesn't exist)
docker network create joomla-network || echo "Network already exists"

echo "launching mysql container.."
# Create MySQL 8 container
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

echo "launching joomla container.."
# Create Joomla container
docker run -d \
  --name joomla \
  --network joomla-network \
  -p 8080:80 \
  -e JOOMLA_DB_HOST=joomla-mysql \
  -e JOOMLA_DB_USER=joomlauser \
  -e JOOMLA_DB_PASSWORD=joomlapass \
  -e JOOMLA_DB_NAME=joomla \
  -v joomla-html:/var/www/html \
  joomla


echo "all containers started!"
