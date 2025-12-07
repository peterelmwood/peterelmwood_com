# Pre-Launch Checklist

This document outlines all requirements that must be completed before successfully deploying the application to Cloud Run.

## Required GCP Resources

### 1. GCP Project
- [ ] Create GCP project or use existing one
- [ ] Enable billing on the project
- [ ] Note your `PROJECT_ID` for configuration

### 2. Required APIs

Enable these APIs in your GCP project:

```bash
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  sqladmin.googleapis.com \
  secretmanager.googleapis.com \
  storage.googleapis.com \
  --project=YOUR_PROJECT_ID
```

- [ ] Cloud Run API
- [ ] Artifact Registry API  
- [ ] Cloud SQL Admin API
- [ ] Secret Manager API
- [ ] Cloud Storage API

### 3. Artifact Registry Repository

Create a Docker repository for storing container images:

```bash
gcloud artifacts repositories create peterelmwood \
  --repository-format=docker \
  --location=us-central1 \
  --project=YOUR_PROJECT_ID
```

- [ ] Artifact Registry repository created
- [ ] Note repository name (default: `peterelmwood`)

### 4. Cloud SQL PostgreSQL Instance

Create and configure a PostgreSQL database:

```bash
# Create Cloud SQL instance
gcloud sql instances create peterelmwood-db \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=us-central1 \
  --project=YOUR_PROJECT_ID

# Create database
gcloud sql databases create peterelmwood_db \
  --instance=peterelmwood-db \
  --project=YOUR_PROJECT_ID

# Create database user
gcloud sql users create dbuser \
  --instance=peterelmwood-db \
  --password=YOUR_SECURE_PASSWORD \
  --project=YOUR_PROJECT_ID
```

- [ ] Cloud SQL instance created
- [ ] Database created
- [ ] Database user created with secure password
- [ ] Note connection details:
  - Instance connection name: `PROJECT_ID:REGION:INSTANCE_NAME`
  - Database name: `peterelmwood_db`
  - Username: `dbuser`
  - Password: (stored securely)

### 5. Cloud Storage Bucket

Create a bucket for media/static files:

```bash
gcloud storage buckets create gs://peterelmwood-media \
  --location=us-central1 \
  --project=YOUR_PROJECT_ID
```

- [ ] Cloud Storage bucket created
- [ ] Note bucket name (e.g., `peterelmwood-media`)

### 6. Service Account for Cloud Run

Create service account with necessary permissions:

```bash
# Create service account
gcloud iam service-accounts create cloud-run-sa \
  --display-name="Cloud Run Service Account" \
  --project=YOUR_PROJECT_ID

# Grant Cloud SQL Client role
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:cloud-run-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"

# Grant Storage Object Admin role
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:cloud-run-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

# Grant Secret Manager Secret Accessor role
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:cloud-run-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

- [ ] Service account `cloud-run-sa` created
- [ ] Cloud SQL Client role granted
- [ ] Storage Object Admin role granted
- [ ] Secret Manager Secret Accessor role granted

## Required Secrets in Google Secret Manager

Create these secrets in Google Secret Manager. The Cloud Run deployment references these secrets.

### 1. Django Secret Key

```bash
# Generate a secure secret key
python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'

# Create secret
echo -n "your-generated-secret-key-here" | gcloud secrets create django-secret-key \
  --data-file=- \
  --project=YOUR_PROJECT_ID

# Grant access to service account
gcloud secrets add-iam-policy-binding django-secret-key \
  --member="serviceAccount:cloud-run-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --project=YOUR_PROJECT_ID
```

- [ ] Secret `django-secret-key` created
- [ ] Service account has access to secret

**Purpose**: Django's SECRET_KEY for cryptographic signing, session management, and security features.

### 2. Database URL

Format: `postgres://USERNAME:PASSWORD@/DATABASE?host=/cloudsql/PROJECT_ID:REGION:INSTANCE_NAME`

Example: `postgres://dbuser:mypassword@/peterelmwood_db?host=/cloudsql/my-project:us-central1:peterelmwood-db`

