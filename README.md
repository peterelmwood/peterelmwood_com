# peterelmwood_com

Personal website for Peter Elmwood, built with Django and Django REST Framework.

## Tech Stack

- **Backend**: Django 5.x with Django REST Framework
- **Database**: PostgreSQL 17
- **Package Manager**: uv (Python package manager)
- **Static Files**: WhiteNoise (local), GCP Cloud Storage (production)
- **Containerization**: Docker & Docker Compose
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
├── .github/
│   └── workflows/
│       └── deploy.yml         # CI/CD workflow
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

### GCP Setup Requirements

1. Create a GCP project
2. Enable Artifact Registry API
3. Create an Artifact Registry repository
4. Create a service account with permissions:
   - Artifact Registry Writer
   - Storage Admin (if using GCS)
5. Generate a JSON key for the service account

### GitHub Repository Secrets

Set the following secrets in your GitHub repository:

- `GCP_SA_KEY`: GCP service account JSON key

### GitHub Repository Variables

Set the following variables in your GitHub repository:

- `GCP_PROJECT_ID`: Your GCP project ID
- `GCP_REGION`: GCP region (e.g., `us-central1`)
- `GCP_ARTIFACT_REPO`: Artifact Registry repository name

### Deployment Workflow

The deployment workflow triggers on push to the `main` branch:

1. **Version Increment**: Automatically increments the patch version and creates a git tag
2. **Build & Push**: Builds the Docker image and pushes to GCP Artifact Registry
3. **Documentation**: (Future) Build and publish documentation

## API Documentation

The REST API is available at `/api/` (to be implemented).

## License

MIT License - see [LICENSE](LICENSE) for details.

