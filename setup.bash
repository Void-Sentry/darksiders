#!/bin/bash

# Minimum required versions
MIN_DOCKER_VERSION="27.5.1"
MIN_COMPOSE_VERSION="v2.32.4"
MIN_DESKTOP_VERSION="4.40.0"

# Colors for messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if command exists and is executable
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to run command with appropriate privileges
run_with_privileges() {
    if [ "$NEED_SUDO" = true ]; then
        # echo -e "${YELLOW}Requires sudo privileges, please enter password if prompted...${NC}"
        sudo "$@"
    else
        "$@"
    fi
}

# Check dependencies and permissions
check_dependencies_and_permissions() {
    local missing=()
    local docker_ok=false
    local compose_ok=false
    NEED_SUDO=false

    # Check for basic commands
    for cmd in git bash less sh grep sed awk sort; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done

    # Check Docker
    if command_exists "docker"; then
        if docker info &>/dev/null; then
            docker_ok=true
            DOCKER_CMD="docker"
        elif sudo docker info &>/dev/null; then
            docker_ok=true
            DOCKER_CMD="sudo docker"
            NEED_SUDO=true
        fi
    fi

    # Check Docker Compose
    if command_exists "docker-compose"; then
        compose_ok=true
        COMPOSE_CMD="docker-compose"
    elif command_exists "docker" && docker compose version &>/dev/null; then
        compose_ok=true
        COMPOSE_CMD="docker compose"
    fi

    # Verify compose works with current privileges
    if $compose_ok && [ "$NEED_SUDO" = true ]; then
        if ! sudo $COMPOSE_CMD version &>/dev/null; then
            compose_ok=false
        fi
    fi

    # Error reporting
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing dependencies:${NC} ${missing[*]}"
        echo -e "\nInstall with:"

        if command_exists "apt"; then
            echo "sudo apt install ${missing[*]}"
        elif command_exists "yum"; then
            echo "sudo yum install ${missing[*]}"
        elif command_exists "pacman"; then
            echo "sudo pacman -S ${missing[*]}"
        else
            echo "Please install manually: ${missing[*]}"
        fi
        exit 1
    fi

    if ! $docker_ok; then
        echo -e "${RED}Error: Docker is not installed or not accessible${NC}"
        echo "Install with:"
        echo "  https://docs.docker.com/engine/install/"
        exit 1
    fi

    if ! $compose_ok; then
        echo -e "${RED}Error: Docker Compose is not installed or not accessible${NC}"
        echo "Install with:"
        echo "  https://docs.docker.com/compose/install/"
        exit 1
    fi

    if [ "$NEED_SUDO" = true ]; then
        echo -e "${YELLOW}Warning: Using sudo for Docker commands${NC}"
    else
        echo -e "${GREEN}Docker accessible without sudo${NC}"
    fi
}

# Function to check Docker Desktop version
check_docker_desktop() {
    local platform_info=$(run_with_privileges $DOCKER_CMD version --format '{{.Server.Platform.Name}}' 2>/dev/null)

    if [[ "$platform_info" == *"Docker Desktop"* ]]; then
        local desktop_version=$(run_with_privileges $DOCKER_CMD version --format '{{.Server.Platform.Name}}' | awk '{print $3}' 2>/dev/null)

        if [[ -z "$desktop_version" ]]; then
            echo -e "${YELLOW}Warning: Docker Desktop detected but could not determine version${NC}"
            return
        fi

        if [ "$(printf '%s\n' "$MIN_DESKTOP_VERSION" "$desktop_version" | sort -V | head -n1)" != "$MIN_DESKTOP_VERSION" ]; then
            echo -e "${RED}Error: Docker Desktop version $desktop_version is lower than required ($MIN_DESKTOP_VERSION)${NC}"
            exit 1
        else
            echo -e "${GREEN}Docker Desktop version $desktop_version - OK${NC}"
        fi
    else
        echo -e "${GREEN}Running Docker Engine (Docker Desktop not detected)${NC}"
    fi
}

# Check Docker version
check_docker_version() {
    local version
    version=$(run_with_privileges $DOCKER_CMD version --format '{{.Client.Version}}' | awk '{print $1}')

    if [ "$(printf '%s\n' "$MIN_DOCKER_VERSION" "$version" | sort -V | head -n1)" != "$MIN_DOCKER_VERSION" ]; then
        echo -e "${RED}Error: Docker version $version is lower than required ($MIN_DOCKER_VERSION)${NC}"
        exit 1
    fi
    echo -e "${GREEN}Docker version $version - OK${NC}"
}

