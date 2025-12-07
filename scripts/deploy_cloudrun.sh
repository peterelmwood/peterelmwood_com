#!/usr/bin/env bash

# Cloud Run deployment script for peterelmwood.com
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

# Default values - override with environment variables
PROJECT_ID="${GCP_PROJECT_ID:-}"
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="${SERVICE_NAME:-peterelmwood-com}"
ARTIFACT_REPO="${GCP_ARTIFACT_REPO:-peterelmwood}"

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
        log_error "gcloud CLI is not installed. Install from https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    
    if [ -z "$PROJECT_ID" ]; then
        PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
        if [ -z "$PROJECT_ID" ]; then
            log_error "GCP_PROJECT_ID not set and no default project configured"
            exit 1
        fi
    fi
    
    log_info "Using project: $PROJECT_ID"
    log_info "Using region: $REGION"
}

enable_apis() {
    log_info "Enabling required GCP APIs..."
    
    gcloud services enable \
        run.googleapis.com \
        artifactregistry.googleapis.com \
        sqladmin.googleapis.com \
        secretmanager.googleapis.com \
        --project="$PROJECT_ID"
    
    log_info "APIs enabled successfully"
}

create_secrets() {
    log_info "Checking secrets..."
    
    # List of required secrets
    REQUIRED_SECRETS=(
        "django-secret-key"
        "database-url"
        "gcs-bucket-name"
    )
    
    for secret in "${REQUIRED_SECRETS[@]}"; do
        if ! gcloud secrets describe "$secret" --project="$PROJECT_ID" &>/dev/null; then
            log_warn "Secret '$secret' does not exist. Please create it:"
            echo "  gcloud secrets create $secret --project=$PROJECT_ID"
            echo "  echo -n 'your-secret-value' | gcloud secrets versions add $secret --data-file=- --project=$PROJECT_ID"
        else
            log_info "Secret '$secret' exists"
        fi
    done
}

setup_service_account() {
    log_info "Setting up Cloud Run service account..."
    
    SERVICE_ACCOUNT="cloud-run-sa@${PROJECT_ID}.iam.gserviceaccount.com"
    
    # Create service account if it doesn't exist
    if ! gcloud iam service-accounts describe "$SERVICE_ACCOUNT" --project="$PROJECT_ID" &>/dev/null; then
        gcloud iam service-accounts create cloud-run-sa \
            --display-name="Cloud Run Service Account" \
            --project="$PROJECT_ID"
        log_info "Created service account: $SERVICE_ACCOUNT"
    else
        log_info "Service account already exists: $SERVICE_ACCOUNT"
    fi
    
    # Grant necessary permissions
    log_info "Granting permissions to service account..."
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SERVICE_ACCOUNT" \
        --role="roles/cloudsql.client"
    
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SERVICE_ACCOUNT" \
        --role="roles/storage.objectAdmin"
    
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SERVICE_ACCOUNT" \
        --role="roles/secretmanager.secretAccessor"
}

deploy_to_cloud_run() {
    log_info "Deploying to Cloud Run..."
    
    IMAGE_URL="${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPO}/${SERVICE_NAME}:latest"
    
    log_info "Using image: $IMAGE_URL"
    
    gcloud run deploy "$SERVICE_NAME" \
        --image="$IMAGE_URL" \
        --platform=managed \
        --region="$REGION" \
        --allow-unauthenticated \
        --min-instances=0 \
        --max-instances=10 \
        --cpu=1 \
        --memory=512Mi \
        --timeout=300 \
        --concurrency=80 \
        --port=8000 \
        --service-account="cloud-run-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
        --set-env-vars="DJANGO_SETTINGS_MODULE=config.settings.production,DEBUG=False,ALLOWED_HOSTS=*,SECURE_SSL_REDIRECT=True" \
        --set-secrets="SECRET_KEY=django-secret-key:latest,DATABASE_URL=database-url:latest,GS_BUCKET_NAME=gcs-bucket-name:latest" \
        --project="$PROJECT_ID"
    
    log_info "Deployment complete!"
}

run_migrations() {
    log_info "Running database migrations..."
    
    # Run migrations using Cloud Run Jobs or gcloud run jobs execute
    log_warn "Manual migration step required:"
    echo "  gcloud run jobs create ${SERVICE_NAME}-migrate \\"
    echo "    --image=${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPO}/${SERVICE_NAME}:latest \\"
    echo "    --region=$REGION \\"
    echo "    --command=uv,run,python,manage.py,migrate \\"
    echo "    --set-secrets=SECRET_KEY=django-secret-key:latest,DATABASE_URL=database-url:latest \\"
    echo "    --project=$PROJECT_ID"
    echo ""
    echo "  gcloud run jobs execute ${SERVICE_NAME}-migrate --region=$REGION --project=$PROJECT_ID"
}

show_service_url() {
    log_info "Fetching service URL..."
    
    SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" \
        --region="$REGION" \
        --project="$PROJECT_ID" \
        --format="value(status.url)")
    
    log_info "Service deployed at: $SERVICE_URL"
}

show_usage() {
    cat << EOF
Usage: $0 [COMMAND]

Commands:
    setup       Initial setup (enable APIs, create service account)
    deploy      Deploy application to Cloud Run
    full        Run setup and deploy
    url         Show service URL
    logs        Show service logs
    help        Show this help message

Environment Variables:
    GCP_PROJECT_ID      GCP Project ID (required)
    GCP_REGION          GCP region (default: us-central1)
    GCP_ARTIFACT_REPO   Artifact Registry repo (default: peterelmwood)
    SERVICE_NAME        Cloud Run service name (default: peterelmwood-com)

Examples:
    GCP_PROJECT_ID=my-project $0 setup
    GCP_PROJECT_ID=my-project $0 deploy
    GCP_PROJECT_ID=my-project GCP_REGION=us-east1 $0 full
EOF
}

# Main script
main() {
    local command="${1:-help}"
    
    case "$command" in
        setup)
            check_prerequisites
            enable_apis
            create_secrets
            setup_service_account
            ;;
        deploy)
            check_prerequisites
            deploy_to_cloud_run
            run_migrations
            show_service_url
            ;;
        full)
            check_prerequisites
            enable_apis
            create_secrets
            setup_service_account
            deploy_to_cloud_run
            run_migrations
            show_service_url
            ;;
        url)
            check_prerequisites
            show_service_url
            ;;
        logs)
            check_prerequisites
            gcloud run services logs read "$SERVICE_NAME" \
                --region="$REGION" \
                --project="$PROJECT_ID" \
                --limit=100
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
