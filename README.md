# GeoStorm-AI Services Integration

This repository orchestrates the full GeoStorm-AI microservice system.
The four microservices are maintained in separate public repositories.
This repository provides Docker Compose files, shared contracts, canonical environment examples, scripts, and documentation.

## Services

| Service | Role | Image |
| --- | --- | --- |
| Frontend Gateway | Next.js dashboard and `/api/analyze` gateway | `ghcr.io/<owner>/geostorm-frontend-gateway:<tag>` |
| AI Engine | FastAPI risk analysis and RabbitMQ publisher | `ghcr.io/<owner>/geostorm-ai-engine:<tag>` |
| MCP Server | NASA/NOAA data service plus optional ESA SWE/HAPI context over gRPC and HTTP health/debug | `ghcr.io/<owner>/geostorm-mcp-server:<tag>` |
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
- `ESA_ENABLED=false`
- `ESA_HAPI_BASE_URL` if ESA is enabled
- `ESA_HAPI_DATASET_ID` if ESA is enabled
- `ESA_HAPI_PARAMETERS` optional comma-separated HAPI parameters
- `ESA_ACCESS_TOKEN` or `ESA_TOKEN_URL`/`ESA_CLIENT_ID`/`ESA_CLIENT_SECRET` if the selected ESA/HAPI endpoint requires authentication
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

## Optional ESA SWE/HAPI Provider

ESA ingestion is implemented in the MCP server as a supplementary provider and is disabled by default. NASA DONKI and NOAA SWPC remain the canonical risk sources; ESA status/data are added to the normalized context as provider metadata and do not override `risk_level`, `current_risk_level`, `forecast_risk_level`, or `risk_basis`.

The implementation expects a HAPI-compatible server. HAPI clients discover data with `/catalog`, inspect datasets with `/info`, and fetch records with `/data`. Configure the verified ESA/HAPI base URL and dataset before enabling it:

```env
ESA_ENABLED=true
ESA_HAPI_BASE_URL=https://example-esa-hapi-server/hapi
ESA_HAPI_DATASET_ID=replace_with_verified_dataset
ESA_HAPI_PARAMETERS=replace,with,parameters
ESA_HAPI_LOOKBACK_HOURS=24
```

If the selected ESA SWE/HAPI source requires authentication, either provide `ESA_ACCESS_TOKEN` directly or configure OAuth client credentials with `ESA_TOKEN_URL`, `ESA_CLIENT_ID`, and `ESA_CLIENT_SECRET`. Leave `ESA_ENABLED=false` until those values are confirmed; missing ESA configuration degrades to `esa_source_status=disabled` or `missing_configuration` and does not break NASA/NOAA analysis.

## Validation

```bash
docker compose config --quiet
docker compose -f docker-compose.images.yml config --quiet
scripts/smoke-test.sh
scripts/check-secrets.sh
```

## Known Limitations

- Report artifacts are text files, not PDFs.
- ESA SWE/HAPI is optional and config-driven because a public unauthenticated ESA HAPI endpoint/dataset is not assumed.
- Email delivery is disabled by default with `EMAIL_ENABLED=false`.
- SMTP/email delivery requires explicit configuration and is not assumed.
- No authentication is included.
- No production TLS or mTLS is included.
