# ==========================================
# Stage 1: Build API
# ==========================================
FROM node:20-alpine AS api-builder

# Create app directory
WORKDIR /usr/src/readdig/api

# Copy API source code
COPY api/package.json api/yarn.lock ./
RUN yarn install

# Copy rest of API source
COPY api/ ./

# Remove the existing build directory and create a fresh one
RUN rm -rf ./dist && mkdir ./dist

# Build to dist
RUN yarn build

# Copy email files to fresh /dist directory
COPY api/src/utils/email/templates ./dist/utils/email/templates

# ==========================================
# Stage 2: Build App (Frontend)
# ==========================================
FROM node:20-alpine AS app-builder

# Create app directory
WORKDIR /usr/src/readdig/app

# Copy app source code
COPY app/package.json app/yarn.lock ./
RUN yarn install

# Copy rest of app source
COPY app/ ./

# Build app
RUN yarn build

# ==========================================
# Stage 3: API Runtime
# ==========================================
FROM node:20-alpine AS api

# Install PM2 and redis-cli, postgresql-client globally
RUN yarn global add pm2 && apk add --no-cache redis postgresql-client

# Create app directory
WORKDIR /usr/src/readdig/api

# Copy built API from builder
COPY --from=api-builder /usr/src/readdig/api ./

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose port 8000
EXPOSE 8000

# Use entrypoint script to run migrations before starting app
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["pm2-runtime", "start", "ecosystem.prod.config.js"]

# ==========================================
# Stage 4: App Runtime (Nginx)
# ==========================================
FROM nginx:latest AS app

# Copy build file from app builder
COPY --from=app-builder /usr/src/readdig/app/build /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf
