#!/bin/bash

echo "Testing Health Education API at http://209.38.150.181:8000"
echo "=========================================="
echo ""

# Test the chat endpoint
echo "Testing /chat endpoint with query: 'what is blood pressure in AD?'"
echo ""

curl -X POST http://209.38.150.181:8000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "query": "what is blood pressure in AD?",
    "topic_filter": "",
    "n_results": 5,
    "use_advanced_search": true
  }' | python3 -m json.tool

echo ""
echo "=========================================="
echo "Test complete!"