```bash
# Create secret with your actual database connection string
echo -n "postgres://dbuser:YOUR_PASSWORD@/peterelmwood_db?host=/cloudsql/YOUR_PROJECT:us-central1:peterelmwood-db" | \
  gcloud secrets create database-url \
  --data-file=- \
  --project=YOUR_PROJECT_ID

# Grant access to service account
gcloud secrets add-iam-policy-binding database-url \
  --member="serviceAccount:cloud-run-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --project=YOUR_PROJECT_ID
```

- [ ] Secret `database-url` created with correct connection string
- [ ] Service account has access to secret

**Purpose**: PostgreSQL database connection string for Django's database backend.

### 3. GCS Bucket Name

```bash
# Create secret with your bucket name
echo -n "peterelmwood-media" | gcloud secrets create gcs-bucket-name \
  --data-file=- \
  --project=YOUR_PROJECT_ID

# Grant access to service account
gcloud secrets add-iam-policy-binding gcs-bucket-name \
  --member="serviceAccount:cloud-run-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --project=YOUR_PROJECT_ID
```

- [ ] Secret `gcs-bucket-name` created
- [ ] Service account has access to secret

**Purpose**: Google Cloud Storage bucket name for storing media files and user uploads.

## GitHub Configuration

### GitHub Secrets

Configure in GitHub repository: Settings → Secrets and variables → Actions → Secrets

#### 1. GCP_SERVICE_ACCOUNT_KEY

Create a service account key for GitHub Actions deployments:

```bash
# Create service account for GitHub Actions
gcloud iam service-accounts create github-actions-sa \
  --display-name="GitHub Actions Service Account" \
  --project=YOUR_PROJECT_ID

# Grant necessary roles
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

# Create and download key
gcloud iam service-accounts keys create github-actions-key.json \
  --iam-account=github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com \
  --project=YOUR_PROJECT_ID
```

- [ ] GitHub Actions service account created
- [ ] Roles granted: Artifact Registry Writer, Cloud Run Admin, Service Account User
- [ ] Service account key JSON downloaded
- [ ] Key added to GitHub as secret `GCP_SERVICE_ACCOUNT_KEY` (paste entire JSON content)

**Purpose**: Authenticates GitHub Actions to deploy to GCP (build Docker images, push to Artifact Registry, deploy to Cloud Run).

**Required Roles**:
- `roles/artifactregistry.writer` - Push Docker images to Artifact Registry
- `roles/run.admin` - Deploy and manage Cloud Run services
- `roles/iam.serviceAccountUser` - Act as the Cloud Run service account

### GitHub Variables

Configure in GitHub repository: Settings → Secrets and variables → Actions → Variables

- [ ] `GCP_PROJECT_ID` = Your GCP project ID (e.g., `my-project-123`)
- [ ] `GCP_REGION` = GCP region (e.g., `us-central1`)
- [ ] `GCP_ARTIFACT_REPO` = Artifact Registry repository name (e.g., `peterelmwood`)

**Purpose**: Non-sensitive configuration values used in GitHub Actions workflow.

## Database Migrations

After first deployment, run migrations to set up database schema:

```bash
# Create migration job
gcloud run jobs create peterelmwood-com-migrate \
  --image=us-central1-docker.pkg.dev/YOUR_PROJECT_ID/peterelmwood/peterelmwood-com:latest \
  --region=us-central1 \
  --command=uv,run,python,manage.py,migrate \
  --set-secrets=SECRET_KEY=django-secret-key:latest,DATABASE_URL=database-url:latest \
  --set-cloudsql-instances=YOUR_PROJECT_ID:us-central1:peterelmwood-db \
  --service-account=cloud-run-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com \
  --project=YOUR_PROJECT_ID

# Execute migration
gcloud run jobs execute peterelmwood-com-migrate \
  --region=us-central1 \
  --project=YOUR_PROJECT_ID
```

- [ ] Migration job created
- [ ] Initial migrations executed successfully

## Optional: Create Django Superuser

