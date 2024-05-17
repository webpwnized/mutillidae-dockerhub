# **OWASP Mutillidae II**

## Project Announcements

* **Twitter**: [https://twitter.com/webpwnized](https://twitter.com/webpwnized)

## Tutorials

* **YouTube**: [https://www.youtube.com/user/webpwnized](https://www.youtube.com/user/webpwnized)

## Installation on Docker

The following video tutorials explain how to bring up Mutillidae on a set of 5 containers running Apache/PHP, MySQL, OpenLDAP, PHPMyAdmin, and PHPLDAPAdmin:

* [How to Install Docker on Ubuntu](https://www.youtube.com/watch?v=Y_2JVREtDFk)
* [How to Run Mutillidae from DockerHub Images](https://www.youtube.com/watch?v=c1nOSp3nagw)

## TL;DR

docker-compose up -d

## Important Information

The website assumes the user will access the site using the domain `mutillidae.localhost`. The domain can be configured in the user's local hosts file.

## Instructions

There are five containers in this project:

- **www**: Apache, PHP, Mutillidae source code. The website is exposed on ports 80, 443, and 8080.
- **database**: The MySQL database. The database is not exposed externally, but you can modify the Dockerfile to expose the database.
- **database_admin**: The PHPMyAdmin console. The console is exposed on port 81.
- **ldap**: The OpenLDAP directory. The directory is exposed on port 389 to allow import of the `mutillidae.ldif` file. This file is found in the ***res*** resourses folder of the project.
- **ldap_admin**: The PHPLDAPAdmin console. The console is exposed on port 82.

To download the containers, if necessary, and bring them up, run the following command:

docker-compose up -d

Once the containers are running, the following services are available on `localhost`:

- **Port 80, 8080**: Mutillidae HTTP web interface
- **Port 81**: MySQL Admin HTTP web interface
- **Port 82**: LDAP Admin web interface
- **Port 443**: HTTPS web interface
- **Port 389**: LDAP interface

These services are connected using two networks, `datanet` and `ldapnet`, to separate the database and LDAP traffic. Volumes `ldap_data` and `ldap_config` are used to persist LDAP data and configuration.
