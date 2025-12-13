#!/bin/bash
# Single script to start and stop the monitoring stack

set -e

COMPOSE_FILE="docker-compose.monitoring.yml"
ENV_FILE="monitoring.env"
STACK_NAME="${STACK_NAME:-monitoring}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null && ! command -v docker &> /dev/null; then
    print_error "Docker Compose is not installed!"
    exit 1
fi

# Use docker compose (v2) if available, otherwise docker-compose (v1)
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
elif docker-compose version &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    print_error "Docker Compose is not available!"
    exit 1
fi

# Function to start the stack
start_stack() {
    print_info "Starting monitoring stack..."
    
    if [ ! -f "$COMPOSE_FILE" ]; then
        print_error "Compose file not found: $COMPOSE_FILE"
        exit 1
    fi
    
    if [ ! -f "$ENV_FILE" ]; then
        print_warn "Environment file not found: $ENV_FILE (using defaults)"
    fi
    
    $DOCKER_COMPOSE -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d
    
    if [ $? -eq 0 ]; then
        print_info "Stack started successfully!"
        print_info "Waiting for services to be healthy..."
        sleep 5
        
        # Show status
        $DOCKER_COMPOSE -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps
        
        echo ""
        print_info "Access Grafana at: http://localhost:3200"
        print_info "Access Prometheus at: http://localhost:9090"
        print_info "Access Loki at: http://localhost:13100"
        if [ -n "${NGINX_PORT:-}" ]; then
            print_info "Access via Nginx at: http://localhost:${NGINX_PORT}"
        fi
    else
        print_error "Failed to start stack!"
        exit 1
    fi
}

# Function to stop the stack
stop_stack() {
    print_info "Stopping monitoring stack..."
    
    $DOCKER_COMPOSE -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down
    
    if [ $? -eq 0 ]; then
        print_info "Stack stopped successfully!"
    else
        print_error "Failed to stop stack!"
        exit 1
    fi
}

# Function to restart the stack
restart_stack() {
    print_info "Restarting monitoring stack..."
    stop_stack
    sleep 2
    start_stack
}

# Function to show status
status_stack() {
    print_info "Monitoring stack status:"
    $DOCKER_COMPOSE -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps
}

# Function to show logs
logs_stack() {
    if [ -n "$1" ]; then
        $DOCKER_COMPOSE -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs -f "$1"
    else
        $DOCKER_COMPOSE -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs -f
    fi
}

# Main script logic
case "${1:-}" in
    start)
        start_stack
        ;;
    stop)
        stop_stack
        ;;
    restart)
        restart_stack
        ;;
    status)
        status_stack
        ;;
    logs)
        logs_stack "$2"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs [service]}"
        echo ""
        echo "Commands:"
        echo "  start   - Start the monitoring stack"
        echo "  stop    - Stop the monitoring stack"
        echo "  restart - Restart the monitoring stack"
        echo "  status  - Show stack status"
        echo "  logs    - Show logs (optionally for a specific service)"
        echo ""
        echo "Examples:"
        echo "  $0 start"
        echo "  $0 stop"
        echo "  $0 restart"
        echo "  $0 status"
        echo "  $0 logs"
        echo "  $0 logs grafana"
        exit 1
        ;;
esac

