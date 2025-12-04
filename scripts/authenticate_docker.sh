#!/usr/bin/env bash

# Authenticate Docker to use Google Artifact Registry
set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

GCP_REGION="${GCP_REGION:-us-central1}"
GCP_PROJECT_ID="${GCP_PROJECT_ID:-peterelmwood}"

gcloud auth configure-docker "${GCP_REGION}-docker.pkg.dev" --project="${GCP_PROJECT_ID}"
