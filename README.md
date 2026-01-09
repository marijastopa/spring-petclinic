# Spring PetClinic - CI/CD Pipeline

Automated CI/CD pipeline for deploying Spring PetClinic to Google Cloud Platform using GitHub Actions, Docker, and Terraform.

**Live Application:** 
https://petclinic-prod-71198917000.us-central1.run.app/

## Project Overview

Implementation of a production-ready CI/CD pipeline that:
- Automates testing and deployment of a Dockerized web application
- Stores Docker images in Google Artifact Registry
- Includes security scanning of Docker images and source code
- Deploys to Google Cloud Run using Infrastructure as Code (Terraform)

## Technology Stack

- **CI/CD System:** GitHub Actions
- **Cloud Provider:** Google Cloud Platform (Cloud Run)
- **Application:** Spring Boot 3.x, Java 21
- **Containerization:** Docker with multi-stage builds
- **Infrastructure:** Terraform
- **Security Scanning:** Trivy
- **Testing:** Maven, JUnit, JaCoCo

## Quick Start

### Prerequisites

- Google Cloud Platform account with billing enabled
- GitHub repository with Actions enabled
- `gcloud` CLI installed

### Setup Instructions

1. **Clone and configure:**
   ```bash
   git clone https://github.com/marijastopa/spring-petclinic.git
   cd spring-petclinic
   # Edit scripts/.env with your GCP project details
   ```

2. **Run automated setup:**
   ```bash
   cd scripts
   chmod +x setup-gcp.sh
   ./setup-gcp.sh
   ```

3. **Configure GitHub Secrets** (output by setup script):
   - `GCP_PROJECT_ID`
   - `GCP_WORKLOAD_IDENTITY_PROVIDER`
   - `GCP_SERVICE_ACCOUNT`

4. **Push to main branch** - Pipeline runs automatically!

## CI/CD Pipeline

The pipeline executes automatically on push to `main` or `develop` branches:

### Stage 1: Build and Test
- Runs Maven tests with JUnit
- Generates JaCoCo code coverage reports
- Uploads test results as artifacts

### Stage 2: Filesystem Security Scan
- Scans source code with Trivy
- Detects CRITICAL and HIGH vulnerabilities
- Uploads SARIF results to GitHub Security

### Stage 3: Build and Push Docker Image
- Multi-stage Docker build (builder + runtime)
- Pushes to Google Artifact Registry

### Stage 4: Container Security Scan
- Scans Docker image with Trivy
- Validates image before deployment

### Stage 5: Deploy to GCP
- Deploys using Terraform to Cloud Run
- Executes smoke test (health check)
- Outputs service URL

### Stage 6: Notify
- Reports pipeline status

## Docker

Multi-stage Dockerfile with optimizations:
- **Builder stage:** Maven build with dependencies cached separately
- **Runtime stage:** JRE-only for smaller image size
- **Security:** Non-root user, health checks configured
- **Optimization:** Layer caching for faster builds

**Local testing:**
```bash
docker-compose up
# Access at http://localhost:8080
```

## Security Implementation

- **Workload Identity:** OIDC authentication (no service account keys stored)
- **Automated Scanning:** Trivy scans filesystem and container images
- **Secret Management:** GitHub Secrets with sensitive variable protection
- **Non-root Container:** Application runs as unprivileged user
- **SARIF Integration:** Vulnerability reports in GitHub Security tab

## Infrastructure as Code

Terraform manages all cloud resources:
- Cloud Run service with auto-scaling
- IAM roles and bindings
- Health probes (startup + liveness)
- Resource limits and optimization

## Key Features Implemented

**Automated CI/CD** - GitHub Actions with 6-stage pipeline  
**Dockerization** - Multi-stage builds, optimized images  
**Cloud Deployment** - GCP Cloud Run (serverless, auto-scaling)  
**Security Scanning** - Trivy for vulnerabilities  
**Automated Testing** - Maven tests on every commit  
**Infrastructure as Code** - Terraform for reproducible deployments  
**Secret Management** - Secure handling via Workload Identity  
**Pipeline Optimization** - Caching, parallel jobs  
**Health Monitoring** - Smoke tests, health probes  

## Monitoring

- **Health endpoint:** `/actuator/health`
- **Liveness probe:** `/actuator/health/liveness`
- **Logs:** Available in GCP Cloud Logging
- **Pipeline status:** GitHub Actions UI

---

**Module 4 Assignment** - CI/CD Pipeline Implementation  
