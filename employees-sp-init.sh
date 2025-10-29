#!/bin/bash
# Define variables
DB_USER=ubuntu
DB_PASS='Pels202570124$!$!'
DB_NAME=flexibleserverdb
URL=modernapp-mysql-server.mysql.database.azure.com

# Update packages and install required software
apt-get update
apt-get install -y apache2 php php-mysqli mysql-client

cd /opt
mkdir crud
cd /opt/crud

# Download the PHP application code
wget https://d6opu47qoi4ee.cloudfront.net/labs/option3/index.php

# Update the database connection details in the application configuration file
sed -i "s/DB_USER/$DB_USER/g" index.php
sed -i "s/DB_PASS/$DB_PASS/g" index.php
sed -i "s/DB_NAME/$DB_NAME/g" index.php
sed -i "s/DBServer/$URL/g" index.php

cp index.php /var/www/html

# Create the database tables
wget https://d6opu47qoi4ee.cloudfront.net/employees.sql
mysql -h $URL -u $DB_USER -p$DB_PASS $DB_NAME < employees.sql

# Update Apache configuration
sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php index.html/' /etc/apache2/mods-enabled/dir.conf

# Restart Apache
systemctl restart apache2
