#!/bin/bash

echo "Starting containers";
docker-compose -f docker-compose.yml up -d;

echo "Waiting for database to start";
sleep 10;

echo "Requesting database be built";
curl http://mutillidae.local/set-up-database.php;

echo "Clearing the screen";
clear;
