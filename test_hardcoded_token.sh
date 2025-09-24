#!/bin/bash

echo "Testing Hardcoded Token Implementation"
echo "======================================"
echo ""

# The hardcoded token from the code
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTc1NDY3NjgxOH0.SoNdU8muI14yVnQ0CzM1uvH6F6oBowJsCblQTKdKZhs"

echo "1. Testing API with hardcoded token"
echo "   Token: ${TOKEN:0:50}..."
echo ""

echo "2. Making API call to /api/v2/chat"
curl -X POST http://209.38.150.181:8000/api/v2/chat \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "what is blood pressure in AD?",
    "topic_filter": "",
    "n_results": 5,
    "use_advanced_search": true
  }' 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print('✅ API Call Successful!')
    print(f'   - Answer length: {len(data.get(\"answer\", \"\"))} characters')
    print(f'   - Sources: {len(data.get(\"sources\", []))}')
    print(f'   - Images: {len(data.get(\"images\", []))}')
    print(f'   - Has images: {data.get(\"has_images\", False)}')
    print(f'   - Processing time: {data.get(\"processing_time\", 0):.2f}s')
    print(f'   - Model: {data.get(\"model_used\", \"unknown\")}')
    if data.get('images'):
        print(f'\\n   Image details:')
        for i, img in enumerate(data['images'][:3], 1):
            print(f'   {i}. {img.get(\"filename\", \"N/A\")} - {img.get(\"description\", \"No description\")[:50]}...')
except Exception as e:
    print(f'❌ Error: {e}')
"

echo ""
echo "======================================"
echo "Test Complete!"