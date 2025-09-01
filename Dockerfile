# Full-stack Dockerfile (build from project root)
# Multi-stage build for Crown Security API + Flutter Web

# Flutter Web Build Stage
FROM ghcr.io/cirruslabs/flutter:3.35.2 AS flutter-builder

# Set working directory
WORKDIR /flutter-app

# Copy Flutter project
COPY app/crown_security/ ./

# Get Flutter dependencies
RUN flutter pub get

# Build Flutter web app
RUN flutter build web --release \
    --dart-define=API_BASE_URL=/api/v1 \
    --base-href=/admin/ \
    --no-wasm-dry-run

# Backend Build Stage
FROM node:22-alpine AS backend-builder

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apk add --no-cache \
    postgresql-client \
    wget \
    curl

# Copy package files
COPY backend/package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy backend application code
COPY backend/ ./

# Final production stage
FROM node:22-alpine

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apk add --no-cache \
    postgresql-client \
    wget \
    curl

# Copy backend from builder stage
COPY --from=backend-builder /app ./

# Copy Flutter web build to public directory
COPY --from=flutter-builder /flutter-app/build/web ./public/admin

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs

# Change ownership of the app directory
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE ${PORT:-10000}

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT:-10000}/health || exit 1

# Start the application
CMD ["npm", "start"]
