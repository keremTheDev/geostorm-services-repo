#!/usr/bin/env python3
"""Smoke test for GeoStorm MCP gRPC service."""

import json
import os
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
AI_ENGINE_ROOT = REPO_ROOT / "geostorm-ai-engine"
sys.path.insert(0, str(AI_ENGINE_ROOT))

import grpc  # noqa: E402
from app.grpc import space_weather_pb2, space_weather_pb2_grpc  # noqa: E402


def main() -> int:
    host = os.environ.get("MCP_GRPC_HOST", "localhost")
    port = os.environ.get("MCP_GRPC_PORT", "50051")
    target = f"{host}:{port}"

    with grpc.insecure_channel(target) as channel:
        stub = space_weather_pb2_grpc.SpaceWeatherServiceStub(channel)

        health = stub.Health(space_weather_pb2.HealthRequest(), timeout=5)
        ready = stub.Ready(space_weather_pb2.ReadyRequest(), timeout=5)
        context = stub.GetContext(
            space_weather_pb2.GetContextRequest(start_date="", end_date=""),
            timeout=30,
        )

    print("Health:", health.status, health.service, health.message)
    print("Ready:", ready.status, ready.service, ready.message)
    print(
        "Context:",
        json.dumps(
            {
                "source": context.source,
                "fetched_at": context.fetched_at,
                "date_window": {
                    "startDate": context.date_window.start_date,
                    "endDate": context.date_window.end_date,
                },
                "errors": list(context.errors),
            },
            indent=2,
        ),
    )

    if health.status != "ok":
        print("Health check did not return ok.", file=sys.stderr)
        return 1
    if ready.status not in {"ready", "ok"}:
        print("Ready check did not return ready/ok.", file=sys.stderr)
        return 1
    if context.source != "geostorm-mcp-server":
        print("Context source was unexpected.", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
