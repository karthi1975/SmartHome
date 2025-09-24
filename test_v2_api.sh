#!/bin/bash

echo "Testing Health Education v2 API with Authentication"
echo "===================================================="
echo ""

# Step 1: Login to get token
echo "1. Logging in with admin credentials..."
TOKEN=$(curl -s -X POST http://209.38.150.181:8000/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123" | python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])")

if [ -z "$TOKEN" ]; then
    echo "Failed to get authentication token"
    exit 1
fi

echo "   Token obtained: ${TOKEN:0:20}..."
echo ""

# Step 2: Test v2 chat endpoint with authentication
echo "2. Testing /api/v2/chat endpoint with query: 'what is blood pressure in AD?'"
echo ""

curl -X POST http://209.38.150.181:8000/api/v2/chat \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "what is blood pressure in AD?",
    "topic_filter": "",
    "n_results": 5,
    "use_advanced_search": true
  }' | python3 -m json.tool

echo ""
echo "===================================================="
echo "Test complete!"