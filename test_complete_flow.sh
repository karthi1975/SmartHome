#!/bin/bash

echo "Testing Complete Health Education API Flow"
echo "==========================================="
echo ""

# Hardcoded token
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTc1NDY3NjgxOH0.SoNdU8muI14yVnQ0CzM1uvH6F6oBowJsCblQTKdKZhs"

echo "Test 1: Query with Images"
echo "--------------------------"
curl -s -X POST http://209.38.150.181:8000/api/v2/chat \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "what is blood pressure in AD?",
    "topic_filter": "",
    "n_results": 5,
    "use_advanced_search": true
  }' | python3 -c "
import sys, json
data = json.load(sys.stdin)
print('Response Structure:')
print(f'  ✅ Answer: {len(data.get(\"answer\", \"\"))} characters')
print(f'  ✅ Sources: {len(data.get(\"sources\", []))} documents')
print(f'  ✅ Has Images: {data.get(\"has_images\", False)}')
print(f'  ✅ Images Array: {len(data.get(\"images\", []))} items')

if data.get('sources'):
    print(f'\\n  Source Documents:')
    for s in data['sources'][:3]:
        print(f'    - {s.get(\"document\", \"N/A\")} (relevance: {s.get(\"relevance_score\", 0):.2f})')

if data.get('images'):
    print(f'\\n  Images Found:')
    for i, img in enumerate(data['images'][:3], 1):
        print(f'    {i}. {img.get(\"filename\", \"N/A\")}')
        print(f'       Description: {img.get(\"description\", \"N/A\")[:50]}...')
        print(f'       Has base64: {\"base64_data\" in img and img[\"base64_data\"] is not None}')
else:
    print(f'\\n  ⚠️  No images in response (empty array)')

print(f'\\n  Follow-up Suggestions: {len(data.get(\"follow_up_suggestions\", []))}')
"

echo ""
echo "Test 2: Query without Images (general question)"
echo "------------------------------------------------"
curl -s -X POST http://209.38.150.181:8000/api/v2/chat \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "what are the benefits of exercise?",
    "topic_filter": "",
    "n_results": 5,
    "use_advanced_search": true
  }' | python3 -c "
import sys, json
data = json.load(sys.stdin)
print('Response Structure:')
print(f'  ✅ Answer: {len(data.get(\"answer\", \"\"))} characters')
print(f'  ✅ Sources: {len(data.get(\"sources\", []))} documents')
print(f'  ✅ Has Images: {data.get(\"has_images\", False)}')
print(f'  ✅ Images Array: {len(data.get(\"images\", []))} items')
print(f'  ✅ Model: {data.get(\"model_used\", \"unknown\")}')
print(f'\\nAnswer Preview:')
answer = data.get(\"answer\", \"\")
print(answer[:200] + '...' if len(answer) > 200 else answer)
"

echo ""
echo "==========================================="
echo "Test Complete!"