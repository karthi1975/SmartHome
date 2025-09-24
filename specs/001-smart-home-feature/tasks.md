# Tasks: Smart Home Controller Feature

**Input**: Design documents from `/specs/001-smart-home-feature/`
**Prerequisites**: spec.md (available), plan.md (not available - using codebase analysis)
**Tech Stack**: Swift, SwiftUI, Vapi SDK, Home Assistant API, Zammad API

## Execution Flow (main)
```
1. Analyze existing codebase:
   → Swift/SwiftUI iOS app with multiple integrations
   → Vapi voice assistant integration
   → Home Assistant smart device control
   → Zammad ticketing system
2. Generate tasks by category:
   → Setup: project configuration, API keys
   → Tests: integration tests for each API
   → Core: models, services, view models
   → Integration: API clients, middleware
   → Polish: unit tests, UI animations, documentation
3. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
4. Number tasks sequentially (T001, T002...)
5. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Phase 3.1: Setup & Configuration
- [x] T001 Verify Xcode project builds successfully with existing dependencies
- [ ] T002 [P] Configure Home Assistant API credentials in SmartHomeController/HomeAssistantConfig.swift
- [ ] T003 [P] Configure Zammad API credentials in SmartHomeController/ZammadClient.swift
- [ ] T004 [P] Configure Vapi API keys and assistant IDs in SmartHomeController/CallManager.swift
- [ ] T005 Set up test environment configurations in SmartHomeController.xcodeproj

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [ ] T006 [P] Integration test Home Assistant connection in test_real_api.sh
- [ ] T007 [P] Integration test Vapi voice call flow in test_voice_trigger.sh
- [ ] T008 [P] Integration test Zammad ticket creation in test_manual_ticket.sh
- [ ] T009 [P] Integration test complete smart home flow in test_complete_flow.sh
- [ ] T010 [P] Unit test SmartDevice model in SmartHomeControllerTests/SmartDeviceTests.swift
- [ ] T011 [P] Unit test Room model in SmartHomeControllerTests/RoomTests.swift
- [ ] T012 [P] Unit test DeviceStore persistence in SmartHomeControllerTests/DeviceStoreTests.swift

## Phase 3.3: Core Models & Data Layer (ONLY after tests are failing)
- [ ] T013 [P] Enhance SmartDevice model with device capabilities in SmartHomeController/SmartDevice.swift
- [ ] T014 [P] Enhance Room model with device grouping in SmartHomeController/Room.swift
- [ ] T015 [P] Implement DeviceGroup for device collections in SmartHomeController/DeviceGroup.swift
- [ ] T016 [P] Implement Scene model for automation in SmartHomeController/Scene.swift
- [ ] T017 [P] Enhance DeviceHistory tracking in SmartHomeController/DeviceHistory.swift
- [ ] T018 Implement DeviceStore persistence layer in SmartHomeController/DeviceStore.swift
- [ ] T019 [P] Create DeviceTemplate for quick setup in SmartHomeController/DeviceTemplate.swift

## Phase 3.4: Service Layer & API Integration
- [ ] T020 Complete HomeAssistantClient device discovery in SmartHomeController/HomeAssistantClient.swift
- [ ] T021 Implement HomeAssistantClient state updates in SmartHomeController/HomeAssistantClient.swift
- [ ] T022 Enhance ZammadClient ticket management in SmartHomeController/ZammadClient.swift
- [ ] T023 Complete CallManager voice command processing in SmartHomeController/CallManager.swift
- [ ] T024 [P] Implement HomeAssistantDeviceDiscovery service in SmartHomeController/HomeAssistantDeviceDiscovery.swift
- [ ] T025 [P] Create HealthEducationAPI integration in SmartHomeController/HealthEducationAPI.swift

## Phase 3.5: View Models & Business Logic
- [ ] T026 [P] Implement AppState navigation logic in SmartHomeController/AppState.swift
- [ ] T027 [P] Create HealthEducationViewModel in SmartHomeController/HealthEducationViewModel.swift
- [ ] T028 [P] Create AnimatedTempCardViewModel in SmartHomeController/AnimatedTempCardViewModel.swift
- [ ] T029 Enhance DeviceStore with reactive updates in SmartHomeController/DeviceStore.swift

## Phase 3.6: UI Components & Views
- [ ] T030 [P] Complete RoomView with device grid in SmartHomeController/RoomView.swift
- [ ] T031 [P] Enhance DeviceCard with animations in SmartHomeController/DeviceCard.swift
- [ ] T032 [P] Complete AnimatedBlindsCard control in SmartHomeController/AnimatedBlindsCard.swift
- [ ] T033 [P] Complete AnimatedToasterCard control in SmartHomeController/AnimatedToasterCard.swift
- [ ] T034 [P] Implement FridgeCard with temperature in SmartHomeController/FridgeCard.swift
- [ ] T035 [P] Implement OvenCard with timer in SmartHomeController/OvenCard.swift
- [ ] T036 [P] Implement DishwasherCard with cycle in SmartHomeController/DishwasherCard.swift
- [ ] T037 Complete AddDeviceView discovery UI in SmartHomeController/AddDeviceView.swift
- [ ] T038 Enhance CreateTicketView form in SmartHomeController/CreateTicketView.swift
- [ ] T039 Complete SettingsView preferences in SmartHomeController/SettingsView.swift
- [ ] T040 Enhance SidebarView navigation in SmartHomeController/SidebarView.swift

## Phase 3.7: Voice & Animation Features
- [ ] T041 Complete MicrophoneAnimationView states in SmartHomeController/MicrophoneAnimationView.swift
- [ ] T042 Implement wake word detection in SmartHomeController/CallManager.swift
- [ ] T043 Add voice feedback animations in SmartHomeController/ContentView.swift
- [ ] T044 Implement Tree of Thought prompts in SmartHomeController/TreeOfThoughtPrompts.swift

## Phase 3.8: Special Room Views
- [ ] T045 [P] Complete EntranceView security features in SmartHomeController/EntranceView.swift
- [ ] T046 [P] Complete PlayroomView child safety in SmartHomeController/PlayroomView.swift
- [ ] T047 [P] Complete MasterView bedroom controls in SmartHomeController/MasterView.swift
- [ ] T048 Complete HomeControlsView dashboard in SmartHomeController/HomeControlsView.swift

## Phase 3.9: Integration & Middleware
- [ ] T049 Connect all device cards to HomeAssistantClient
- [ ] T050 Wire up voice commands to device actions in CallManager
- [ ] T051 Implement state synchronization between views
- [ ] T052 Add error handling and retry logic for API calls
- [ ] T053 [P] Implement ImagePicker for screenshots in SmartHomeController/ImagePicker.swift
- [ ] T054 [P] Implement ScreenshotHelper utility in SmartHomeController/ScreenshotHelper.swift

## Phase 3.10: Polish & Documentation
- [ ] T055 [P] Add loading states and spinners to all async operations
- [ ] T056 [P] Implement pull-to-refresh in device lists
- [ ] T057 [P] Add haptic feedback to device controls
- [ ] T058 [P] Create USER_INSTRUCTIONS.md with setup guide
- [ ] T059 [P] Update IMPLEMENTATION_SUMMARY.md with architecture
- [ ] T060 Run all test scripts and fix failures
- [ ] T061 Performance optimization for device list rendering
- [ ] T062 Memory leak detection and fixes
- [ ] T063 Accessibility features for VoiceOver support

## Dependencies
- Setup (T001-T005) must complete before all other tasks
- Tests (T006-T012) before implementation (T013-T054)
- Models (T013-T019) before services (T020-T025)
- Services before view models (T026-T029)
- View models before UI components (T030-T048)
- All implementation before polish (T055-T063)

## Parallel Execution Examples

### Launch all test scripts together:
```bash
# Run in parallel using Task agent
Task: "Integration test Home Assistant in test_real_api.sh"
Task: "Integration test Vapi voice in test_voice_trigger.sh"
Task: "Integration test Zammad tickets in test_manual_ticket.sh"
Task: "Integration test complete flow in test_complete_flow.sh"
```

### Launch model implementations together:
```bash
# Different files, can run in parallel
Task: "Enhance SmartDevice model in SmartHomeController/SmartDevice.swift"
Task: "Enhance Room model in SmartHomeController/Room.swift"
Task: "Implement DeviceGroup in SmartHomeController/DeviceGroup.swift"
Task: "Implement Scene model in SmartHomeController/Scene.swift"
```

### Launch UI components together:
```bash
# Independent view files
Task: "Complete AnimatedBlindsCard in SmartHomeController/AnimatedBlindsCard.swift"
Task: "Complete AnimatedToasterCard in SmartHomeController/AnimatedToasterCard.swift"
Task: "Implement FridgeCard in SmartHomeController/FridgeCard.swift"
Task: "Implement OvenCard in SmartHomeController/OvenCard.swift"
```

## Notes
- [P] tasks = different files, no shared dependencies
- Verify tests fail before implementing features
- Commit after each completed task
- Use Xcode simulator for UI testing
- Test voice features with actual Vapi calls
- Validate Home Assistant integration with real devices if available

## Validation Checklist
*GATE: Checked before execution*

- [x] All APIs have corresponding integration tests
- [x] All models have unit test tasks
- [x] All tests come before implementation
- [x] Parallel tasks are truly independent
- [x] Each task specifies exact file path
- [x] No task modifies same file as another [P] task
- [x] Voice integration tasks properly sequenced
- [x] UI components can be developed independently

## Current Implementation Status
Based on codebase analysis:
- ✅ Basic project structure exists
- ✅ Vapi integration partially implemented
- ✅ Home Assistant client stubbed
- ✅ Zammad client implemented
- ⚠️ Device discovery incomplete
- ⚠️ Many UI components need completion
- ⚠️ Test coverage minimal
- ⚠️ Voice command processing needs enhancement