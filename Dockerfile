# syntax=docker/dockerfile:1
FROM python:3.12-slim AS base

# Prevent Python from writing pyc files and buffer stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

WORKDIR /app

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security with a writable home for uv caches
RUN addgroup --system --gid 1001 appgroup && \
    adduser --system --uid 1001 --gid 1001 --home /home/appuser appuser && \
    mkdir -p /home/appuser/.cache/uv && \
    chown -R appuser:appgroup /home/appuser

# Development stage
FROM base AS development

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies including dev dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen

# Copy application code
COPY . .

# Change ownership to non-root user
RUN chown -R appuser:appgroup /app

ENV HOME=/home/appuser

USER appuser

# Expose port
EXPOSE 8000

# Run Django development server
CMD ["uv", "run", "python", "manage.py", "runserver", "0.0.0.0:8000"]

# Production stage
FROM base AS production

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install production dependencies only
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

# Copy application code
COPY . .

# Collect static files (using a temporary secret key for build only)
RUN SECRET_KEY=build-time-secret-key \
    DATABASE_URL=sqlite:///db.sqlite3 \
    uv run python manage.py collectstatic --noinput

# Change ownership to non-root user
RUN chown --recursive appuser:appgroup /app

ENV HOME=/home/appuser

USER appuser

# Expose port
EXPOSE 8000

# Run gunicorn with uvicorn workers (ASGI server)
CMD ["uv", "run", "gunicorn", "config.asgi:application", "--bind", "0.0.0.0:8000", "--workers", "4", "--worker-class", "uvicorn.workers.UvicornWorker"]
