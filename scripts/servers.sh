#!/bin/bash

# Start MySQL container with the specified root password
docker run -d --name mysql-server -e MYSQL_ROOT_PASSWORD=1234 -p 3306:3306 mysql:latest

# Wait for MySQL to be up and running
sleep 10

# Create the 'mywebapp' database
docker exec mysql-server mysql -uroot -p1234 -e "CREATE DATABASE mywebapp;"

# Use the 'mywebapp' database
docker exec mysql-server mysql -uroot -p1234 mywebapp -e "
    CREATE TABLE users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(255) NOT NULL,
        password VARCHAR(255) NOT NULL
    );"

# Create the 'checkboxes' database
docker exec mysql-server mysql -uroot -p1234 -e "CREATE DATABASE checkboxes;"

# Use the 'checkboxes' database
docker exec mysql-server mysql -uroot -p1234 checkboxes -e "
    CREATE TABLE checkbox (
        UserID VARCHAR(255) NOT NULL,
        Timestamp VARCHAR(255) NOT NULL,
        IsChecked BOOLEAN NOT NULL,
        IsReuploaded BOOLEAN NOT NULL
    );"

echo "MySQL server is up and running, 'mywebapp' and 'checkboxes' databases are created, and tables are created."

docker run -d --name=ipfs_host -p 4001:4001 -p 5001:5001 -p 8000:8000 ipfs/go-ipfs:latest
