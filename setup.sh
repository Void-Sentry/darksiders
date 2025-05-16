#!/bin/sh

# Minimum required versions
MIN_DOCKER_VERSION="28.0.4"
MIN_COMPOSE_VERSION="v2.34.0"
MIN_DESKTOP_VERSION="4.40.0"

# Colors for messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_dependencies() {
  local missing=()

  for cmd in git bash less sh docker grep sed awk sort; do
    if ! command -v $cmd &>/dev/null; then
      missing+=("$cmd")
    fi
  done

  if [ ${#missing[@]} -ne 0 ]; then
    echo -e "${RED}Error: Missing dependencies:${NC} ${missing[*]}"
    echo -e "\nInstall with:"

    if command -v apt &>/dev/null; then
      echo "sudo apt install ${missing[*]}"
    elif command -v yum &>/dev/null; then
      echo "sudo yum install ${missing[*]}"
    elif command -v pacman &>/dev/null; then
      echo "sudo pacman -S ${missing[*]}"
    else
      echo "Please install manually: ${missing[*]}"
    fi
    exit 1
  fi

  if ! { docker compose version &>/dev/null || command -v docker-compose &>/dev/null; }; then
    echo -e "${RED}Error: Docker Compose V2 is required${NC}"
    echo "Install with:"
    echo "  https://docs.docker.com/compose/install/"
    exit 1
  fi
}

# Function to check Docker Desktop version
check_docker_desktop() {
  local platform_info=$(docker version --format '{{.Server.Platform.Name}}' 2>/dev/null)

  if [[ "$platform_info" == *"Docker Desktop"* ]]; then
    local desktop_version=$(docker version --format '{{.Server.Platform.Name}}' | awk '{print $3}' 2>/dev/null)

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

# Check if commands need sudo
check_sudo_requirement() {
  if docker info &>/dev/null; then
    echo -e "${GREEN}Docker can run without sudo${NC}"
    DOCKER_CMD="docker"
  elif sudo docker info &>/dev/null; then
    echo -e "${YELLOW}Warning: Docker requires sudo${NC}"
    DOCKER_CMD="sudo docker"
  else
    echo -e "${RED}Error: Docker is not installed or not running${NC}"
    exit 1
  fi
}

# Check Docker version
check_docker_version() {
  local version
  version=$($DOCKER_CMD version --format '{{.Client.Version}}' | awk '{print $1}')

  if [ "$(printf '%s\n' "$MIN_DOCKER_VERSION" "$version" | sort -V | head -n1)" != "$MIN_DOCKER_VERSION" ]; then
    echo -e "${RED}Error: Docker version $version is lower than required ($MIN_DOCKER_VERSION)${NC}"
    exit 1
  fi
  echo -e "${GREEN}Docker version $version - OK${NC}"
}

# Check Docker Compose version
check_compose_version() {
  # Try docker compose (v2) first
  if command -v docker-compose &>/dev/null; then
    local version
    version=$(docker-compose --version | grep -oP '\d+\.\d+\.\d+')

    if [[ "$version" =~ ^1 ]]; then
      echo -e "${RED}Error: Docker Compose V1 ($version) is not supported. Please upgrade to V2.${NC}"
      exit 1
    else
      COMPOSE_CMD="docker-compose"
      echo -e "${GREEN}Docker Compose V2 ($version) detected - OK${NC}"
    fi
  elif $DOCKER_CMD compose version &>/dev/null; then
    COMPOSE_CMD="$DOCKER_CMD compose"
    version=$($COMPOSE_CMD version | grep -oP 'v?\d+\.\d+\.\d+')
    echo -e "${GREEN}Docker Compose V2 ($version) detected - OK${NC}"
  else
    echo -e "${RED}Error: Docker Compose is not installed${NC}"
    exit 1
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
  until $COMPOSE_CMD -f compose/compose.yaml logs zitadel 2>&1 | grep -q "http://localhost:8001/debug/healthz"; do
    sleep 1
  done
}

# Wait for CockroachDB to start
wait_for_cockroach_start() {
  local nodes=("roach1" "roach2" "roach3")
  local ready_message="awaiting \`cockroach init\` or join with an already initialized node"

  for node in "${nodes[@]}"; do
    until $COMPOSE_CMD -f compose/compose.yaml logs "$node" 2>&1 | grep -q "$ready_message"; do
      sleep 1
    done
  done
}

# Initialize the environment
initialize() {
  $DOCKER_CMD run --rm -it -v "$(pwd)":/app -w /app docker.io/cockroachdb/cockroach:v24.2.1 bash -c "
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

  $COMPOSE_CMD -f compose/compose.yaml up -d

  show_spinner "Waiting for CockroachDB to start" &
  wait_pid=$!
  wait_for_cockroach_start
  kill $wait_pid 2>/dev/null

  $DOCKER_CMD exec -it compose-roach1-1 ./cockroach --host roach1:26357 init --certs-dir /run/secrets

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

  $COMPOSE_CMD -f compose/compose.yaml up -d gateway fury death strife war eireneon --force-recreate --build
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

  $COMPOSE_CMD -f compose/compose.yaml up -d gateway war --force-recreate
}

check_dependencies
check_sudo_requirement
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
