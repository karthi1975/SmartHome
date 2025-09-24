# Voice-Text Separation Implementation Guide

## Architecture Overview

The system uses a dual-response architecture where the RAG API provides both voice and screen content:

```
User Question → API → {
    "answer": "Full detailed medical explanation...",      // For screen
    "voice_answer": "Brief 2-line natural summary",        // For voice  
    "images": [...],                                       // For screen
    "sources": [...]                                       // For screen
}
```

## Backend API Requirements

The `/api/v2/chat` endpoint should return:

### 1. `answer` (for screen display)
- Complete medical information
- Detailed explanations
- Step-by-step instructions
- Can be multiple paragraphs
- Include medical terminology with explanations
- Structured with bullet points, sections

### 2. `voice_answer` (for VAPI voice)
- 1-2 natural sentences maximum
- Conversational tone
- 10-15 seconds speaking time
- End with: "Check your screen for details" or similar
- Use everyday language

### 3. `images` (for screen display)
- Relevant medical diagrams
- Instructional images
- Charts and infographics
- Each with metadata (description, source)

## Example API Response

```json
{
  "answer": "Autonomic Dysreflexia (AD) is a potentially life-threatening medical emergency that affects individuals with spinal cord injuries at T6 or above. It occurs when there is an irritating stimulus below the level of injury that causes an uncontrolled sympathetic nervous system response.\n\nSymptoms include:\n• Sudden severe headache\n• Profuse sweating above the injury level\n• Flushed or blotchy skin\n• Stuffy nose\n• Slow heart rate\n• Blood pressure elevation of 20-40 mmHg above baseline\n\nImmediate Actions:\n1. Sit up immediately (if lying down)\n2. Loosen tight clothing\n3. Check for and remove triggers\n4. Monitor blood pressure\n5. Call 911 if symptoms persist",
  
  "voice_answer": "It's when your blood pressure suddenly spikes dangerously high, usually from something irritating your body below your injury. I've put all the warning signs and emergency steps on your screen.",
  
  "images": [
    {
      "image_data": "base64...",
      "description": "Anatomical diagram showing AD trigger pathways",
      "page_number": 12,
      "document_source": "SCI Emergency Guide"
    },
    {
      "image_data": "base64...",
      "description": "Blood pressure spike visualization",
      "page_number": 15,
      "document_source": "AD Management Protocol"
    }
  ],
  
  "sources": ["SCI Emergency Guide.pdf", "AD Management Protocol.pdf"],
  "confidence_score": 0.95
}
```

## Frontend Implementation

### HealthEducationViewModel.swift handles the separation:

```swift
// When processing API response:
if let response = try await api.askQuestion(query) {
    // Display full answer on screen
    let screenMessage = HealthChatMessage(
        content: response.answer,        // Full detailed text
        images: response.images,          // All images
        sources: response.sources         // References
    )
    messages.append(screenMessage)
    
    // Send brief summary to VAPI for voice
    if let voiceAnswer = response.voiceAnswer {
        // VAPI speaks the brief version
        await callManager.speakResponse(voiceAnswer)
    }
}
```

## VAPI Configuration

Since VAPI is handling voice responses based on the `voiceAnswer` field:

1. **When backend provides `voice_answer`**: 
   - VAPI speaks the brief summary
   - Screen shows full details

2. **When backend doesn't provide `voice_answer`**:
   - VAPI should generate its own brief summary
   - Use the prompt to ensure brevity

## Testing the Separation

### Test Case 1: Complex Medical Question
**User**: "What is autonomic dysreflexia?"
**Voice** (10 sec): "It's when your blood pressure spikes dangerously high. Check your screen for symptoms and emergency steps."
**Screen**: [Full medical explanation with diagrams]

### Test Case 2: Practical Care Question  
**User**: "How do I prevent pressure sores?"
**Voice** (8 sec): "Change positions every 2 hours and check your skin daily. Full prevention guide is on your screen."
**Screen**: [Detailed positioning schedules, risk area maps, equipment recommendations]

### Test Case 3: Emergency Situation
**User**: "Severe headache and sweating"
**Voice** (5 sec): "Sit up now and call 911 - possible AD emergency. Steps on screen."
**Screen**: [Emergency protocol with immediate actions]

## Backend Enhancement Suggestions

If the backend doesn't currently generate `voice_answer`, consider:

1. **Add voice summary generation** to the RAG pipeline
2. **Use a prompt template** like:
   ```
   Generate a 1-2 sentence conversational summary of this answer 
   suitable for voice output (10-15 seconds speaking time):
   [detailed_answer]
   ```

3. **Or use extraction**: Take first 1-2 sentences and add "Details on your screen"

## Benefits of This Architecture

1. **Optimal for each medium**: Voice is conversational, screen is comprehensive
2. **No cognitive overload**: User isn't processing voice while reading
3. **Accessibility**: Users can choose their preferred learning mode
4. **Efficiency**: Quick voice acknowledgment, detailed visual learning
5. **Natural interaction**: Voice sounds human, not robotic