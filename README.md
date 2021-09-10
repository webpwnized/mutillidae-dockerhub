# <span style="color:darkblue">*OWASP Mutillidae II*</span>

## Project Announcements

* **Twitter**: [https://twitter.com/webpwnized](https://twitter.com/webpwnized)

## Tutorials

* **YouTube**: [https://www.youtube.com/user/webpwnized](https://www.youtube.com/user/webpwnized)

## Installation on Docker

The following video tutorials explain how to bring up Mutillidae on a set of 5 containers running Apache/PHP, MySQL, OpenLDAP, PHPMyAdmin, and PHPLDAPAdmin
* **YouTube**: [How to Install Docker on Ubuntu](https://www.youtube.com/watch?v=Y_2JVREtDFk)
* **YouTube**: [How to Run Mutillidae from DockerHub Images](https://www.youtube.com/watch?v=c1nOSp3nagw)

## TLDR

	docker-compose up

## Instructions

There are five containers in this project. 

- **www** - Apache, PHP, Mutillidae source code
- **database** - The MySQL database
- **database_admin** - The PHPMyAdmin console
- **ldap** - The OpenLDAP directory
- **ldap_admin** - The PHPLDAPAdmin console

The containers are built and stored on DockerHub. The docker-compose.yml file instructs docker-compose to download a copy of the containers and run them.

To build the containers, if neccesary, and bring the containers up, run the following command.

	docker-compose up

