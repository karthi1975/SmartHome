#!/bin/bash

echo "Creating local test ticket..."
echo "================================"

# Configuration
ZAMMAD_URL="https://tickets.homeadapt.us/api/v1"
ZAMMAD_TOKEN="3chvCU9AmUKAoYI8suDCJiEjJ9Mm2zEWvQlZQIi4AYr_oD077Vt0FAQoOGJmrYhR"

# Ticket details
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Create the ticket JSON
TICKET_JSON=$(cat <<JSON_EOF
{
    "title": "URGENT: Fridge light not working - Test from App",
    "group": "Users",
    "customer_id": 2,
    "article": {
        "subject": "Fridge Light Issue - URGENT",
        "body": "Issue Report:\\n\\nDevice: Refrigerator\\nProblem: Light not working\\nPriority: URGENT\\nLocation: Kitchen\\nEmail: karthi@tetradapt.us\\n\\nDescription:\\nThe refrigerator light is not working. This is an urgent issue that needs immediate attention.\\n\\nReported at: $TIMESTAMP\\nStatus: Requires immediate attention",
        "type": "note",
        "internal": false
    },
    "state_id": 1,
    "priority_id": 3
}
JSON_EOF
)

echo "Creating ticket..."

# Create the ticket
RESPONSE=$(curl -s -X POST "$ZAMMAD_URL/tickets" \
    -H "Authorization: Bearer $ZAMMAD_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$TICKET_JSON")

# Extract ticket ID and number
if echo "$RESPONSE" | grep -q '"id"'; then
    TICKET_ID=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    TICKET_NUMBER=$(echo "$RESPONSE" | grep -o '"number":"[^"]*"' | cut -d'"' -f4)
    
    echo "✅ TICKET CREATED SUCCESSFULLY!"
    echo "  Ticket ID: $TICKET_ID"
    echo "  Ticket Number: $TICKET_NUMBER"
    echo "  Priority: URGENT"
    echo "  Email: karthi@tetradapt.us"
    echo ""
    echo "View at: https://tickets.homeadapt.us/#ticket/zoom/$TICKET_ID"
else
    echo "❌ Failed to create ticket"
    echo "$RESPONSE" | head -100
fi
