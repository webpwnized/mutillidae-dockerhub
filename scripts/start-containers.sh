#!/bin/bash

echo "";
echo "Starting containers";
docker-compose -f docker-compose.yml up -d;

echo "";
echo "Waiting for database to start";
sleep 10;

echo "";
echo "Requesting database be built";
curl http://mutillidae.local/set-up-database.php;

echo "";
echo "Clearing the screen";
clear;
