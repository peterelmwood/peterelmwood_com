# peterelmwood_com

Personal website for Peter Elmwood, built with Django and Django REST Framework.

## Tech Stack

- **Backend**: Django 5.x with Django REST Framework
- **Database**: PostgreSQL (Cloud SQL)
- **Package Manager**: uv (Python package manager)
- **Static Files**: WhiteNoise (local), GCP Cloud Storage (production)
- **Containerization**: Docker
- **Deployment**: Google Cloud Run (serverless)
- **CI/CD**: GitHub Actions
- **Cloud**: Google Cloud Platform (GCP)

## Project Structure

```
peterelmwood_com/
├── config/                     # Django configuration
│   ├── settings/
│   │   ├── __init__.py
│   │   ├── base.py            # Base settings
│   │   ├── local.py           # Local development settings
│   │   └── production.py      # Production settings
│   ├── urls.py
│   ├── wsgi.py
│   └── asgi.py
├── scripts/
│   └── deploy_cloudrun.sh     # Cloud Run deployment script
├── .github/
│   └── workflows/
│       └── deploy.yml         # CI/CD workflow
├── cloud-run-service.yaml     # Cloud Run service configuration
├── docker-compose.yml         # Local development
├── docker-compose.prod.yml    # Production deployment
├── Dockerfile
├── pyproject.toml             # Python dependencies (uv)
└── manage.py
```

## Getting Started

### Prerequisites

- Docker and Docker Compose
- uv (optional, for local development without Docker)

### Local Development with Docker

1. Clone the repository:
   ```bash
   git clone https://github.com/peterelmwood/peterelmwood_com.git
   cd peterelmwood_com
   ```

2. Start the development environment:
   ```bash
   docker compose up --build
   ```

3. Run migrations:
   ```bash
   docker compose exec web uv run python manage.py migrate
   ```

4. Create a superuser:
   ```bash
   docker compose exec web uv run python manage.py createsuperuser
   ```

5. Access the application at http://localhost:8000

### Local Development without Docker

1. Install uv:
   ```bash
   pip install uv
   ```

2. Install dependencies:
   ```bash
   uv sync
   ```

3. Create a `.env` file from the example:
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

4. Run migrations:
   ```bash
   uv run python manage.py migrate
   ```

5. Start the development server:
   ```bash
   uv run python manage.py runserver
   ```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SECRET_KEY` | Django secret key | Required |
| `DEBUG` | Debug mode | `False` |
| `ALLOWED_HOSTS` | Comma-separated list of allowed hosts | `[]` |
| `DATABASE_URL` | PostgreSQL connection URL | Required |
| `GS_BUCKET_NAME` | GCP Storage bucket name | Optional |
| `GS_CREDENTIALS_FILE` | Path to GCP credentials JSON | `/secrets/gcp-credentials.json` |

## Production Deployment

The application is deployed to **Google Cloud Run**, a fully managed serverless platform that:
- Scales automatically from zero to handle traffic
- Only charges for actual usage (pay-per-request)
- Provides automatic HTTPS and custom domains
- Ideal for low to moderate traffic applications

### Prerequisites

1. **GCP Account** with billing enabled
2. **GCP Project** created
3. **Required APIs enabled**:
   - Cloud Run API
   - Artifact Registry API
   - Cloud SQL Admin API (for database)
   - Secret Manager API

### Initial Setup

#### 1. Create GCP Resources

```bash
# Set your project ID
export GCP_PROJECT_ID="your-project-id"
export GCP_REGION="us-central1"

# Enable required APIs
gcloud services enable run.googleapis.com \
  artifactregistry.googleapis.com \
  sqladmin.googleapis.com \
  secretmanager.googleapis.com \
  --project=$GCP_PROJECT_ID

# Create Artifact Registry repository
gcloud artifacts repositories create peterelmwood \
  --repository-format=docker \
  --location=$GCP_REGION \
  --project=$GCP_PROJECT_ID
```

#### 2. Create Secrets

Create the required secrets in Google Secret Manager:

```bash
# Django secret key
echo -n "your-django-secret-key" | gcloud secrets create django-secret-key \
  --data-file=- \
  --project=$GCP_PROJECT_ID

# Database URL (format: postgresql://user:password@/dbname?host=/cloudsql/project:region:instance)
echo -n "your-database-url" | gcloud secrets create database-url \
  --data-file=- \
  --project=$GCP_PROJECT_ID

# GCS bucket name
echo -n "your-bucket-name" | gcloud secrets create gcs-bucket-name \
  --data-file=- \
  --project=$GCP_PROJECT_ID
```

#### 3. Create Service Account

```bash
# Create service account for Cloud Run
gcloud iam service-accounts create cloud-run-sa \
  --display-name="Cloud Run Service Account" \
  --project=$GCP_PROJECT_ID

# Grant necessary permissions
gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:cloud-run-sa@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:cloud-run-sa@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:cloud-run-sa@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### Manual Deployment

Use the deployment script for manual deployments:

```bash
# Initial setup (run once)
GCP_PROJECT_ID=your-project-id ./scripts/deploy_cloudrun.sh setup

# Deploy application
GCP_PROJECT_ID=your-project-id ./scripts/deploy_cloudrun.sh deploy

# View service URL
GCP_PROJECT_ID=your-project-id ./scripts/deploy_cloudrun.sh url

# View logs
GCP_PROJECT_ID=your-project-id ./scripts/deploy_cloudrun.sh logs
```

### Automated Deployment (CI/CD)

The application automatically deploys to Cloud Run when code is pushed to the `main` branch.

### GitHub Repository Secrets

Set the following secrets in your GitHub repository (Settings → Secrets and variables → Actions):

- `GCP_SERVICE_ACCOUNT_KEY`: GCP service account JSON key with the following roles:
  - Artifact Registry Writer
  - Cloud Run Admin
  - Service Account User
  - Secret Manager Secret Accessor

### GitHub Repository Variables

Set the following variables in your GitHub repository (Settings → Secrets and variables → Actions → Variables):

- `GCP_PROJECT_ID`: Your GCP project ID
- `GCP_REGION`: GCP region (e.g., `us-central1`)
- `GCP_ARTIFACT_REPO`: Artifact Registry repository name (e.g., `peterelmwood`)

### Deployment Workflow

The deployment workflow triggers on push to the `main` branch:

1. **Version Increment**: Automatically increments the patch version and creates a git tag
2. **Build & Push**: Builds the Docker image and pushes to GCP Artifact Registry
3. **Deploy to Cloud Run**: Deploys the latest image to Cloud Run with zero-downtime rolling update

### Cost Estimation

Cloud Run pricing is pay-per-use with a generous free tier:

**Free Tier (per month)**:
- 2 million requests
- 360,000 GB-seconds of memory
- 180,000 vCPU-seconds

**Typical costs for low-traffic site**:
- ~$0-5/month (within free tier for most personal sites)
- Cloud SQL: ~$10-20/month (if using smallest instance)
- Cloud Storage: ~$0.02/GB/month

**Total estimated cost**: $10-25/month (vs $30-35/month for VM)

## API Documentation

The REST API is available at `/api/` (to be implemented).

## License

MIT License - see [LICENSE](LICENSE) for details.

