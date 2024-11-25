#!/bin/bash
# Purpose: Start Docker containers defined in docker-compose.yml
# Usage: ./start-containers.sh [options] -f <compose-file>

# Function to print messages with a timestamp
print_message() {
    echo ""
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1"
}

# Function to handle errors
handle_error() {
    print_message "Error: $1"
    exit 1
}

# Function to display help message
show_help() {
    cat << EOF
Usage: $0 [options] -f <compose-file>

Options:
  -f, --compose-file <path>    Specify the path to the docker-compose.yml file (required).
  -i, --initialize-containers  Initialize the containers after starting them.
  -r, --rebuild-containers     Rebuild the containers before starting them.
  -u, --unattended             Run the script unattended without waiting for user input.
  -l, --ldif-file <path>       Specify the path to the LDIF file (required with --initialize-containers).
  -h, --help                   Display this help message.

Examples:
  ./start-containers.sh --compose-file ./docker-compose.yml
  ./start-containers.sh --compose-file ./docker-compose.yml --rebuild-containers
  ./start-containers.sh --compose-file ./docker-compose.yml --initialize-containers --ldif-file ./res/ldif/mutillidae.ldif
EOF
}

# Parse options
INITIALIZE_CONTAINERS=false
REBUILD_CONTAINERS=false
UNATTENDED=false
LDIF_FILE=""
COMPOSE_FILE=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--initialize-containers) INITIALIZE_CONTAINERS=true ;;
        -r|--rebuild-containers) REBUILD_CONTAINERS=true ;;
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

# Ensure the compose file is provided and exists
if [[ -z "$COMPOSE_FILE" ]]; then
    handle_error "The --compose-file option is required."
fi
if [[ ! -f "$COMPOSE_FILE" ]]; then
    handle_error "The specified compose file does not exist: $COMPOSE_FILE"
fi

# If initialization is required, ensure the LDIF file is provided and exists
if [[ "$INITIALIZE_CONTAINERS" = true ]]; then
    if [[ -z "$LDIF_FILE" ]]; then
        handle_error "The --ldif-file option is required when using --initialize-containers."
    fi
    if [[ ! -f "$LDIF_FILE" ]]; then
        handle_error "The specified LDIF file does not exist: $LDIF_FILE"
    fi
    if ! command -v ldapadd &>/dev/null; then
        handle_error "ldapadd is not installed. Please install ldap-utils."
    fi
fi

# Remove existing containers and images if rebuilding is requested
if [[ "$REBUILD_CONTAINERS" = true ]]; then
    print_message "Rebuilding containers..."
    docker compose --file "$COMPOSE_FILE" down --rmi all -v || handle_error "Failed to remove existing containers and images."
fi

# Start Docker containers
print_message "Starting containers..."
docker compose --file "$COMPOSE_FILE" up --detach || handle_error "Failed to start Docker containers."

# Initialize containers if requested
if [[ "$INITIALIZE_CONTAINERS" = true ]]; then
    print_message "Waiting for containers to initialize..."
    sleep 10

    print_message "Setting up the database..."
    curl -sS http://mutillidae.localhost/set-up-database.php || handle_error "Failed to set up the database."

    print_message "Adding LDAP entries from LDIF file..."
    ldapadd -c -x -D "cn=admin,dc=mutillidae,dc=localhost" -w mutillidae -H ldap:// -f "$LDIF_FILE"
    LDAP_STATUS=$?
    if [[ $LDAP_STATUS -eq 0 ]]; then
        print_message "LDAP entries added successfully."
    elif [[ $LDAP_STATUS -eq 68 ]]; then
        print_message "Some LDAP entries already existed. Others were added successfully."
    else
        handle_error "Failed to add LDAP entries. ldapadd exited with status $LDAP_STATUS."
    fi

    # Wait for user input if not running unattended
    if [[ "$UNATTENDED" = false ]]; then
        read -p "Press Enter to continue or <CTRL>-C to stop" </dev/tty
        clear
    fi
fi

print_message "All operations completed successfully."
