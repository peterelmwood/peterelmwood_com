"""
Production settings for peterelmwood_com project.

These settings are intended for production deployment.
"""

from .base import *  # noqa: F401, F403

# Security settings for production
DEBUG = False

# HTTPS/SSL settings
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SECURE_SSL_REDIRECT = env.bool("SECURE_SSL_REDIRECT", default=True)  # noqa: F405
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_HSTS_SECONDS = 31536000  # 1 year
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_CONTENT_TYPE_NOSNIFF = True

# Database
# Use PostgreSQL in production
DATABASES = {
    "default": env.db("DATABASE_URL"),  # noqa: F405
}

# GCP Cloud Storage for static and media files
GS_BUCKET_NAME = env("GS_BUCKET_NAME", default=None)  # noqa: F405

if GS_BUCKET_NAME:
    # Use GCP storage for static files
    STORAGES = {
        "default": {
            "BACKEND": "storages.backends.gcloud.GoogleCloudStorage",
        },
        "staticfiles": {
            "BACKEND": "storages.backends.gcloud.GoogleCloudStorage",
        },
    }

    GS_DEFAULT_ACL = "publicRead"
    GS_FILE_OVERWRITE = False

    # Google Cloud Storage settings
    from google.oauth2 import service_account

    GS_CREDENTIALS_FILE = env(  # noqa: F405
        "GS_CREDENTIALS_FILE", default="/secrets/gcp-credentials.json"
    )

    try:
        GS_CREDENTIALS = service_account.Credentials.from_service_account_file(
            GS_CREDENTIALS_FILE
        )
    except FileNotFoundError:
        # Fallback to default credentials (e.g., when running on GCP)
        GS_CREDENTIALS = None

# Logging configuration for production
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {
            "format": "{levelname} {asctime} {module} {process:d} {thread:d} {message}",
            "style": "{",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "verbose",
        },
    },
    "root": {
        "handlers": ["console"],
        "level": "INFO",
    },
    "loggers": {
        "django": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
        "django.request": {
            "handlers": ["console"],
            "level": "ERROR",
            "propagate": False,
        },
    },
}

# Email configuration
EMAIL_BACKEND = env(  # noqa: F405
    "EMAIL_BACKEND", default="django.core.mail.backends.smtp.EmailBackend"
)
EMAIL_HOST = env("EMAIL_HOST", default="smtp.gmail.com")  # noqa: F405
EMAIL_PORT = env.int("EMAIL_PORT", default=587)  # noqa: F405
EMAIL_USE_TLS = env.bool("EMAIL_USE_TLS", default=True)  # noqa: F405
EMAIL_HOST_USER = env("EMAIL_HOST_USER", default="")  # noqa: F405
EMAIL_HOST_PASSWORD = env("EMAIL_HOST_PASSWORD", default="")  # noqa: F405
