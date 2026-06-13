#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

PROMPT='Analyze current space weather risk using NASA and NOAA data; include optional ESA provider status if available.'

echo "Checking frontend health..."
curl -fsS http://localhost:3000/api/health >/dev/null

echo "Checking AI health..."
curl -fsS http://localhost:8000/health >/dev/null

echo "Checking AI readiness..."
curl -fsS http://localhost:8000/ready >/dev/null

echo "Checking MCP HTTP health..."
curl -fsS http://localhost:6274/health >/dev/null

echo "Checking AI insight endpoint..."
curl -fsS -X POST http://localhost:8000/api/v1/insight \
  -H "Content-Type: application/json" \
  -d "{\"prompt\":\"${PROMPT}\"}" >/tmp/geostorm-smoke-insight.json

echo "Checking latest PostgreSQL alert row when postgres is available..."
if docker compose ps postgres >/dev/null 2>&1; then
  docker compose exec -T postgres psql -U "${POSTGRES_USER:-geostorm}" -d "${POSTGRES_DB:-geostorm}" \
    -c "SELECT id, event_id, alert_level, report_path, email_status, received_at FROM alert_logs ORDER BY id DESC LIMIT 1;" || true
else
  echo "PostgreSQL service is not available through docker compose; skipping DB row check."
fi

echo "Checking report artifacts when alert service is available..."
if docker compose ps geostorm-alert-service >/dev/null 2>&1; then
  docker compose exec -T geostorm-alert-service sh -c "ls -la /app/reports | tail -20" || true
else
  echo "Alert service is not available through docker compose; skipping report artifact check."
fi

echo "Smoke test completed."
