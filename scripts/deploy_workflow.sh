#!/usr/bin/env bash
# Deploys (upserts) a workflow definition to Orkes Conductor.
# Usage: bash deploy_workflow.sh <path/to/workflow.json>
# Run from the orkes-conductor directory where .env lives.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

WORKFLOW_FILE="${1:?Usage: deploy_workflow.sh <path/to/workflow.json>}"

if [ ! -f "$WORKFLOW_FILE" ]; then
  echo "Error: File not found: $WORKFLOW_FILE"
  exit 1
fi

# Load .env
if [ ! -f .env ]; then
  echo "Error: .env not found. Run this script from the orkes-conductor directory."
  exit 1
fi
load_env .env

# Require jq
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install it with: brew install jq"
  exit 1
fi

WORKFLOW_NAME=$(jq -r '.name' "$WORKFLOW_FILE")

# Get auth token
echo "Authenticating..."
TOKEN=$(get_token) || exit 1

# Deploy — API expects an array
echo "Deploying workflow: $WORKFLOW_NAME..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$CONDUCTOR_SERVER_URL/metadata/workflow" \
  -H "X-Authorization: $TOKEN" \
  -H "Content-Type: application/json" \
  -d "[$(cat "$WORKFLOW_FILE")]")

HTTP_STATUS=$(echo "$RESPONSE" | tail -1)

if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "204" ]; then
  echo "Deployed: $WORKFLOW_NAME"
else
  echo "Error: Deploy failed (HTTP $HTTP_STATUS)."
  echo "$RESPONSE" | head -1
  exit 1
fi
