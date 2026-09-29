#!/usr/bin/env bash
# Shared helpers for the orkes-conductor setup scripts.
# Source this file; do not execute it directly.

# Reads a .env file as data, not as shell code, so quotes, spaces, "export "
# prefixes, or Windows line endings in pasted secrets can't break or hijack
# the calling script the way `source .env` can.
load_env() {
  local env_file="${1:-.env}" line key val
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    line="${line#"${line%%[![:space:]]*}"}"
    [ -z "$line" ] && continue
    case "$line" in \#*) continue ;; esac
    line="${line#export }"
    key="${line%%=*}"; val="${line#*=}"
    key="${key%"${key##*[![:space:]]}"}"
    val="${val#"${val%%[![:space:]]*}"}"; val="${val%"${val##*[![:space:]]}"}"
    if [ "${#val}" -ge 2 ]; then
      case "$val" in \"*\"|\'*\') val="${val:1:${#val}-2}" ;; esac
    fi
    [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] && export "$key=$val"
  done < "$env_file"
}

# Exchanges CONDUCTOR_AUTH_KEY/CONDUCTOR_AUTH_SECRET (already loaded into the
# environment) for a bearer token. Prints the token on success; prints an
# error to stderr and returns non-zero on failure. Builds the request body
# with jq so a special character in a secret (a quote, a backslash) can't
# break or inject into the JSON.
get_token() {
  local body token
  body=$(jq -n --arg k "$CONDUCTOR_AUTH_KEY" --arg s "$CONDUCTOR_AUTH_SECRET" \
    '{keyId: $k, keySecret: $s}')
  token=$(curl -sf -X POST "$CONDUCTOR_SERVER_URL/token" \
    -H "Content-Type: application/json" \
    -d "$body" | jq -r '.token // empty') || true
  if [ -z "$token" ]; then
    echo "Error: Failed to get auth token. Check CONDUCTOR_AUTH_KEY and CONDUCTOR_AUTH_SECRET in .env." >&2
    return 1
  fi
  echo "$token"
}
