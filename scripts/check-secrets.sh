#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

failed=0

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  failed=1
}

check_paths_for_sensitive_names() {
  local label="$1"
  shift
  local paths=("$@")

  for path in "${paths[@]}"; do
    case "$path" in
      .env|*/.env|.env.local|*/.env.local|*.pem)
        fail "$label contains local secret-like file: $path"
        ;;
    esac
  done
}

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  mapfile -t tracked_paths < <(git ls-files)
  mapfile -t staged_paths < <(git diff --cached --name-only)

  check_paths_for_sensitive_names "tracked files" "${tracked_paths[@]}"
  check_paths_for_sensitive_names "staged files" "${staged_paths[@]}"

  mapfile -t scan_paths < <(
    git ls-files \
      ':!:*.env' \
      ':!:.env' \
      ':!:.env.*' \
      ':!:*.local' \
      ':!:node_modules/**' \
      ':!:.next/**' \
      ':!:target/**'
  )
else
  warn "not inside a git work tree; scanning repository files outside ignored build directories"
  mapfile -t scan_paths < <(
    find . -type f \
      -not -path './node_modules/*' \
      -not -path './*/node_modules/*' \
      -not -path './.next/*' \
      -not -path './*/.next/*' \
      -not -path './target/*' \
      -not -path './*/target/*' \
      -not -path './.git/*' \
      -not -name '.env' \
      -not -name '.env.local' \
      -not -name '*.pem' \
      -print
  )
fi

if ((${#scan_paths[@]} > 0)); then
  for path in "${scan_paths[@]}"; do
    if grep -Iq . "$path"; then
      if grep -Eq -- 'sk-or-v1-[A-Za-z0-9_-]{20,}' "$path"; then
        fail "OpenRouter-looking key pattern found in $path"
      fi
      if grep -Eq -- '-----BEGIN (RSA |EC |OPENSSH |DSA |)?PRIVATE KEY-----' "$path"; then
        fail "private key marker found in $path"
      fi
    fi
  done
fi

if [[ -f .env ]]; then
  warn ".env exists locally; keep it untracked and out of reports/logs"
fi

if [[ -f .env.local ]]; then
  warn ".env.local exists locally; keep it untracked and out of reports/logs"
fi

if ((failed)); then
  exit 1
fi

echo "Secret check completed."
