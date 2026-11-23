#!/usr/bin/env bash
# Checks the running Docker Compose stack end to end, including the email reaching Mailpit.
# Needs curl and jq.
set -euo pipefail

API="${API_URL:-http://localhost:3000}"
MAILPIT="${MAILPIT_URL:-http://localhost:8025}"

echo "1. API health"
curl -fsS "$API/health" | jq -e '.status == "ok"' >/dev/null

echo "2. Home page: 5 featured products"
count=$(curl -fsS "$API/api/v1/products/featured" | jq '.items | length')
[ "$count" -eq 5 ] || { echo "Expected 5 featured products, got $count"; exit 1; }

echo "3. Enquiry is accepted"
reference=$(curl -fsS -X POST "$API/api/v1/enquiries" \
  -H 'content-type: application/json' \
  -d '{"productId":"1","name":"Smoke Test","email":"smoke@example.com","message":"CI smoke test"}' |
  jq -r '.reference')
echo "   reference: $reference"

echo "4. Sales inbox receives the email"
for _ in $(seq 1 20); do
  found=$(curl -fsS "$MAILPIT/api/v1/search?query=$reference" | jq '.messages_count')
  if [ "$found" -ge 1 ]; then
    echo "OK: all smoke checks passed"
    exit 0
  fi
  sleep 1
done
echo "Email with reference $reference did not arrive in Mailpit"
exit 1
