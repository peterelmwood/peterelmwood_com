#!/usr/bin/env bash

# Application deployment script for peterelmwood.com
# This script deploys the Docker application to the provisioned VM

set -o errexit
set -o nounset
set -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values
VM_NAME="${VM_NAME:-peterelmwood-web-vm}"
VM_ZONE="${VM_ZONE:-us-central1-a}"
SSH_USER="${SSH_USER:-ubuntu}"
APP_DIR="/opt/peterelmwood_com"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI is not installed"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    log_info "Prerequisites met"
}

setup_vm_access() {
    log_info "Setting up SSH access to VM..."
    
    # Ensure SSH keys are in gcloud
    gcloud compute config-ssh --quiet
    
    log_info "Testing SSH connection..."
    if ! gcloud compute ssh "${SSH_USER}@${VM_NAME}" --zone="${VM_ZONE}" --command="echo 'SSH connection successful'" 2>/dev/null; then
        log_error "Failed to connect to VM. Please check your VM is running and SSH is configured"
        exit 1
    fi
}

configure_docker_registry() {
    log_info "Configuring VM to access GCP Artifact Registry..."
    
    gcloud compute ssh "${SSH_USER}@${VM_NAME}" --zone="${VM_ZONE}" --command="
        set -e
        # Configure Docker to use gcloud for authentication
        gcloud auth configure-docker us-central1-docker.pkg.dev --quiet
        echo 'Docker registry configured'
    "
}

deploy_application() {
    log_info "Deploying application to VM..."
    
    # Get the latest image tag from GCP Artifact Registry
    local project_id
    project_id=$(gcloud config get-value project)
    local image_url="us-central1-docker.pkg.dev/${project_id}/peterelmwood/peterelmwood-com:latest"
    
    log_info "Using image: $image_url"
    
    # Copy docker-compose.prod.yml to VM
    log_info "Copying deployment files..."
    gcloud compute scp "${PROJECT_ROOT}/docker-compose.prod.yml" \
        "${SSH_USER}@${VM_NAME}:${APP_DIR}/docker-compose.yml" \
        --zone="${VM_ZONE}"
    
    # Deploy using docker compose
    log_info "Starting application containers..."
    gcloud compute ssh "${SSH_USER}@${VM_NAME}" --zone="${VM_ZONE}" --command="
        set -e
        cd ${APP_DIR}
        
        # Pull latest images
        docker compose pull
        
        # Stop existing containers
        docker compose down || true
        
        # Start containers
        docker compose up --detach
        
        # Run migrations
        docker compose exec --no-TTY web uv run python manage.py migrate
        
        # Collect static files
        docker compose exec --no-TTY web uv run python manage.py collectstatic --noinput
        
        echo 'Application deployed successfully'
    "
    
    log_info "Application deployment complete!"
}

show_logs() {
    log_info "Fetching application logs..."
    gcloud compute ssh "${SSH_USER}@${VM_NAME}" --zone="${VM_ZONE}" --command="
        cd ${APP_DIR}
        docker compose logs --tail=50
    "
}

show_status() {
    log_info "Checking application status..."
    gcloud compute ssh "${SSH_USER}@${VM_NAME}" --zone="${VM_ZONE}" --command="
        cd ${APP_DIR}
        docker compose ps
    "
}

restart_application() {
    log_info "Restarting application..."
    gcloud compute ssh "${SSH_USER}@${VM_NAME}" --zone="${VM_ZONE}" --command="
        cd ${APP_DIR}
        docker compose restart
    "
    log_info "Application restarted"
}

show_usage() {
    cat << EOF
Usage: $0 [COMMAND]

Commands:
    deploy      Deploy the application to the VM
    logs        Show application logs
    status      Show application status
    restart     Restart the application
    ssh         SSH into the VM
    help        Show this help message

Environment Variables:
    VM_NAME     Name of the VM instance (default: peterelmwood-web-vm)
    VM_ZONE     GCP zone (default: us-central1-a)
    SSH_USER    SSH username (default: ubuntu)

Examples:
    $0 deploy
    $0 logs
    $0 status
    VM_NAME=my-vm $0 deploy
EOF
}

# Main script
main() {
    local command="${1:-help}"
    
    case "$command" in
        deploy)
            check_prerequisites
            setup_vm_access
            configure_docker_registry
            deploy_application
            ;;
        logs)
            check_prerequisites
            show_logs
            ;;
        status)
            check_prerequisites
            show_status
            ;;
        restart)
            check_prerequisites
            restart_application
            ;;
        ssh)
            gcloud compute ssh "${SSH_USER}@${VM_NAME}" --zone="${VM_ZONE}"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
