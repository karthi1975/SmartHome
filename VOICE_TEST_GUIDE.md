# Voice Input Testing Guide

## Testing Voice → API → Panel Display

### 1. Manual Test Steps

1. **Navigate to Health Education Page**
   - Say: "Take me to health education" or tap Health Education in sidebar

2. **Ask a Health Question via Voice**
   - Say: "What is blood pressure in AD?"
   - Or: "What is autonomic dysreflexia?"

3. **Expected Behavior**:
   - **Voice Response** (immediate): Brief 1-2 sentence summary
   - **Panel Display** (1-2 seconds later):
     - User's question appears as a bubble
     - Loading indicator shows
     - Full detailed text appears
     - Images appear below text
     - Sources and page references shown

### 2. Debug Console Output

When voice input is working correctly, you should see:

```
[DEBUG] 🎯 HealthEducationUserMessage notification received in ViewModel
[DEBUG] 🎯 Received user message notification: 'what is blood pressure in AD'
[DEBUG] 🔥 handleUserMessage START with message: 'what is blood pressure in AD'
[DEBUG] 🔥 isConfigured: true
[DEBUG] 🔥 Adding user message directly to UI
[DEBUG] 🔥 User message added. Total messages: 2
[DEBUG] 🔥 Starting API call for voice input: 'what is blood pressure in AD'
[DEBUG] 🚀 HealthEducationViewModel.processQuery called with: 'what is blood pressure in AD'
[DEBUG] 🌐 Calling api.askQuestion with query: 'what is blood pressure in AD'
[DEBUG] 🌐 API Response received:
  - Answer: In the context of Autonomic Dysreflexia...
  - Images count: 2
[DEBUG] ✅ Adding message to UI:
  - Content: In the context of Autonomic Dysreflexia...
  - Has images: true
  - Images count: 2
[DEBUG] ✅ Message added successfully. Total messages: 3
```

### 3. Common Issues and Fixes

#### Issue: Voice input not triggering API
**Check**:
- Is HealthEducationViewModel configured? Check settings
- Is the notification being posted from CallManager?
- Is the singleton HealthEducationViewModel.shared being used?

#### Issue: API called but no display
**Check**:
- Are messages being added to the array?
- Is objectWillChange.send() being called?
- Is the view observing the correct ViewModel?

#### Issue: Text shows but no images
**Check**:
- Does API response include images?
- Are images being decoded successfully?
- Check console for "Successfully decoded base64 image" messages

### 4. Test Different Question Types

Test these to ensure all types work:

1. **Definition**: "What is autonomic dysreflexia?"
2. **How-to**: "How do I prevent pressure sores?"
3. **Symptoms**: "What are symptoms of UTI?"
4. **Management**: "How to manage spasticity?"

### 5. Verify Voice/Text Separation

For each question, verify:
- Voice gives brief summary (10-15 seconds max)
- Screen shows full detailed explanation
- Images are displayed when relevant
- Voice ends with directing to screen

### 6. Code Flow Summary

```
Voice Input
    ↓
CallManager detects health question
    ↓
Posts "HealthEducationUserMessage" notification
    ↓
HealthEducationViewModel.handleUserMessage() receives it
    ↓
Adds user message to UI
    ↓
Calls processQuery()
    ↓
API call to /api/v2/chat
    ↓
Response received with answer + images
    ↓
Message with full content added to UI
    ↓
Brief voice summary spoken via VAPI
    ↓
Panel displays everything
```

### 7. Quick Fix Checklist

If voice input isn't working:

✅ Ensure HealthEducationViewModel is using singleton pattern
✅ Verify notification observer is set up in init()
✅ Check API configuration (token, URL)
✅ Confirm CallManager is posting notifications
✅ Verify view is using @StateObject with .shared
✅ Check console for debug messages
✅ Ensure processQuery() is being called
✅ Verify API response is being received

### 8. Testing from Xcode

To see all debug output:
1. Run app in Xcode
2. Open Debug Console (Shift+Cmd+Y)
3. Filter console by "[DEBUG]"
4. Test voice input and watch the flow