# Check Docker Compose version
check_compose_version() {
    local version

    if command_exists "docker-compose"; then
        version=$(run_with_privileges docker-compose --version | grep -oP '\d+\.\d+\.\d+')

        if [[ "$version" =~ ^1 ]]; then
            echo -e "${RED}Error: Docker Compose V1 ($version) is not supported. Please upgrade to V2.${NC}"
            exit 1
        else
            COMPOSE_CMD="docker-compose"
            echo -e "${GREEN}Docker Compose V2 ($version) detected - OK${NC}"
        fi
    else
        COMPOSE_CMD="$DOCKER_CMD compose"
        version=$(run_with_privileges $COMPOSE_CMD version | grep -oP 'v?\d+\.\d+\.\d+')
        echo -e "${GREEN}Docker Compose V2 ($version) detected - OK${NC}"
    fi

    # Verify minimum version
    local clean_version=${version//v/}
    local clean_min_version=${MIN_COMPOSE_VERSION//v/}

    if [ "$(printf '%s\n' "$clean_min_version" "$clean_version" | sort -V | head -n1)" != "$clean_min_version" ]; then
        echo -e "${RED}Error: Docker Compose version $version is lower than required ($MIN_COMPOSE_VERSION)${NC}"
        exit 1
    fi
}

# Show spinner animation
show_spinner() {
    local delay=0.1
    local spinstr='|/-\'
    echo -n "$1 "
    while kill -0 "$!" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    echo "..."
}

# Wait for Zitadel to start
wait_for_zitadel_start() {
    until run_with_privileges $COMPOSE_CMD -f compose/compose.yaml logs zitadel 2>&1 | grep -q "http://localhost:8001/debug/healthz"; do
        sleep 1
    done
}

# Wait for CockroachDB to start
wait_for_cockroach_start() {
    local nodes=("roach1" "roach2" "roach3")
    local ready_message="awaiting \`cockroach init\` or join with an already initialized node"

    for node in "${nodes[@]}"; do
        until run_with_privileges $COMPOSE_CMD -f compose/compose.yaml logs "$node" 2>&1 | grep -q "$ready_message"; do
            sleep 1
        done
    done
}

# Initialize the environment
initialize() {
    run_with_privileges $DOCKER_CMD run --rm -it -v "$(pwd)":/app -w /app docker.io/cockroachdb/cockroach:v24.2.1 bash -c "
        cd compose/services/database && \
        cockroach cert create-ca --certs-dir=./ --ca-key=ca.key && \
        for node in roach1 roach2 roach3; do \
            cockroach cert create-node \$node roach-lb --certs-dir=./ --ca-key=ca.key && \
            mkdir -p node\${node: -1}/certs && mv node.* node\${node: -1}/certs; \
        done && \
        for client in root zitadel fury strife death war; do \
            cockroach cert create-client \$client --certs-dir=./ --ca-key=ca.key && \
            mkdir -p clients/\$client && mv client.* clients/\$client; \
        done && \
        chown 1000:1000 -R .
    "

    git submodule foreach 'cp .env.example .env'

    run_with_privileges $COMPOSE_CMD -f compose/compose.yaml up -d

    show_spinner "Waiting for CockroachDB to start" &
    wait_pid=$!
    wait_for_cockroach_start
    kill $wait_pid 2>/dev/null

    run_with_privileges $DOCKER_CMD exec -it compose-roach1-1 ./cockroach --host roach1:26357 init --certs-dir /run/secrets

    show_spinner "Waiting for Zitadel to start" &
    wait_pid=$!
    wait_for_zitadel_start
    kill $wait_pid 2>/dev/null
}

# Update client ID
update_client_id() {
    CLIENT_ID="$1"
    echo "Updating Client ID to: $CLIENT_ID"

    FILE=src/eireneon/.env
    [ ! -f "$FILE" ] && echo "Error: File $FILE not found" && exit 1

    grep -q "^NEXT_PUBLIC_CLIENT_ID=" "$FILE" &&
        sed -i "s/^NEXT_PUBLIC_CLIENT_ID=.*/NEXT_PUBLIC_CLIENT_ID=$CLIENT_ID/" "$FILE" ||
        echo "NEXT_PUBLIC_CLIENT_ID=$CLIENT_ID" >>"$FILE"

    for service in war fury strife death; do
        FILE="src/$service/.env"
        [ ! -f "$FILE" ] && echo "Warning: File $FILE not found" && continue

        grep -q "^AUDIENCE=" "$FILE" &&
            sed -i "s/^AUDIENCE=.*/AUDIENCE=$CLIENT_ID/" "$FILE" ||
            echo "AUDIENCE=$CLIENT_ID" >>"$FILE"
    done

    run_with_privileges $COMPOSE_CMD -f compose/compose.yaml up -d gateway fury death strife war eireneon --force-recreate --build
}

# Update service token
update_service_token() {
    TOKEN="$1"
    FILE="src/war/.env"

    [ ! -f "$FILE" ] && echo "Error: File $FILE not found" && exit 1

    echo "Updating service token in $FILE"
    grep -q "^SERVICE_TOKEN=" "$FILE" &&
        sed -i "s/^SERVICE_TOKEN=.*/SERVICE_TOKEN=$TOKEN/" "$FILE" ||
        echo "SERVICE_TOKEN=$TOKEN" >>"$FILE"

    echo "Verification:"
    grep "^SERVICE_TOKEN=" "$FILE"

    run_with_privileges $COMPOSE_CMD -f compose/compose.yaml up -d gateway war --force-recreate
}

# Main execution
check_dependencies_and_permissions
check_docker_version
check_docker_desktop
check_compose_version

case "$1" in
initialize)
    initialize
    ;;
update_client_id)
    [ -z "$2" ] && echo "Error: Missing client ID" && exit 1
    update_client_id "$2"
    ;;
update_service_token)
    [ -z "$2" ] && echo "Error: Missing token" && exit 1
    update_service_token "$2"
    ;;
*)
    echo "Usage: $0 {initialize|update_client_id <client_id>|update_service_token <token>}"
    exit 1
    ;;
esac