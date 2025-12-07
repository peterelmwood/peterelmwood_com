#!/usr/bin/env bash

# Terraform deployment script for peterelmwood.com VM
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
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"

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
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install it from https://www.terraform.io/downloads"
        exit 1
    fi
    
    # Check if gcloud is installed
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI is not installed. Please install it from https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    
    # Check if terraform.tfvars exists
    if [ ! -f "${TERRAFORM_DIR}/terraform.tfvars" ]; then
        log_error "terraform.tfvars not found. Please create it from terraform.tfvars.example"
        exit 1
    fi
    
    log_info "All prerequisites met"
}

authenticate_gcloud() {
    log_info "Authenticating with Google Cloud..."
    
    # Check if already authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
        log_warn "Not authenticated. Running gcloud auth login..."
        gcloud auth login
    fi
    
    # Set the project
    local project_id
    project_id=$(grep "^project_id" "${TERRAFORM_DIR}/terraform.tfvars" | cut -d '"' -f 2)
    
    if [ -n "$project_id" ]; then
        gcloud config set project "$project_id"
        log_info "Set project to: $project_id"
    fi
}

terraform_init() {
    log_info "Initializing Terraform..."
    cd "${TERRAFORM_DIR}"
    terraform init
}

terraform_plan() {
    log_info "Running Terraform plan..."
    cd "${TERRAFORM_DIR}"
    terraform plan -out=tfplan
    
    log_warn "Review the plan above. Continue with apply? (yes/no)"
    read -r response
    if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Deployment cancelled"
        exit 0
    fi
}

terraform_apply() {
    log_info "Applying Terraform configuration..."
    cd "${TERRAFORM_DIR}"
    terraform apply tfplan
    rm -f tfplan
    
    log_info "Deployment complete!"
    log_info "Fetching outputs..."
    terraform output
}

terraform_destroy() {
    log_warn "This will destroy all infrastructure. Are you sure? (yes/no)"
    read -r response
    if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Destroy cancelled"
        exit 0
    fi
    
    log_info "Destroying infrastructure..."
    cd "${TERRAFORM_DIR}"
    terraform destroy
}

show_usage() {
    cat << EOF
Usage: $0 [COMMAND]

Commands:
    deploy      Deploy the infrastructure (init, plan, apply)
    plan        Run Terraform plan only
    apply       Apply Terraform changes
    destroy     Destroy the infrastructure
    output      Show Terraform outputs
    help        Show this help message

Examples:
    $0 deploy
    $0 plan
    $0 destroy
EOF
}

# Main script
main() {
    local command="${1:-help}"
    
    case "$command" in
        deploy)
            check_prerequisites
            authenticate_gcloud
            terraform_init
            terraform_plan
            terraform_apply
            ;;
        plan)
            check_prerequisites
            authenticate_gcloud
            terraform_init
            terraform_plan
            ;;
        apply)
            check_prerequisites
            authenticate_gcloud
            terraform_init
            terraform_apply
            ;;
        destroy)
            check_prerequisites
            authenticate_gcloud
            terraform_init
            terraform_destroy
            ;;
        output)
            cd "${TERRAFORM_DIR}"
            terraform output
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
