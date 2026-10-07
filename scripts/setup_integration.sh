#!/usr/bin/env bash
# Sets up an LLM provider + model integration on Orkes Conductor.
# Usage: bash setup_integration.sh <provider> <model>
# Example: bash setup_integration.sh openai gpt-4o
# Reads the matching provider API key from .env (see the provider map below) —
# run from the orkes-conductor directory where .env lives.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

PROVIDER="${1:?Usage: setup_integration.sh <provider> <model>}"
MODEL="${2:?Usage: setup_integration.sh <provider> <model>}"

# Load .env
if [ ! -f .env ]; then
  echo "Error: .env not found. Run this script from the orkes-conductor directory."
  exit 1
fi
load_env .env

# Map the workflow's llmProvider to the .env key name and API endpoint Orkes
# needs for that provider. Add a case here when a workflow needs a provider
# that isn't listed yet.
case "$PROVIDER" in
  openai)
    KEY_VAR=OPENAI_API_KEY
    ENDPOINT="https://api.openai.com/v1/"
    ;;
  anthropic)
    KEY_VAR=ANTHROPIC_API_KEY
    ENDPOINT="https://api.anthropic.com"
    ;;
  google_gemini)
    KEY_VAR=GEMINI_API_KEY
    ENDPOINT=""
    ;;
  *)
    echo "Error: unsupported provider '$PROVIDER'. Add it to the case statement in setup_integration.sh."
    exit 1
    ;;
esac

if [ -z "${!KEY_VAR:-}" ]; then
  echo "Error: $KEY_VAR not set in .env (required for provider '$PROVIDER')."
  exit 1
fi
LLM_API_KEY="${!KEY_VAR}"

# Require jq
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install it with: brew install jq"
  exit 1
fi

# Get auth token
echo "Authenticating..."
TOKEN=$(get_token) || exit 1
AUTH_HEADER="X-Authorization: $TOKEN"

# Check if provider exists
echo "Checking provider: $PROVIDER..."
PROVIDER_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "$AUTH_HEADER" \
  "$CONDUCTOR_SERVER_URL/integrations/provider/$PROVIDER")

if [ "$PROVIDER_STATUS" = "200" ]; then
  echo "Provider already exists: $PROVIDER"
else
  echo "Creating provider: $PROVIDER..."
  PROVIDER_BODY=$(jq -n \
    --arg type "$PROVIDER" \
    --arg key "$LLM_API_KEY" \
    --arg endpoint "$ENDPOINT" \
    '{category: "AI_MODEL", type: $type, enabled: true,
      configuration: {api_key: $key, endpoint: $endpoint, organizationId: ""}}')
  CREATE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    "$CONDUCTOR_SERVER_URL/integrations/provider/$PROVIDER" \
    -H "$AUTH_HEADER" \
    -H "Content-Type: application/json" \
    -d "$PROVIDER_BODY")

  if [ "$CREATE_STATUS" = "200" ] || [ "$CREATE_STATUS" = "204" ]; then
    echo "Created provider: $PROVIDER"
  else
    echo "Error: Failed to create provider $PROVIDER (HTTP $CREATE_STATUS)."
    exit 1
  fi
fi

# Check if model exists
echo "Checking model: $MODEL..."
MODEL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "$AUTH_HEADER" \
  "$CONDUCTOR_SERVER_URL/integrations/provider/$PROVIDER/integration/$MODEL")

if [ "$MODEL_STATUS" = "200" ]; then
  echo "Model already exists: $MODEL"
else
  echo "Adding model: $MODEL..."
  ADD_MODEL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    "$CONDUCTOR_SERVER_URL/integrations/provider/$PROVIDER/integration/$MODEL" \
    -H "$AUTH_HEADER" \
    -H "Content-Type: application/json" \
    -d "{
      \"description\": \"$MODEL\",
      \"enabled\": true,
      \"configuration\": {}
    }")

  if [ "$ADD_MODEL_STATUS" = "200" ] || [ "$ADD_MODEL_STATUS" = "204" ]; then
    echo "Added model: $MODEL"
  else
    echo "Error: Failed to add model $MODEL (HTTP $ADD_MODEL_STATUS)."
    exit 1
  fi
fi

echo "Integration ready: $PROVIDER / $MODEL"
