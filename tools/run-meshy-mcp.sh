#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

trim_env_value() {
  local value="$1"
  value="${value#${value%%[![:space:]]*}}"
  value="${value%${value##*[![:space:]]}}"
  if [[ "${#value}" -ge 2 ]]; then
    if [[ "${value:0:1}" == '"' && "${value: -1}" == '"' ]]; then
      value="${value:1:${#value}-2}"
    elif [[ "${value:0:1}" == "'" && "${value: -1}" == "'" ]]; then
      value="${value:1:${#value}-2}"
    fi
  fi
  printf '%s' "$value"
}

load_trusted_env_keys() {
  local env_file="$1"
  local line key value
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    if [[ "$line" =~ ^[[:space:]]*(MESHY_API_KEY|MESHY_MCP_PACKAGE)[[:space:]]*=(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      value="$(trim_env_value "${BASH_REMATCH[2]}")"
      if [[ -z "${!key:-}" ]]; then
        export "$key=$value"
      fi
    fi
  done < "$env_file"
}

# Optional local-only convenience. Reads only trusted KEY=VALUE pairs; it does not
# execute .env as shell code.
if [[ -f ".env" ]]; then
  load_trusted_env_keys ".env"
fi

if [[ -z "${MESHY_API_KEY:-}" ]]; then
  echo "MESHY_API_KEY is not set. Export it in the shell that launches Codex, or put MESHY_API_KEY=... in an uncommitted .env." >&2
  exit 1
fi

package="${MESHY_MCP_PACKAGE:-@meshy-ai/meshy-mcp-server}"
exec npx -y "$package"
