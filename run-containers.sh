#!/bin/bash

docker-compose -f docker-compose.yml up -d
sleep 10
curl http://mutillidae.local/set-up-database.php
