#!/bin/bash
# Purpose: Start Docker containers defined in docker-compose.yml
# Usage: .tools/start-containers.sh [options] -f <compose-file>

# Function to print messages with a timestamp
print_message() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1"
}

# Function to handle errors
handle_error() {
    print_message "Error: $1"
    exit 1
}

# Retry function
retry_command() {
    local retries=5
    local delay=5
    local count=0
    while [[ $count -lt $retries ]]; do
        "$@" && return 0
        count=$((count + 1))
        print_message "Retrying... ($count/$retries)"
        sleep $delay
    done
    return 1
}

# Wait for a service to be ready
wait_for_service() {
    local url=$1
    local retries=10
    local delay=5
    for ((i=1; i<=retries; i++)); do
        if curl -s "$url" &>/dev/null; then
            return 0
        fi
        print_message "Waiting for service at $url (Attempt $i/$retries)..."
        sleep $delay
    done
    return 1
}

# Function to display help message
show_help() {
    cat << EOF
Usage: .tools/start-containers.sh [options] -f <compose-file>

Options:
  -f, --compose-file <path>        Specify the path to the docker-compose.yml file (required).
  -i, --initialize-containers      Initialize the containers after starting them.
  -rmi, --remove-existing-images   Remove existing containers and images before starting.
  -u, --unattended                 Run the script unattended without waiting for user input.
  -l, --ldif-file <path>           Specify the path to the LDIF file (required with --initialize-containers).
  -h, --help                       Display this help message.

Examples:
  1. Start containers using the default docker-compose.yml file:
     .tools/start-containers.sh -f docker-compose.yml

  2. Remove existing containers and images before starting:
     .tools/start-containers.sh -f docker-compose.yml --remove-existing-images

  3. Start and initialize containers using an LDIF file:
     .tools/start-containers.sh -f docker-compose.yml --initialize-containers --ldif-file res/ldif/mutillidae.ldif

  4. Run the script unattended with initialization and image removal:
     .tools/start-containers.sh -f docker-compose.yml --initialize-containers --ldif-file res/ldif/mutillidae.ldif --remove-existing-images --unattended

  5. Display help for the script:
     .tools/start-containers.sh --help
EOF
}

# Parse options
INITIALIZE_CONTAINERS=false
REMOVE_EXISTING_IMAGES=false
UNATTENDED=false
LDIF_FILE=""
COMPOSE_FILE=""

if [[ "$#" -eq 0 ]]; then
    show_help
    exit 1
fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--initialize-containers) INITIALIZE_CONTAINERS=true ;;
        -rmi|--remove-existing-images) REMOVE_EXISTING_IMAGES=true ;;
        -u|--unattended) UNATTENDED=true ;;
        -l|--ldif-file)
            if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                LDIF_FILE="$2"
                shift
            else
                handle_error "The --ldif-file option requires a valid file path."
            fi ;;
        -f|--compose-file)
            if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                COMPOSE_FILE="$2"
                shift
            else
                handle_error "The --compose-file option requires a valid file path."
            fi ;;
        -h|--help) show_help; exit 0 ;;
        *) handle_error "Unknown parameter passed: $1";;
    esac
    shift
done

if [[ ! -f "$COMPOSE_FILE" ]]; then
    handle_error "The specified compose file does not exist: $COMPOSE_FILE"
fi

if [[ "$INITIALIZE_CONTAINERS" = true ]]; then
    if [[ ! -r "$LDIF_FILE" ]]; then
        handle_error "The specified LDIF file is not readable: $LDIF_FILE"
    fi
fi

if [[ "$REMOVE_EXISTING_IMAGES" = true ]]; then
    print_message "Stopping and removing existing containers and images..."
    .tools/stop-containers.sh -f "$COMPOSE_FILE" || handle_error "Failed to stop existing containers."
    .tools/remove-all-images.sh || handle_error "Failed to remove existing images."
fi

print_message "Starting containers..."
retry_command docker compose -f "$COMPOSE_FILE" up -d || handle_error "Failed to start containers."

if [[ "$INITIALIZE_CONTAINERS" = true ]]; then
    print_message "Waiting for database service..."
    wait_for_service "http://mutillidae.localhost/set-up-database.php" || handle_error "Database service is not ready."

    print_message "Setting up the database..."
    retry_command curl -sS http://mutillidae.localhost/set-up-database.php || handle_error "Failed to set up the database."

    print_message "Waiting for LDAP service..."
    wait_for_service "ldap://mutillidae.localhost" || handle_error "LDAP service is not ready."

    print_message "Adding LDAP entries from LDIF file..."
    retry_command ldapadd -c -x -D "cn=admin,dc=mutillidae,dc=localhost" -w mutillidae -H ldap:// -f "$LDIF_FILE"
    LDAP_STATUS=$?

    if [[ $LDAP_STATUS -eq 0 ]]; then
        print_message "LDAP entries added successfully."
    elif [[ $LDAP_STATUS -eq 68 ]]; then
        print_message "Some or all LDAP entries already exist. No action needed."
    else
        handle_error "LDAP add operation failed with status code $LDAP_STATUS."
    fi
fi

print_message "All operations completed successfully."
