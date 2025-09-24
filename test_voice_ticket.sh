#!/bin/bash

echo "🎯 Testing Voice-Triggered Ticket Creation"
echo "========================================="
echo ""

# Kill any existing simulator app
echo "📱 Closing existing app instances..."
xcrun simctl terminate 1EF875CA-C0AF-4A48-A5CE-F0F5D71D2681 com.universityofutahhealth.SmartHome 2>/dev/null || true

sleep 1

# Launch the app
echo "🚀 Launching SmartHomeController app..."
xcrun simctl launch 1EF875CA-C0AF-4A48-A5CE-F0F5D71D2681 com.universityofutahhealth.SmartHome

sleep 2

echo ""
echo "📝 Test Instructions:"
echo "1. The app should be running now"
echo "2. Tap the microphone button to start voice"
echo "3. Say: 'Create a ticket - my fridge light is not working'"
echo "4. Watch for these debug messages in Xcode console:"
echo "   - 🎫 Ticket creation request detected"
echo "   - 📝 Extracted details (subject, description)"
echo "   - 📱 CreateTicketView received notification"
echo "   - Email set to karthi@tetradapt.us"
echo ""
echo "5. The app should:"
echo "   - Navigate to Support page automatically"
echo "   - Fill in subject and description from voice"
echo "   - Set email to karthi@tetradapt.us"
echo "   - Show priority selection buttons"
echo "   - Allow submission to Zammad"
echo ""
echo "✅ App is now running. Open Xcode to see console logs."
echo ""

# Keep the script running to show logs if needed
echo "Press Ctrl+C to stop monitoring..."

# Monitor system log for our app
log stream --predicate 'processImagePath CONTAINS "SmartHome"' --style compact
