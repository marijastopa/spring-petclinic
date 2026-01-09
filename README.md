# Spring PetClinic - CI/CD Pipeline

Automated CI/CD pipeline for deploying Spring PetClinic to Google Cloud Platform using GitHub Actions, Docker, and Terraform.

**Live Application:** https://petclinic-prod-uosana3xyq-uc.a.run.app  

**Current Version:** v1.0.4

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

### Optimization Strategy

**Multi-stage build:**
- **Builder stage:** Eclipse Temurin 21 JDK - Maven compilation
- **Runtime stage:** Eclipse Temurin 21 JRE - Application execution only

**Additional optimizations:**
- Layer caching for dependencies (faster rebuilds)
- Non-root user for security
- Health checks via Spring Actuator

## Security Implementation

### Vulnerability Scanning
- **Tool:** Trivy (industry standard)
- **Stage 1:** Filesystem scan (source code)
- **Stage 2:** Container image scan (built Docker image)
- **Severity:** CRITICAL and HIGH vulnerabilities
- **Integration:** Results uploaded to GitHub Security tab (SARIF format)

### Authentication & Secrets
- **Workload Identity (OIDC):** Short-lived tokens, no service account keys
- **GitHub Secrets:** Encrypted storage for sensitive data
- **Terraform Variables:** Marked as sensitive, never logged
- **No Hardcoded Credentials:** All secrets managed externally

### Container Security
- Non-root user (`spring:spring`)
- Minimal base image (JRE only, no build tools)
- Regular security scans in CI/CD

## Version Management

This project uses semantic versioning for production releases.

### Creating a Release

```bash
# Commit all changes
git add .
git commit -m "feat: Add new feature"
git push origin main

# Tag the release
git tag -a v1.1.0 -m "Release v1.1.0: Description of changes"
git push origin v1.1.0

# CI/CD automatically:
# 1. Runs Maven tests
# 2. Scans for security vulnerabilities  
# 3. Builds and pushes Docker image
# 4. Deploys to Cloud Run
```

### Docker Image Tags

Each release creates three tags:
- **`v1.0.4`** - Exact version (immutable)
- **`v1.0`** - Latest patch of v1.0.x (rolling)
- **`v1`** - Latest minor of v1.x.x (rolling)

---

## Infrastructure as Code

All cloud resources are managed with Terraform:
- Cloud Run service with auto-scaling (0-10 instances)
- Health probes (startup + liveness on `/actuator/health`)
- Resource limits (1 CPU, 512Mi RAM)
- IAM roles and public access configuration

Terraform deployment is automated via CI/CD. 

## Monitoring & Health

- **Health endpoint:** `/actuator/health`
- **Liveness probe:** `/actuator/health/liveness`
- **Logs:** GCP Cloud Logging
- **Metrics:** GCP Cloud Monitoring

---

**Module 4 Assignment** - CI/CD Pipeline Implementation  
