# GeoStorm-AI Services Integration

This repository orchestrates the full GeoStorm-AI microservice system.
The four microservices are maintained in separate public repositories.
This repository provides Docker Compose files, shared contracts, canonical environment examples, scripts, and documentation.

## Services

| Service | Role | Image |
| --- | --- | --- |
| Frontend Gateway | Next.js dashboard and `/api/analyze` gateway | `ghcr.io/<owner>/geostorm-frontend-gateway:<tag>` |
| AI Engine | FastAPI risk analysis and RabbitMQ publisher | `ghcr.io/<owner>/geostorm-ai-engine:<tag>` |
| MCP Server | NASA/NOAA data service over gRPC and HTTP health/debug | `ghcr.io/<owner>/geostorm-mcp-server:<tag>` |
| Alert Service | Rust RabbitMQ consumer, PostgreSQL writer, text report artifact generator | `ghcr.io/<owner>/geostorm-alert-service:<tag>` |

Service repository links:

- `https://github.com/<owner>/geostorm-frontend-gateway`
- `https://github.com/<owner>/geostorm-ai-engine`
- `https://github.com/<owner>/geostorm-mcp-server`
- `https://github.com/<owner>/geostorm-alert-service`

## Run Mode 1: Local Source Build

The root `docker-compose.yml` is the default local development compose file. It builds from local service folders and must remain the normal source-build runtime.

```bash
git clone <root-repo-url>
cd geostorm-services-repo
cp .env.example .env
# edit .env with local runtime values
docker compose up -d --build
```

This mode requires these folders to exist locally:

- `geostorm-ai-engine/`
- `geostorm-mcp-server/`
- `geostorm-alert-service/`
- `geostorm-frontend-gateway/`

Equivalent helper:

```bash
scripts/run-local-build.sh
```

## Run Mode 2: Registry Images

The `docker-compose.images.yml` file runs the same system from prebuilt GHCR images and does not require service source folders locally.
For this course submission, the image-based compose file uses the `latest` GHCR image tag by default. The source-build compose remains available for reproducible local builds from the service repositories.

```bash
git clone <root-repo-url>
cd geostorm-services-repo
cp .env.example .env
# edit image variables and runtime values
docker compose -f docker-compose.images.yml up -d
```

Or pull first:

```bash
docker compose -f docker-compose.images.yml pull
docker compose -f docker-compose.images.yml up -d
```

Equivalent helper:

```bash
scripts/run-images.sh
```

GHCR images must exist and be public or accessible to your Docker login before image mode can pull them.

Default image variables use `latest`:

```env
AI_ENGINE_IMAGE=ghcr.io/<owner>/geostorm-ai-engine:latest
MCP_SERVER_IMAGE=ghcr.io/<owner>/geostorm-mcp-server:latest
ALERT_SERVICE_IMAGE=ghcr.io/<owner>/geostorm-alert-service:latest
FRONTEND_GATEWAY_IMAGE=ghcr.io/<owner>/geostorm-frontend-gateway:latest
```

## Required Environment Values

Copy `.env.example` to `.env` and replace placeholder values. Do not commit real `.env` files.

Core runtime values:

- `OPENROUTER_API_KEY`
- `OPENROUTER_MODEL`
- `NASA_API_KEY`
- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `DATABASE_URL`
- `RABBITMQ_USER`
- `RABBITMQ_PASSWORD`
- `RABBITMQ_URL`
- `FASTAPI_URL`
- `EMAIL_ENABLED=false`

Image-mode values:

- `IMAGE_TAG`
- `GITHUB_CONTAINER_OWNER`
- `AI_ENGINE_IMAGE`
- `MCP_SERVER_IMAGE`
- `ALERT_SERVICE_IMAGE`
- `FRONTEND_GATEWAY_IMAGE`

## Service URLs

- Frontend: `http://localhost:3000`
- AI Engine: `http://localhost:8000`
- MCP HTTP health/debug: `http://localhost:6274`
- MCP gRPC: `localhost:50051`
- RabbitMQ UI: `http://localhost:15672`
- PostgreSQL: `localhost:5432`

## Validation

```bash
docker compose config --quiet
docker compose -f docker-compose.images.yml config --quiet
scripts/smoke-test.sh
scripts/check-secrets.sh
```

## Known Limitations

- Report artifacts are text files, not PDFs.
- Email delivery is disabled by default with `EMAIL_ENABLED=false`.
- SMTP/email delivery requires explicit configuration and is not assumed.
- No authentication is included.
- No production TLS or mTLS is included.
