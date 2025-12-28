# Readdig

Readdig is an RSS and Podcast reader application.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Development Setup](#development-setup)
  - [Docker Deployment](#docker-deployment)
  - [Synology NAS Deployment](#synology-nas-deployment)
- [Configuration](#configuration)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Features

- RSS feed reader
- Podcast player
- User authentication and management
- Feed organization with folders and tags
- Article starring and reading history
- OPML import/export
- Email notifications
- Payment integration with Paddle

## Architecture

The application consists of:

- **API**: Node.js backend service (Express.js)
- **App**: React frontend (Create React App)
- **Database**: PostgreSQL
- **Cache**: Redis
- **Queue**: Bull (Redis-based)

## Prerequisites

- Node.js 18.20.8 or later
- PostgreSQL 12 or later
- Redis 6 or later
- Docker and Docker Compose (for Docker deployment)

## Installation

### Development Setup

#### 1. Clone Repository

```bash
git clone https://github.com/readdig/readdig.git
cd readdig
```

#### 2. Setup API

```bash
cd api

# Install dependencies
yarn install

# Configure environment
cp .env.example .env
# Edit .env with your settings

# Run database migrations
yarn db:migrate

# Start development server
yarn dev
```

The API will be available at `http://localhost:8000`

#### 3. Setup App

```bash
cd ../app

# Install dependencies
yarn install

# Configure environment
cp .env.example .env
# Edit .env with your settings

# Start development server
yarn start
```

The app will be available at `http://localhost:3000`

### Docker Deployment

This project provides a unified Docker setup at the root level that orchestrates all services (API, App, Redis, PostgreSQL) in a single configuration.

> **📌 Synology NAS Deployment**: If you're deploying on Synology NAS using Docker, see the [Synology NAS Deployment](#synology-nas-deployment) section below for specific instructions on configuring local network access (e.g., `http://192.168.100.110:5233`).

#### 1. Clone Repository

```bash
git clone https://github.com/readdig/readdig.git
cd readdig
```

#### 2. Configure API Service

```bash
# Copy API environment configuration
cp .env.api.example api/.env

# Copy PM2 production configuration
cp ecosystem.prod.config.js.example ecosystem.prod.config.js
```

Edit `api/.env`:

```bash
# Production environment
NODE_ENV=production

# Product Information
PRODUCT_URL=https://www.readdig.com
PRODUCT_NAME=Readdig.com
USER_AGENT=ReaddigBot/1.0 (https://www.readdig.com)

# Security - IMPORTANT: Generate secure keys
JWT_SECRET=your-jwt-secret-key-here

# Email Configuration (SendGrid)
EMAIL_SENDER_SUPPORT_NAME=Readdig Support
EMAIL_SENDER_SUPPORT_EMAIL=support@readdig.com
EMAIL_SENDGRID_SECRET=your-sendgrid-api-key

# Optional: Cloudflare Worker Proxy
CLOUDFLARE_PROXY_URL=https://your-worker.workers.dev
CLOUDFLARE_PROXY_SECRET=your-cloudflare-secret

# Optional: Paddle Payment Integration
PADDLE_PUBLIC_KEY=your-paddle-public-key
PADDLE_API_URL=https://vendors.paddle.com/api/2.0
PADDLE_VENDOR_ID=your-vendor-id
PADDLE_VENDOR_AUTH_CODE=your-auth-code

# Optional: Sentry Error Tracking
SENTRY_DSN=your-sentry-dsn
```

#### 3. Configure App Service

```bash
# Copy App environment configuration
cp .env.app.example app/.env

# Copy Nginx configuration
cp nginx.conf.example nginx.conf
```

Edit `app/.env`:

```bash
# React App Configuration
NODE_ENV=production

# Product Information
REACT_APP_PRODUCT_URL=https://www.readdig.com
REACT_APP_PRODUCT_NAME=Readdig.com
REACT_APP_PRODUCT_DESCRIPTION=Readdig.com an RSS and Podcast reader

# API Endpoint - IMPORTANT: Point to your actual API
REACT_APP_API_URL=https://api.readdig.com
# Or if API is on same domain: https://www.readdig.com/api

# Optional: Analytics and Monitoring
REACT_APP_SENTRY_DSN=your-sentry-dsn
REACT_APP_PADDLE_VENDOR_ID=your-paddle-vendor-id
```

Edit `nginx.conf` (replace domain names):

```nginx
server {
  listen 80;
  listen [::]:80;
  server_name yourdomain.com;
  return 301 http://www.yourdomain.com$request_uri;
}

server {
  listen 80;
  listen [::]:80;
  server_name www.yourdomain.com;

  # Serve React app static files
  location / {
    root /usr/share/nginx/html;
    try_files $uri $uri/ /index.html =404;
  }

  # Proxy API requests to backend
  location /api/ {
    proxy_pass http://api:8000/;
    proxy_http_version  1.1;
    proxy_cache_bypass  $http_upgrade;

    proxy_set_header Upgrade            $http_upgrade;
    proxy_set_header Connection         "upgrade";
    proxy_set_header Host               $host;
    proxy_set_header X-Real-IP          $remote_addr;
    proxy_set_header X-Forwarded-For    $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto  $scheme;
    proxy_set_header X-Forwarded-Host   $host;
    proxy_set_header X-Forwarded-Port   $server_port;
  }
}
```

**Notes**:
- Replace `yourdomain.com` with your actual domain name
- The first server block redirects non-www to www
- `proxy_pass http://api:8000/` - points to the API container (using Docker network name)
- The trailing slash in `/api/` and `http://api:8000/` is important - it removes `/api` prefix when forwarding

#### 4. Configure Database Password

Edit `docker-compose.yml` to set a secure database password:

```yaml
api:
  environment:
    DATABASE_URL: postgresql://readdig:your-secure-password@database:5432/readdig

database:
  environment:
    POSTGRES_PASSWORD: your-secure-password
```

**Important**: Make sure the database password in `database.environment.POSTGRES_PASSWORD` matches the one in `api.environment.DATABASE_URL`

**Note**: Redis runs without password in the internal Docker network, which is secure for private deployments.

#### 5. Build and Start All Services

```bash
# Build all services (API and App)
docker compose build

# Start all services (API, App, PostgreSQL, Redis)
docker compose up -d

# Check service status
docker compose ps

# View logs for all services
docker compose logs -f

# View logs for specific service
docker compose logs -f api
docker compose logs -f app
```

The services will be available at:
- **Frontend**: `http://localhost:80`
- **API**: `http://localhost:8000` (internally accessible from app container)

**Note**: Database migrations will run automatically when the API container starts.

#### 6. Verify Deployment

```bash
# Check API health (from within the container network)
docker compose exec app curl http://api:8000/health

# Expected response: {"status":"ok"}
```

Open your browser:
- Frontend: `http://localhost:80`

#### Alternative: Individual Service Deployment

If you prefer to deploy API and App services separately (e.g., for different servers), you can still use the individual Docker configurations in the `api/` and `app/` directories:

**API Service:**
```bash
cd api
cp .env.example .env
cp docker-compose.yml.example docker-compose.yml
cp ecosystem.prod.config.js.example ecosystem.prod.config.js
# Edit configurations as needed
docker compose up -d
```

**App Service:**
```bash
cd app
cp .env.example .env
cp docker-compose.yml.example docker-compose.yml
cp nginx.conf.example nginx.conf
# Edit configurations as needed
docker compose up -d
```

### Synology NAS Deployment

Deploying Readdig on Synology NAS allows you to access your RSS reader via your local network (e.g., `http://192.168.100.110:5233`).

#### Prerequisites

- Synology NAS with Docker package installed
- SSH access to your Synology NAS (or use File Station to transfer files)
- Basic knowledge of terminal commands

#### Deployment Steps

**1. Access Your Synology NAS**

SSH into your Synology NAS or use the File Station:
```bash
ssh admin@192.168.100.110
```

**2. Clone the Repository**

```bash
cd /volume1/docker  # or your preferred location
git clone https://github.com/readdig/readdig.git
cd readdig
```

**3. Configure Port Mapping**

Edit `docker-compose.yml` to use a custom port (e.g., 5233 instead of 80):

```yaml
app:
  ports:
    - '5233:80'  # Change from default '80:80' to your preferred port
```

**4. Configure Environment Variables**

Set up API environment:
```bash
cp .env.api.example api/.env
nano api/.env  # or use File Station editor
```

In `api/.env`, configure with your local network IP:
```bash
NODE_ENV=production
PRODUCT_URL=http://192.168.100.110:5233
PRODUCT_NAME=Readdig
USER_AGENT=ReaddigBot/1.0
JWT_SECRET=your-secure-jwt-secret-here
```

Set up App environment:
```bash
cp .env.app.example app/.env
nano app/.env
```

In `app/.env`, configure with your local network IP:
```bash
NODE_ENV=production
REACT_APP_PRODUCT_URL=http://192.168.100.110:5233
REACT_APP_PRODUCT_NAME=Readdig
REACT_APP_PRODUCT_DESCRIPTION=Readdig - RSS and Podcast Reader
REACT_APP_API_URL=http://192.168.100.110:5233/api
```

**5. Configure Nginx**

```bash
cp nginx.conf.example nginx.conf
nano nginx.conf
```

Update the server name to your local IP:
```nginx
server {
  listen 80;
  server_name 192.168.100.110;

  location / {
    root /usr/share/nginx/html;
    try_files $uri $uri/ /index.html =404;
  }

  location /api/ {
    proxy_pass http://api:8000/;
    proxy_http_version  1.1;
    proxy_cache_bypass  $http_upgrade;

    proxy_set_header Upgrade            $http_upgrade;
    proxy_set_header Connection         "upgrade";
    proxy_set_header Host               $host;
    proxy_set_header X-Real-IP          $remote_addr;
    proxy_set_header X-Forwarded-For    $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto  $scheme;
    proxy_set_header X-Forwarded-Host   $host;
    proxy_set_header X-Forwarded-Port   $server_port;
  }
}
```

**6. Configure PM2 and Database**

```bash
cp ecosystem.prod.config.js.example ecosystem.prod.config.js
```

Update database password in `docker-compose.yml`:
```yaml
api:
  environment:
    DATABASE_URL: postgresql://readdig:your-secure-password@database:5432/readdig

database:
  environment:
    POSTGRES_PASSWORD: your-secure-password
```

**7. Build and Start Services**

```bash
docker compose build
docker compose up -d
```

**8. Access Your Application**

Open your browser and navigate to:
- **From same local network**: `http://192.168.100.110:5233` (replace with your NAS IP and port)
- **From NAS itself**: `http://localhost:5233`

**9. Verify Deployment**

```bash
# Check service status
docker compose ps

# View logs
docker compose logs -f

# Test API health
docker compose exec app curl http://api:8000/health
```

#### Important Notes for Synology NAS

- **Port Selection**: Choose a port that's not already in use on your NAS (e.g., 5233, 8080, 3000). Avoid common ports like 80, 443, 5000, 5001 which may be used by DSM.
- **Firewall**: Ensure the chosen port is allowed in Synology's firewall settings if you want to access from other devices on your network.
- **IP Address**: Replace `192.168.100.110` with your actual Synology NAS IP address. You can find it in DSM under Control Panel → Network → Network Interface.
- **Persistent Data**: All data (database, Redis, static files) will be stored in `./data/` directory in the Readdig folder. Ensure sufficient storage space.
- **Updates**: To update the application:
  ```bash
  # Navigate to readdig directory
  cd /volume1/docker/readdig
  
  # Pull latest changes
  git pull
  
  # Rebuild and restart services
  docker compose down
  docker compose build
  docker compose up -d
  ```
- **Accessing from Internet**: For external access, configure port forwarding in your router and consider using a reverse proxy with SSL/TLS for security.

#### Troubleshooting on Synology NAS

**Port Already in Use:**
```bash
# Find what's using the port
sudo netstat -tlnp | grep :5233

# Choose a different port in docker-compose.yml
```

**Cannot Access from Browser:**
1. Verify the NAS IP address: `ip addr show`
2. Check if containers are running: `docker compose ps`
3. Check firewall rules in DSM: Control Panel → Security → Firewall
4. Try accessing from the NAS itself: `curl http://localhost:5233`

**Insufficient Permissions:**
```bash
# Run commands with sudo if needed
sudo docker compose up -d
```

**Out of Memory:**
1. Check available resources in DSM Resource Monitor
2. Consider reducing the number of worker processes in `ecosystem.prod.config.js`

## Configuration

### Environment Variables

#### API Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `NODE_ENV` | Environment (development/production) | Yes |
| `API_PORT` | API server port | Yes |
| `API_HOST` | API server host | Yes |
| `DATABASE_URL` | PostgreSQL connection string | Yes |
| `CACHE_URL` | Redis connection string | Yes |
| `JWT_SECRET` | JWT signing secret | Yes |
| `EMAIL_SENDGRID_SECRET` | SendGrid API key | No |
| `SENTRY_DSN` | Sentry error tracking DSN | No |
| `PADDLE_VENDOR_ID` | Paddle vendor ID | No |

#### App Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `REACT_APP_PRODUCT_URL` | Product URL | Yes |
| `REACT_APP_PRODUCT_NAME` | Product name | Yes |
| `REACT_APP_API_URL` | API endpoint URL | Yes |
| `REACT_APP_SENTRY_DSN` | Sentry DSN | No |
| `REACT_APP_PADDLE_VENDOR_ID` | Paddle vendor ID | No |

### Production Deployment with Reverse Proxy

For production, use a reverse proxy Nginx on your host to:
- Handle SSL/TLS certificates
- Route requests to appropriate services
- Serve both app and API from the same domain

**Important**: This is the **host-level reverse proxy** configuration, separate from the `nginx.conf` (in the root directory) that's used inside the app Docker container. The architecture is:

```
Internet → Host Nginx (SSL/proxy) → Docker Containers
                ├─ App container (port 80)
                └─ API container (accessible via backend network)
```


**Configuration Summary**:

| Configuration | Location | Purpose |
|--------------|----------|---------|
| `nginx.conf` (root) | Inside app Docker container | Serves React static files and proxies `/api/` to backend container |
| Host Nginx config | On host server | Handles SSL/TLS and routes traffic to Docker containers |

**Deployment scenarios**:
- **Local development**: Only `nginx.conf` needed (no SSL)
- **Production with Docker only**: Only `nginx.conf` needed (add SSL to Docker config)
- **Production with host reverse proxy** (recommended): Both configs needed - host Nginx handles SSL, `nginx.conf` handles internal routing

## Maintenance

### View Logs

```bash
# All services logs
docker compose logs -f

# API logs
docker compose logs -f api

# App logs
docker compose logs -f app

# Database logs
docker compose logs -f database

# Redis logs
docker compose logs -f cache
```

### Restart Services

```bash
# Restart all services
docker compose restart

# Restart specific service
docker compose restart api
docker compose restart app
```

### Update Application

```bash
# Pull latest code
git pull

# Rebuild and restart all services
docker compose down
docker compose build --no-cache
docker compose up -d

# Or update specific service
docker compose build --no-cache api
docker compose up -d api
```

### Backup Database

```bash
# Create backup
docker exec database pg_dump -U readdig readdig > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore backup
docker exec -i database psql -U readdig readdig < backup_20231201_120000.sql
```

### Monitor Resources

```bash
# View resource usage
docker stats

# View disk usage
docker system df
```

## Troubleshooting

### API Cannot Connect to Database

1. Check database is running:
   ```bash
   docker-compose ps database
   ```

2. Verify `DATABASE_URL` in `.env`:
   ```bash
   DATABASE_URL=postgresql://readdig:password@database:5432/readdig
   ```

3. Check database logs:
   ```bash
   docker-compose logs database
   ```

### App Shows API Connection Error

1. Verify `REACT_APP_API_URL` in `app/.env`
2. Rebuild the app (React env vars are set at build time):
   ```bash
   docker-compose build --no-cache
   docker-compose up -d
   ```

### Port Already in Use

Change the port mapping in `docker-compose.yml`:

```yaml
ports:
  - '8080:8000'  # Use port 8080 instead of 8000
```

### Out of Disk Space

Clean up Docker resources:

```bash
# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Clean everything
docker system prune -a --volumes
```

### Environment Variables Not Working

**For API**: Restart the container after changing `.env`:
```bash
docker-compose restart api
```

**For App**: Rebuild the image (React bakes env vars at build time):
```bash
docker-compose build --no-cache
docker-compose up -d
```

## Security Best Practices

1. **Change Default Passwords**: Update database password in both `docker-compose.yml` and `.env`
2. **Use Strong JWT Secret**: Generate a secure random string for `JWT_SECRET`
3. **Enable HTTPS**: Use a reverse proxy with SSL/TLS certificates
4. **Restrict Ports**: Only expose necessary ports to the public
5. **Regular Updates**: Keep Docker images and dependencies updated
6. **Environment Variables**: Never commit `.env` files to version control
7. **Database Backups**: Set up automated database backups

## Development

### Available Scripts

#### API Scripts

```bash
yarn api          # Start API server
yarn conductor    # Start conductor worker
yarn feed         # Start feed worker
yarn og           # Start OG worker
yarn clean        # Start clean worker
yarn dev          # Start all services with PM2
yarn build        # Build for production
yarn db:migrate   # Run database migrations
yarn db:studio    # Open Drizzle Studio
```

#### App Scripts

```bash
yarn start        # Start development server
yarn build        # Build for production
```

## Support

If you find this project helpful, consider supporting the development:

<a href="https://buymeacoffee.com/debugging" target="_blank">
  <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" >
</a>
