# 🎯 Voice-Triggered Ticket Creation Demo

## Overview
The SmartHomeController app now supports voice-triggered ticket creation for maintenance requests. Users can speak natural language commands to automatically navigate to the support page and pre-fill ticket forms.

## How It Works

### 1. Voice Command Detection (`CallManager.swift`)
- **Lines 787-822**: Process user voice transcripts
- **Lines 1221-1262**: Detect ticket creation keywords
- **Lines 1265-1359**: Extract ticket details from voice command

### 2. Navigation & Form Population
- **Lines 162-189**: When ticket request detected:
  - Extracts subject, description, location, and issue type
  - Posts `NavigateToCreateTicket` notification with extracted details
  - Automatically navigates to Support page

### 3. Ticket Form Auto-Fill (`CreateTicketView.swift`)
- **Lines 723-774**: Receives notification and populates:
  - Subject field with extracted details
  - Description with voice command and context
  - Email automatically set to `karthi@tetradapt.us`
  - Shows priority selection buttons with animation

## Test Instructions

### Running the Test
```bash
./test_voice_ticket.sh
```

### Manual Testing Steps
1. Launch the app in Xcode (for console logs)
2. Tap the microphone button to activate voice
3. Say: **"Create a ticket - my fridge light is not working"**

### Expected Console Output
```
[DEBUG] 🎫 Ticket creation request detected: 'create a ticket - my fridge light is not working'
[DEBUG] 📝 Extracted details:
[DEBUG]   Subject: Not Functioning: Refrigerator in Kitchen
[DEBUG]   Description: Voice Command: "create a ticket - my fridge light is not working"...
[DEBUG]   Location: kitchen
[DEBUG]   Issue: Not Functioning
[DEBUG] 📱 CreateTicketView received navigation notification
[DEBUG] Email set to: karthi@tetradapt.us
```

### Expected App Behavior
1. ✅ Automatically navigates to Support page
2. ✅ Subject field filled: "Not Functioning: Refrigerator in Kitchen"
3. ✅ Description field filled with voice command details
4. ✅ Email field set to: `karthi@tetradapt.us`
5. ✅ Priority selection buttons appear with animation
6. ✅ Ready to submit ticket to Zammad

## Supported Voice Commands

### Ticket Creation Triggers
- "Create a ticket..."
- "Submit a ticket..."
- "Open a ticket..."
- "Report an issue..."
- "Maintenance request..."
- "Need help with..."

### Automatic Detection
The system automatically extracts:
- **Location**: kitchen, bathroom, bedroom, living room, etc.
- **Device**: fridge, AC, heater, sink, toilet, light, etc.
- **Issue Type**: broken, leaking, not working, malfunction, etc.

## Example Voice Commands

1. **Kitchen Issues**
   - "Create a ticket - my fridge is not cooling"
   - "Submit a maintenance request - kitchen sink is leaking"
   - "Report an issue - dishwasher not working"

2. **HVAC Issues**
   - "Open a ticket - AC not working in bedroom"
   - "Create a ticket - heater making strange noise"
   - "Report a problem - thermostat not responding"

3. **Bathroom Issues**
   - "Submit a ticket - bathroom faucet leaking"
   - "Create a maintenance request - toilet not flushing"
   - "Need help - shower has no hot water"

## Technical Implementation

### Key Components

1. **Voice Processing** (`CallManager.swift`)
   ```swift
   private func isTicketCreationRequest(_ text: String) -> Bool
   private func extractTicketDetails(from text: String) -> (subject, description, location, issue)
   ```

2. **Navigation** (Notification-based)
   ```swift
   NotificationCenter.default.post(
       name: NSNotification.Name("NavigateToCreateTicket"),
       object: nil,
       userInfo: ticketDetails
   )
   ```

3. **Form Auto-Fill** (`CreateTicketView.swift`)
   ```swift
   NotificationCenter.default.addObserver(
       forName: NSNotification.Name("NavigateToCreateTicket"),
       // Auto-populate form fields
   )
   ```

## Debug Mode

To enable detailed console logging:
1. Open project in Xcode
2. Run on simulator/device
3. View console output for `[DEBUG]` messages

## Troubleshooting

### Issue: Form doesn't populate
- Check console for `NavigateToCreateTicket` notification
- Verify email is set to `karthi@tetradapt.us`
- Ensure voice command contains ticket keywords

### Issue: Navigation doesn't occur
- Verify microphone permissions granted
- Check if wake word "Hi Luna" is active
- Ensure voice recognition is working

### Issue: Ticket submission fails
- Verify Zammad API credentials
- Check network connectivity
- Ensure all required fields are filled

## Configuration

### Default Settings
- **Email**: `karthi@tetradapt.us`
- **Priority**: Normal (user can change)
- **Auto-submit**: Disabled (requires user confirmation)

### Zammad Integration
- Server: `https://smarthome-test.zammad.com`
- API Token: Configured in `ZammadClient.swift`
- Real-time ticket creation and tracking

## Future Enhancements
- [ ] Auto-detect urgency from voice tone
- [ ] Support for photo attachments via voice
- [ ] Multi-language support
- [ ] Voice confirmation before submission
- [ ] Integration with calendar for scheduling
