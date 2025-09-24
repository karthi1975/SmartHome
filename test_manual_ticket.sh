#!/bin/bash

# Manual Ticket Creation Test Script
# Tests creating a ticket manually via API

echo "======================================"
echo "Manual Ticket Creation Test"
echo "Subject: Fridge not connecting"
echo "Priority: URGENT"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ZAMMAD_URL="https://tickets.homeadapt.us/api/v1"
ZAMMAD_TOKEN="3chvCU9AmUKAoYI8suDCJiEjJ9Mm2zEWvQlZQIi4AYr_oD077Vt0FAQoOGJmrYhR"

# Ticket details
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

echo -e "\n${BLUE}Creating URGENT ticket for Fridge connectivity issue...${NC}"
echo "----------------------------------------"

# Create the ticket JSON
TICKET_JSON=$(cat <<EOF
{
    "title": "URGENT: Fridge not connecting",
    "group": "Users",
    "customer_id": 2,
    "article": {
        "subject": "Fridge Connectivity Issue - URGENT",
        "body": "Issue Report:\n\nDevice: Refrigerator\nProblem: Not connecting to network\nPriority: URGENT\nLocation: Kitchen\n\nDescription:\nThe smart refrigerator is not connecting to the home network. This is causing issues with temperature monitoring and food management features.\n\nRequested action:\n- Check network connectivity\n- Reset device connection\n- Verify smart home integration\n\nReported at: $TIMESTAMP\nStatus: Requires immediate attention",
        "type": "note",
        "internal": false
    },
    "state_id": 1,
    "priority_id": 3
}
EOF
)

echo -e "${YELLOW}Ticket Details:${NC}"
echo "  Subject: Fridge not connecting"
echo "  Priority: URGENT (3 high)"
echo "  Location: Kitchen"
echo "  Issue Type: Device Not Responding"

echo -e "\n${BLUE}Sending ticket to Zammad API...${NC}"

# Create the ticket
CREATE_RESPONSE=$(curl -s -X POST "$ZAMMAD_URL/tickets" \
    -H "Authorization: Bearer $ZAMMAD_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$TICKET_JSON")

# Check if ticket was created successfully
if echo "$CREATE_RESPONSE" | grep -q '"id"'; then
    TICKET_ID=$(echo "$CREATE_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    TICKET_NUMBER=$(echo "$CREATE_RESPONSE" | grep -o '"number":"[^"]*"' | cut -d'"' -f4)

    echo -e "\n${GREEN}✅ TICKET CREATED SUCCESSFULLY!${NC}"
    echo "======================================"
    echo -e "  Ticket ID: ${GREEN}$TICKET_ID${NC}"
    echo -e "  Ticket Number: ${GREEN}$TICKET_NUMBER${NC}"
    echo -e "  Priority: ${RED}URGENT${NC}"
    echo -e "  Subject: Fridge not connecting"
    echo "======================================"
    echo -e "\nView ticket at: ${BLUE}https://tickets.homeadapt.us/#ticket/zoom/$TICKET_ID${NC}"

    # Now verify the ticket by fetching it back
    echo -e "\n${YELLOW}Verifying ticket creation...${NC}"

    VERIFY_RESPONSE=$(curl -s -X GET "$ZAMMAD_URL/tickets/$TICKET_ID" \
        -H "Authorization: Bearer $ZAMMAD_TOKEN")

    if echo "$VERIFY_RESPONSE" | grep -q "Fridge"; then
        echo -e "${GREEN}✅ Ticket verified in system${NC}"

        # Extract and display ticket details
        STATE=$(echo "$VERIFY_RESPONSE" | grep -o '"state_id":[0-9]*' | cut -d':' -f2)
        PRIORITY=$(echo "$VERIFY_RESPONSE" | grep -o '"priority_id":[0-9]*' | cut -d':' -f2)

        echo -e "\nTicket Status:"
        echo -e "  State: $([ "$STATE" = "1" ] && echo "New" || echo "Other")"
        echo -e "  Priority: $([ "$PRIORITY" = "3" ] && echo "${RED}URGENT${NC}" || echo "Normal")"
    fi
else
    echo -e "${RED}❌ Failed to create ticket${NC}"
    echo "Error response:"
    echo "$CREATE_RESPONSE" | head -100
fi

echo -e "\n${YELLOW}======================================"
echo "Test Summary"
echo "======================================${NC}"

if [ ! -z "$TICKET_ID" ]; then
    echo -e "${GREEN}✅ Manual ticket creation: SUCCESS${NC}"
    echo "   • Ticket created with ID: $TICKET_ID"
    echo "   • Priority set to URGENT"
    echo "   • Subject: Fridge not connecting"
    echo "   • Location: Kitchen"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "   1. Check ticket appears in app's ticket history"
    echo "   2. Verify priority displays as URGENT (red)"
    echo "   3. Test voice command for similar issue"
else
    echo -e "${RED}❌ Manual ticket creation: FAILED${NC}"
    echo "   Please check API configuration"
fi

echo -e "\n${GREEN}Test Complete!${NC}"