After migrations, create an admin user:

```bash
# Create a one-off job to create superuser
gcloud run jobs create peterelmwood-com-createsuperuser \
  --image=us-central1-docker.pkg.dev/YOUR_PROJECT_ID/peterelmwood/peterelmwood-com:latest \
  --region=us-central1 \
  --command=uv,run,python,manage.py,createsuperuser,--noinput,--username=admin,--email=admin@example.com \
  --set-secrets=SECRET_KEY=django-secret-key:latest,DATABASE_URL=database-url:latest,DJANGO_SUPERUSER_PASSWORD=django-superuser-password:latest \
  --set-cloudsql-instances=YOUR_PROJECT_ID:us-central1:peterelmwood-db \
  --service-account=cloud-run-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com \
  --project=YOUR_PROJECT_ID

# Note: Create django-superuser-password secret first
echo -n "your-admin-password" | gcloud secrets create django-superuser-password \
  --data-file=- \
  --project=YOUR_PROJECT_ID
```

- [ ] Superuser created (optional)

## Production Configuration

### Update ALLOWED_HOSTS

After initial deployment, configure allowed hosts for your domain:

```bash
gcloud run services update peterelmwood-com \
  --update-env-vars="ALLOWED_HOSTS=peterelmwood.com,www.peterelmwood.com" \
  --region=us-central1 \
  --project=YOUR_PROJECT_ID
```

- [ ] ALLOWED_HOSTS configured with actual domain(s)

### Custom Domain Setup (Optional)

```bash
gcloud run domain-mappings create \
  --service=peterelmwood-com \
  --domain=peterelmwood.com \
  --region=us-central1 \
  --project=YOUR_PROJECT_ID
```

- [ ] Custom domain mapped to Cloud Run service
- [ ] DNS records updated to point to Cloud Run

## Verification Checklist

Before going live, verify:

- [ ] Cloud Run service is deployed and running
- [ ] Application responds to HTTP requests
- [ ] Database connection successful (check logs)
- [ ] Static files loading correctly
- [ ] Admin interface accessible (`/admin`)
- [ ] HTTPS certificate active
- [ ] Monitoring and logging configured
- [ ] Cost alerts set up in GCP billing

## Summary of Required Secrets

| Secret Name | Purpose | Format Example |
|------------|---------|----------------|
| `django-secret-key` | Django cryptographic signing | `abcd1234...` (50+ random chars) |
| `database-url` | PostgreSQL connection | `postgres://user:pass@/db?host=/cloudsql/proj:region:inst` |
| `gcs-bucket-name` | Cloud Storage bucket | `peterelmwood-media` |

## Summary of GitHub Configuration

### Secrets
| Secret Name | Purpose | Content |
|------------|---------|---------|
| `GCP_SERVICE_ACCOUNT_KEY` | GitHub Actions authentication | JSON key file content |

### Variables
| Variable Name | Purpose | Example Value |
|--------------|---------|---------------|
| `GCP_PROJECT_ID` | GCP project identifier | `my-project-123` |
| `GCP_REGION` | Deployment region | `us-central1` |
| `GCP_ARTIFACT_REPO` | Docker registry name | `peterelmwood` |

## Cost Estimates

Expected monthly costs with current configuration:

- **Cloud Run**: $0-5/month (likely free tier with 0-2 instances)
- **Cloud SQL (db-f1-micro)**: ~$7-10/month
- **Cloud Storage**: ~$0.02/GB/month
- **Artifact Registry**: ~$0.10/GB/month

**Total estimated**: $10-20/month for low-traffic site

## Support & Troubleshooting

If deployment fails, check:

1. All secrets exist and are accessible: `gcloud secrets list --project=YOUR_PROJECT_ID`
2. Service account has all required roles
3. APIs are enabled: `gcloud services list --enabled --project=YOUR_PROJECT_ID`
4. Cloud Run logs: `gcloud run services logs read peterelmwood-com --region=us-central1`
5. Database connectivity from Cloud Run service

For detailed troubleshooting, see `SETUP.md`.
