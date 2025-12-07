# Cloud Run Deployment - Quick Reference

## Prerequisites Checklist

- [ ] GCP account with billing enabled
- [ ] GCP project created
- [ ] gcloud CLI installed and configured
- [ ] Docker installed locally (for testing)

## Setup Steps

### 1. Install and Configure gcloud CLI

```bash
# Install gcloud (if not already installed)
# See: https://cloud.google.com/sdk/docs/install

# Login and set project
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

### 2. Enable Required APIs

```bash
export GCP_PROJECT_ID="your-project-id"
export GCP_REGION="us-central1"

gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  sqladmin.googleapis.com \
  secretmanager.googleapis.com \
  --project=$GCP_PROJECT_ID
```

### 3. Create Artifact Registry

```bash
gcloud artifacts repositories create peterelmwood \
  --repository-format=docker \
  --location=$GCP_REGION \
  --project=$GCP_PROJECT_ID
```

### 4. Create Secrets

```bash
# Django secret key (generate with: python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
echo -n "your-generated-secret-key" | gcloud secrets create django-secret-key --data-file=- --project=$GCP_PROJECT_ID

# Database URL
echo -n "postgresql://user:pass@/dbname?host=/cloudsql/project:region:instance" | gcloud secrets create database-url --data-file=- --project=$GCP_PROJECT_ID

# GCS Bucket
echo -n "your-bucket-name" | gcloud secrets create gcs-bucket-name --data-file=- --project=$GCP_PROJECT_ID
```

### 5. Create Service Account

```bash
# Create service account
gcloud iam service-accounts create cloud-run-sa \
  --display-name="Cloud Run Service Account" \
  --project=$GCP_PROJECT_ID

# Grant permissions
SA_EMAIL="cloud-run-sa@${GCP_PROJECT_ID}.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/cloudsql.client"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.objectAdmin"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/secretmanager.secretAccessor"
```

### 6. Deploy to Cloud Run

```bash
# Using the deployment script
GCP_PROJECT_ID=$GCP_PROJECT_ID ./scripts/deploy_cloudrun.sh deploy

# Or manually with gcloud
gcloud run deploy peterelmwood-com \
  --image=$GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/peterelmwood/peterelmwood-com:latest \
  --platform=managed \
  --region=$GCP_REGION \
  --allow-unauthenticated \
  --min-instances=0 \
  --max-instances=10 \
  --project=$GCP_PROJECT_ID
```

## Common Commands

### Deployment

```bash
# Full setup and deploy
GCP_PROJECT_ID=your-project ./scripts/deploy_cloudrun.sh full

# Deploy only
GCP_PROJECT_ID=your-project ./scripts/deploy_cloudrun.sh deploy

# Get service URL
GCP_PROJECT_ID=your-project ./scripts/deploy_cloudrun.sh url
```

### Monitoring

```bash
# View logs
GCP_PROJECT_ID=your-project ./scripts/deploy_cloudrun.sh logs

# Or with gcloud directly
gcloud run services logs read peterelmwood-com \
  --region=$GCP_REGION \
  --project=$GCP_PROJECT_ID

# Describe service
gcloud run services describe peterelmwood-com \
  --region=$GCP_REGION \
  --project=$GCP_PROJECT_ID
```

### Database Migrations

```bash
# Create migration job
gcloud run jobs create peterelmwood-com-migrate \
  --image=$GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/peterelmwood/peterelmwood-com:latest \
  --region=$GCP_REGION \
  --command=uv,run,python,manage.py,migrate \
  --set-secrets=SECRET_KEY=django-secret-key:latest,DATABASE_URL=database-url:latest \
  --project=$GCP_PROJECT_ID

# Execute migration
gcloud run jobs execute peterelmwood-com-migrate \
  --region=$GCP_REGION \
  --project=$GCP_PROJECT_ID
```

## Troubleshooting

### Service not accessible

```bash
# Check service status
gcloud run services describe peterelmwood-com \
  --region=$GCP_REGION \
  --project=$GCP_PROJECT_ID

# Check recent revisions
gcloud run revisions list \
  --service=peterelmwood-com \
  --region=$GCP_REGION \
  --project=$GCP_PROJECT_ID
```

### View error logs

```bash
# Real-time logs
gcloud run services logs tail peterelmwood-com \
  --region=$GCP_REGION \
  --project=$GCP_PROJECT_ID

# Recent errors
gcloud run services logs read peterelmwood-com \
  --region=$GCP_REGION \
  --project=$GCP_PROJECT_ID \
  --limit=50 \
  --format="table(timestamp,severity,textPayload)"
```

### Secret issues

```bash
# List secrets
gcloud secrets list --project=$GCP_PROJECT_ID

# View secret metadata (not content)
gcloud secrets describe django-secret-key --project=$GCP_PROJECT_ID

# Update secret
echo -n "new-secret-value" | gcloud secrets versions add django-secret-key \
  --data-file=- \
  --project=$GCP_PROJECT_ID
```

## Cost Optimization

Cloud Run automatically optimizes costs:

- **Scales to zero**: No charges when idle
- **Pay per request**: Only pay for actual usage
- **Free tier**: 2M requests/month included

Tips:
- Use `--min-instances=0` for maximum savings
- Monitor usage in GCP Console
- Set up billing alerts
- Use Cloud SQL shared-core instance for development

## Security Best Practices

1. **Secrets Management**: Always use Secret Manager, never hardcode secrets
2. **Service Account**: Use least-privilege service account
3. **IAM**: Restrict who can deploy and manage services
4. **VPC**: Consider VPC Connector for private database access
5. **Authentication**: Use IAM for admin endpoints

## Next Steps

1. Set up custom domain with Cloud Run
2. Configure Cloud SQL for production database
3. Set up Cloud Storage bucket for media files
4. Configure Cloud CDN for static assets
5. Set up monitoring and alerting
6. Configure backup strategy for database
