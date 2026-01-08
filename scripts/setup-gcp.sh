#!/bin/bash

set -euo pipefail

echo "  GCP Setup for PetClinic CI/CD"
echo ""

# Check for .env file
if [ ! -f "scripts/.env" ]; then
    echo "ERROR: scripts/.env not found!"
    echo ""
    echo "Create it from example:"
    echo "  cp scripts/.env.example scripts/.env"
    echo "  nano scripts/.env"
    echo ""
    exit 1
fi

# Load .env
echo "Loading configuration from .env..."
source scripts/.env

# Validate required variables
if [ -z "$GCP_PROJECT_ID" ] || [ -z "$GITHUB_USERNAME" ]; then
    echo "ERROR: Required variables missing in .env!"
    echo "Check: GCP_PROJECT_ID, GITHUB_USERNAME"
    exit 1
fi

# Set defaults
GCP_REGION=${GCP_REGION:-us-central1}
GITHUB_REPO_NAME=${GITHUB_REPO_NAME:-spring-petclinic}

# Check gcloud
if ! command -v gcloud &> /dev/null; then
    echo "ERROR: gcloud CLI not found!"
    exit 1
fi

# Set project
gcloud config set project $GCP_PROJECT_ID

# Enable APIs
echo "Enabling APIs..."
gcloud services enable \
    cloudresourcemanager.googleapis.com \
    cloudbuild.googleapis.com \
    run.googleapis.com \
    artifactregistry.googleapis.com \
    iam.googleapis.com \
    iamcredentials.googleapis.com \
    --quiet
echo "APIs enabled"

# Artifact Registry
echo ""
echo "Creating Artifact Registry..."
if gcloud artifacts repositories describe petclinic --location=$GCP_REGION &>/dev/null; then
    echo "Already exists"
else
    gcloud artifacts repositories create petclinic \
        --repository-format=docker \
        --location=$GCP_REGION \
        --quiet
    echo "Created"
fi

# Workload Identity Pool
echo ""
echo "Creating Workload Identity Pool..."
POOL_NAME="github-actions-pool"
if gcloud iam workload-identity-pools describe $POOL_NAME --location=global &>/dev/null; then
    echo "Already exists"
else
    gcloud iam workload-identity-pools create $POOL_NAME \
        --location=global \
        --display-name="GitHub Actions Pool" \
        --quiet
    echo "Created"
fi

# Provider
echo ""
echo "Creating Workload Identity Provider..."
PROVIDER_NAME="github-provider"
if gcloud iam workload-identity-pools providers describe $PROVIDER_NAME \
    --workload-identity-pool=$POOL_NAME --location=global &>/dev/null; then
    echo "Already exists"
else
    gcloud iam workload-identity-pools providers create-oidc $PROVIDER_NAME \
        --location=global \
        --workload-identity-pool=$POOL_NAME \
        --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
        --attribute-condition="assertion.repository_owner=='${GITHUB_USERNAME}'" \
        --issuer-uri="https://token.actions.githubusercontent.com" \
        --quiet
    echo "Created"
fi

# Service Account
echo ""
echo "Creating Service Account..."
SA_NAME="petclinic-ci-cd"
SA_EMAIL="${SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"

if gcloud iam service-accounts describe $SA_EMAIL &>/dev/null; then
    echo "Already exists"
else
    gcloud iam service-accounts create $SA_NAME \
        --display-name="PetClinic CI/CD" \
        --quiet
    echo "Created"
fi

# IAM Roles
echo ""
echo "Granting IAM roles..."
for ROLE in "roles/run.admin" "roles/artifactregistry.admin" "roles/iam.serviceAccountUser" "roles/storage.admin"; do
    gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
        --member="serviceAccount:${SA_EMAIL}" \
        --role="$ROLE" \
        --condition=None --quiet 2>/dev/null || true
done
echo "Roles granted"

# Workload Identity Binding
echo ""
echo "Binding Workload Identity..."
PROJECT_NUMBER=$(gcloud projects describe $GCP_PROJECT_ID --format='value(projectNumber)')

gcloud iam service-accounts add-iam-policy-binding $SA_EMAIL \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/attribute.repository/${GITHUB_USERNAME}/${GITHUB_REPO_NAME}" \
    --quiet
echo "Bound"

# Output
echo ""
echo "Setup Complete!"
echo ""
echo "GCP_PROJECT_ID"
echo "$GCP_PROJECT_ID"
echo ""
echo "GCP_WORKLOAD_IDENTITY_PROVIDER"
echo "projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/providers/${PROVIDER_NAME}"
echo ""
echo "GCP_SERVICE_ACCOUNT"
echo "$SA_EMAIL"
echo ""

echo "Granting additional IAM roles to Cloud Run service account..."

# Log Writer role
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/logging.logWriter" \
  --condition=None

# Metric Writer role  
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/monitoring.metricWriter" \
  --condition=None

echo "Additional IAM roles granted successfully!"