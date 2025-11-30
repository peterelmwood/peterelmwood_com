"""
Local development settings for peterelmwood_com project.

These settings are intended for local development only.
"""

from .base import *  # noqa: F401, F403

# Debug should be True for local development
DEBUG = True

ALLOWED_HOSTS = ["localhost", "127.0.0.1", "0.0.0.0"]  # noqa: S104

# For local development, allow console email backend
EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"

# Database
# Use PostgreSQL for local development via docker-compose
# Falls back to SQLite if DATABASE_URL is not set
DATABASES = {
    "default": env.db(  # noqa: F405
        "DATABASE_URL",
        default="postgres://peterelmwood:peterelmwood@localhost:5432/peterelmwood_db",
    ),
}

# Django Debug Toolbar (optional for local development)
# Uncomment if you want to use Django Debug Toolbar
# INSTALLED_APPS += ["debug_toolbar"]  # noqa: F405
# MIDDLEWARE.insert(0, "debug_toolbar.middleware.DebugToolbarMiddleware")  # noqa: F405
# INTERNAL_IPS = ["127.0.0.1"]

# Logging configuration for local development
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
        },
    },
    "root": {
        "handlers": ["console"],
        "level": "DEBUG",
    },
    "loggers": {
        "django": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
    },
}
