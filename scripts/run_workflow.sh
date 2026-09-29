#!/usr/bin/env bash
# Starts a workflow and polls until it completes, then prints the result.
# Usage: bash run_workflow.sh <workflow_name> [input_json]
# Example: bash run_workflow.sh github_repo_health_check '{"repo":"vercel/next.js"}'
# Run from the orkes-conductor directory where .env lives.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

WORKFLOW_NAME="${1:?Usage: run_workflow.sh <workflow_name> [input_json]}"
INPUT_JSON="${2:-{}}"

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

# Get auth token
echo "Authenticating..."
TOKEN=$(get_token) || exit 1
AUTH_HEADER="Authorization: Bearer $TOKEN"

# Start the workflow
echo "Starting workflow: $WORKFLOW_NAME..."
WORKFLOW_ID=$(curl -sf -X POST "$CONDUCTOR_SERVER_URL/workflow/$WORKFLOW_NAME" \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  -d "$INPUT_JSON")

# The response is a plain string (the workflow ID), strip quotes if present
WORKFLOW_ID=$(echo "$WORKFLOW_ID" | tr -d '"')

if [ -z "$WORKFLOW_ID" ]; then
  echo "Error: Failed to start workflow. Check workflow name and credentials."
  exit 1
fi

echo "Execution ID: $WORKFLOW_ID"
echo "Execution URL: ${CONDUCTOR_SERVER_URL%/api}/execution/$WORKFLOW_ID"
echo ""
echo "Waiting for completion..."

# Poll until terminal state
MAX_WAIT=120  # seconds
INTERVAL=3
ELAPSED=0

while [ $ELAPSED -lt $MAX_WAIT ]; do
  RESPONSE=$(curl -sf -H "$AUTH_HEADER" "$CONDUCTOR_SERVER_URL/workflow/$WORKFLOW_ID")
  STATUS=$(echo "$RESPONSE" | jq -r '.status')

  case "$STATUS" in
    COMPLETED)
      echo "Status: COMPLETED"
      echo ""
      echo "Output:"
      echo "$RESPONSE" | jq '.output'
      exit 0
      ;;
    FAILED|TIMED_OUT|TERMINATED)
      echo "Status: $STATUS"
      echo ""
      FAILED_TASK=$(echo "$RESPONSE" | jq -r '[.tasks[] | select(.status == "FAILED")] | first | .referenceTaskName // "unknown"')
      REASON=$(echo "$RESPONSE" | jq -r '[.tasks[] | select(.status == "FAILED")] | first | .reasonForIncompletion // "No details available."')
      echo "Failed task: $FAILED_TASK"
      echo "Reason: $REASON"
      exit 1
      ;;
    *)
      printf "."
      sleep $INTERVAL
      ELAPSED=$((ELAPSED + INTERVAL))
      ;;
  esac
done

echo ""
echo "Timed out after ${MAX_WAIT}s. Check the execution in the Orkes UI:"
echo "${CONDUCTOR_SERVER_URL%/api}/execution/$WORKFLOW_ID"
exit 1
