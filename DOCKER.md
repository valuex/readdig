# Docker Deployment Guide

This repository supports two Docker deployment approaches:

## Unified Deployment (Recommended)

Deploy all services (API, App, Redis, PostgreSQL) together using the configurations at the root level.

**Files:**
- `Dockerfile` - Multi-stage build for both API and App
- `docker-compose.yml` - Orchestrates all services
- `nginx.conf` - Nginx configuration for the App
- `ecosystem.prod.config.js` - PM2 configuration for the API
- `docker-entrypoint.sh` - API startup script

**Quick Start:**
```bash
# Configure environment files
cp .env.api.example api/.env
cp .env.app.example app/.env
cp nginx.conf.example nginx.conf
cp ecosystem.prod.config.js.example ecosystem.prod.config.js

# Edit configurations
nano api/.env
nano app/.env
nano nginx.conf
nano docker-compose.yml  # Update database password

# Build and start all services
docker compose build
docker compose up -d

# View logs
docker compose logs -f
```

**Advantages:**
- Single command to deploy everything
- All services share the same network
- Simplified configuration management
- Consistent deployment across environments

## Individual Service Deployment

Deploy API and App services separately using configurations in their respective directories.

**Use this approach when:**
- You want to deploy services on different servers
- You need independent scaling of services
- You have existing infrastructure for Redis/PostgreSQL

**API Service:**
```bash
cd api
cp .env.example .env
cp docker-compose.yml.example docker-compose.yml
cp ecosystem.prod.config.js.example ecosystem.prod.config.js
docker compose up -d
```

**App Service:**
```bash
cd app
cp .env.example .env
cp docker-compose.yml.example docker-compose.yml
cp nginx.conf.example nginx.conf
docker compose up -d
```

## Service Ports

- **App (Frontend)**: `http://localhost:80`
- **API (Backend)**: `http://localhost:8000` (not exposed in unified deployment)
- **PostgreSQL**: Port 5432 (internal only)
- **Redis**: Port 6379 (internal only)

## For More Details

See the [main README.md](README.md) for complete setup instructions, configuration options, and troubleshooting guides.
