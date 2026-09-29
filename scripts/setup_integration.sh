#!/usr/bin/env bash
# Sets up an LLM provider + model integration on Orkes Conductor.
# Usage: bash setup_integration.sh <provider> <model>
# Example: bash setup_integration.sh openai gpt-4o
# Reads OPENAI_API_KEY from .env — run from the orkes-conductor directory where .env lives.

set -euo pipefail

PROVIDER="${1:?Usage: setup_integration.sh <provider> <model>}"
MODEL="${2:?Usage: setup_integration.sh <provider> <model>}"

# Load .env
if [ ! -f .env ]; then
  echo "Error: .env not found. Run this script from the orkes-conductor directory."
  exit 1
fi
set -a; source .env; set +a

LLM_API_KEY="${OPENAI_API_KEY:?OPENAI_API_KEY not set in .env}"

# Require jq
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install it with: brew install jq"
  exit 1
fi

# Get auth token
echo "Authenticating..."
TOKEN=$(curl -sf -X POST "$CONDUCTOR_SERVER_URL/token" \
  -H "Content-Type: application/json" \
  -d "{\"keyId\":\"$CONDUCTOR_AUTH_KEY\",\"keySecret\":\"$CONDUCTOR_AUTH_SECRET\"}" \
  | jq -r '.token')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "Error: Failed to get auth token. Check CONDUCTOR_AUTH_KEY and CONDUCTOR_AUTH_SECRET in .env."
  exit 1
fi

AUTH_HEADER="Authorization: Bearer $TOKEN"

# Check if provider exists
echo "Checking provider: $PROVIDER..."
PROVIDER_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "$AUTH_HEADER" \
  "$CONDUCTOR_SERVER_URL/integrations/provider/$PROVIDER")

if [ "$PROVIDER_STATUS" = "200" ]; then
  echo "Provider already exists: $PROVIDER"
else
  echo "Creating provider: $PROVIDER..."
  CREATE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    "$CONDUCTOR_SERVER_URL/integrations/provider/$PROVIDER" \
    -H "$AUTH_HEADER" \
    -H "Content-Type: application/json" \
    -d "{
      \"category\": \"AI_MODEL\",
      \"type\": \"$PROVIDER\",
      \"enabled\": true,
      \"configuration\": {
        \"api_key\": \"$LLM_API_KEY\",
        \"endpoint\": \"https://api.openai.com/v1/\",
        \"organizationId\": \"\"
      }
    }")

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
