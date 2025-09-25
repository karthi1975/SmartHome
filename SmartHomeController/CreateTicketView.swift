import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

enum TicketPriority: String, CaseIterable, Identifiable {
    case low = "1 low"
    case normal = "2 normal"
    case high = "3 high"

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "Urgent"
        }
    }

    var color: Color {
        switch self {
        case .low: return .blue
        case .normal: return .orange
        case .high: return .red
        }
    }

    var icon: String {
        switch self {
        case .low: return "tortoise.fill"
        case .normal: return "hare.fill"
        case .high: return "exclamationmark.triangle.fill"
        }
    }

    var animationScale: CGFloat {
        switch self {
        case .low: return 0.95
        case .normal: return 1.05
        case .high: return 1.15
        }
    }
}

struct AnimatedPriorityButton: View {
    let priority: TicketPriority
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false
    @State private var animateGlow = false
    @State private var rotationAngle: Double = 0
    @State private var bounceScale: CGFloat = 1.0

    var body: some View {
        Button(action: {
            // Trigger animation
            if priority == .low {
                withAnimation(.spring(response: 0.5)) {
                    bounceScale = 1.2
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.5)) {
                        bounceScale = 1.0
                    }
                }
            } else if priority == .normal {
                withAnimation(.spring(response: 0.4)) {
                    rotationAngle += 180
                }
            } else {
                withAnimation(.spring(response: 0.2)) {
                    rotationAngle = 10
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.2)) {
                        rotationAngle = -10
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.2)) {
                        rotationAngle = 0
                    }
                }
            }

            action()

            // Haptic feedback
            let style: UIImpactFeedbackGenerator.FeedbackStyle = priority == .high ? .heavy : (priority == .normal ? .medium : .light)
            let impact = UIImpactFeedbackGenerator(style: style)
            impact.impactOccurred()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    // Multiple animated circles for urgency levels
                    if priority == .high && isSelected {
                        // Pulsing danger rings for urgent
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .stroke(Color.red.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                                .frame(width: 60 + CGFloat(index * 15), height: 60 + CGFloat(index * 15))
                                .scaleEffect(animateGlow ? 1.3 : 1.0)
                                .opacity(animateGlow ? 0 : 0.8)
                                .animation(
                                    .easeOut(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.2),
                                    value: animateGlow
                                )
                        }
                    }

                    // Animated background circle
                    Circle()
                        .fill(priority.color.opacity(isSelected ? 0.2 : 0.05))
                        .frame(width: 60, height: 60)
                        .scaleEffect(isSelected ? 1.1 * bounceScale : 1.0)
                        .overlay(
                            Circle()
                                .stroke(priority.color, lineWidth: isSelected ? 3 : 1)
                                .scaleEffect(animateGlow && isSelected ? 1.2 : 1.0)
                                .opacity(animateGlow && isSelected ? 0 : 1)
                        )

                    // Icon with priority-specific animation
                    Image(systemName: priority.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(isSelected ? priority.color : .gray)
                        .scaleEffect(isPressed ? 0.9 : (isSelected ? priority.animationScale : 1.0))
                        .rotationEffect(.degrees(rotationAngle))
                }

                Text(priority.displayName)
                    .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? priority.color : .gray)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                // Start continuous animation for selected state
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    animateGlow = true
                }

                // Different selection feedback for each priority
                switch priority {
                case .low:
                    // Gentle notification
                    let notification = UINotificationFeedbackGenerator()
                    notification.notificationOccurred(.success)
                case .normal:
                    // Medium feedback
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                case .high:
                    // Strong warning feedback
                    let notification = UINotificationFeedbackGenerator()
                    notification.notificationOccurred(.warning)
                }
            } else {
                animateGlow = false
            }
        }
    }
}

struct CreateTicketView: View {
    @EnvironmentObject var appState: AppState
    @State private var subject = ""
    @State private var description = ""
    @State private var customerEmail = "karthi@tetradapt.us"
    @State private var isSubmitting = false
    @State private var resultMessage: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var priority: TicketPriority = .normal
    @State private var showPriorityAnimation = false
    @State private var showPrioritySelection = false
    @State private var autoSubmitCountdown = 5
    @State private var autoSubmitTimer: Timer?
    @State private var voiceCommand: String = ""
    @State private var showVoiceConfirmation = false
    @State private var subjectFieldFocused = false
    @State private var descriptionFieldFocused = false
    @State private var emailFieldFocused = false
    @State private var buttonPressed = false
    @State private var showFieldAnimation = false
    
    @State private var showAttachmentOptions = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var isDropTargeted = false
    @State private var ticketHistory: [Ticket] = []
    @State private var isLoadingHistory = false
    @State private var isVoiceGuided = false
    @State private var voiceGuidedStep = ""
    @State private var showSubmitAnimation = false

    // Text animation states
    @State private var animatedSubject = ""
    @State private var animatedDescription = ""
    @State private var isAnimatingSubject = false
    @State private var isAnimatingDescription = false

    private var displayTickets: [Ticket] {
        return ticketHistory
    }
    

    
    private func stateColor(for stateId: Int) -> Color {
        switch stateId {
        case 1: return .blue    // New
        case 2: return .orange  // Open
        case 3: return .yellow  // Pending
        case 4: return .green   // Closed
        default: return .gray
        }
    }

    @ViewBuilder
    private var voiceGuidedIndicator: some View {
        if isVoiceGuided && !voiceGuidedStep.isEmpty {
            HStack(spacing: 12) {
                // Removed MicrophoneAnimationView to prevent duplicate
                // The GlobalMicrophoneOverlay already shows the microphone animation
                Image(systemName: "mic.fill")
                    .foregroundColor(.blue)
                    .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Voice Assistant")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(voiceGuidedStep)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
            .transition(.asymmetric(
                insertion: .scale(scale: 0.9).combined(with: .opacity),
                removal: .scale(scale: 0.9).combined(with: .opacity)
            ))
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Voice Guided Indicator
                voiceGuidedIndicator

                // Voice Command Confirmation
                if showVoiceConfirmation && !voiceCommand.isEmpty {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                                .symbolEffect(.pulse)
                            Text("Voice Command Received")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }

                        Text("\"\(voiceCommand)\"")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .italic()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        if showPrioritySelection {
                            Text("Select Priority Level")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .transition(.opacity)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
                }

                // Ticket Creation Form
                VStack(spacing: 16) {
                    // Subject with animation
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Subject")
                                .font(.headline)
                            if subjectFieldFocused {
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 14))
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        TextField("Enter ticket subject", text: $subject, onEditingChanged: { editing in
                            withAnimation(.spring(response: 0.3)) {
                                subjectFieldFocused = editing
                                if editing {
                                    showFieldAnimation = true
                                    // Haptic feedback on focus
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                }
                            }
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .scaleEffect(subjectFieldFocused ? 1.02 : 1.0)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(subjectFieldFocused ? Color.blue : Color.clear, lineWidth: 2)
                                .animation(.spring(response: 0.3), value: subjectFieldFocused)
                        )
                    }
                    
                    // Description with animation
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Description")
                                .font(.headline)
                            if descriptionFieldFocused {
                                Image(systemName: "text.alignleft")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 14))
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        ZStack(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("Describe the issue...")
                                    .foregroundColor(.gray.opacity(0.5))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                            }
                            TextEditor(text: $description)
                                .frame(height: 100)
                                .opacity(description.isEmpty ? 0.25 : 1)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        descriptionFieldFocused = true
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                    }
                                }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(descriptionFieldFocused ? Color.orange : Color(.systemGray4), lineWidth: descriptionFieldFocused ? 2 : 1)
                                .animation(.spring(response: 0.3), value: descriptionFieldFocused)
                        )
                        .scaleEffect(descriptionFieldFocused ? 1.01 : 1.0)
                        .animation(.spring(response: 0.3), value: descriptionFieldFocused)
                    }
                    .onTapGesture {
                        // Dismiss focus from other fields
                        descriptionFieldFocused = true
                        subjectFieldFocused = false
                        emailFieldFocused = false
                    }
                    
                    // Email with animation
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Your Email")
                                .font(.headline)
                            if emailFieldFocused {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 14))
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        TextField("Enter your email", text: $customerEmail, onEditingChanged: { editing in
                            withAnimation(.spring(response: 0.3)) {
                                emailFieldFocused = editing
                                if editing {
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                }
                            }
                        })
                        .keyboardType(.emailAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .scaleEffect(emailFieldFocused ? 1.02 : 1.0)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(emailFieldFocused ? Color.green : Color.clear, lineWidth: 2)
                                .animation(.spring(response: 0.3), value: emailFieldFocused)
                        )
                    }
                    
                    // Priority with animated selection
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Priority")
                                .font(.headline)

                            Spacer()

                            // Priority indicator
                            if showPriorityAnimation {
                                HStack(spacing: 4) {
                                    Image(systemName: priority.icon)
                                        .foregroundColor(priority.color)
                                        .font(.system(size: 14))
                                    Text("\(priority.displayName) Priority Selected")
                                        .font(.caption)
                                        .foregroundColor(priority.color)
                                        .bold()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(priority.color.opacity(0.1))
                                .cornerRadius(12)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }

                        HStack(spacing: 12) {
                            ForEach(TicketPriority.allCases) { p in
                                AnimatedPriorityButton(
                                    priority: p,
                                    isSelected: priority == p,
                                    action: {
                                        priority = p
                                        withAnimation(.spring(response: 0.3)) {
                                            showPriorityAnimation = true
                                        }

                                        // Hide animation after delay
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            withAnimation {
                                                showPriorityAnimation = false
                                            }
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                        )
                    }
                    
                    // Image Attachment
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Attachment (Optional)")
                            .font(.headline)
                        
                        if let image = selectedImage {
                            VStack(spacing: 8) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .cornerRadius(8)
                                
                                Button("Remove Image") {
                                    selectedImage = nil
                                    selectedPhotoItem = nil
                                }
                                .foregroundColor(.red)
                            }
                        } else {
                            Button(action: { showAttachmentOptions = true }) {
                                HStack {
                                    Image(systemName: "photo")
                                    Text("Add Image")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                            }
                        }
                    }

                    // Submit Button with animation
                    Button(action: {
                        if !isVoiceGuided {
                            submit()
                        }
                    }) {
                        if isSubmitting {
                            HStack(spacing: 12) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Creating Ticket...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                        } else {
                            Text("Submit Ticket")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(showSubmitAnimation ? Color.green : (buttonPressed ? Color.blue.opacity(0.8) : Color.blue))
                                .cornerRadius(12)
                                .scaleEffect(buttonPressed ? 0.95 : 1.0)
                        }
                    }
                    .disabled(subject.isEmpty || description.isEmpty || isSubmitting)
                    .opacity(subject.isEmpty || description.isEmpty ? 0.5 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonPressed)
                    .animation(.spring(response: 0.3), value: showSubmitAnimation)
                    
                    // Result Message with Animation
                    if let resultMessage = resultMessage {
                        HStack {
                            Image(systemName: resultMessage.contains("success") ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(resultMessage.contains("success") ? .green : .red)
                                .rotationEffect(.degrees(resultMessage.contains("success") ? 360 : 0))
                                .animation(.spring(response: 0.5), value: resultMessage)

                            Text(resultMessage)
                                .foregroundColor(resultMessage.contains("success") ? .green : .red)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(resultMessage.contains("success") ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(resultMessage.contains("success") ? Color.green : Color.red, lineWidth: 1)
                                )
                        )
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                        .onAppear {
                            if resultMessage.contains("success") {
                                // Success haptic
                                let notification = UINotificationFeedbackGenerator()
                                notification.notificationOccurred(.success)

                                // Auto-dismiss success message after 3 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation {
                                        self.resultMessage = nil
                                    }
                                }
                            } else {
                                // Error haptic
                                let notification = UINotificationFeedbackGenerator()
                                notification.notificationOccurred(.error)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)

                // Real Zammad Tickets Display
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Support Tickets")
                            .font(.title2)
                            .bold()
                        Spacer()
                        if isLoadingHistory {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("\(displayTickets.count) tickets")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if isLoadingHistory {
                        HStack {
                            Spacer()
                            ProgressView("Loading tickets...")
                            Spacer()
                        }
                        .padding()
                    } else if displayTickets.isEmpty {
                        VStack(spacing: 8) {
                            Text("No tickets found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Create your first support ticket above")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(displayTickets, id: \.id) { ticket in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(ticket.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Text("State: \(ticket.state)")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(stateColor(for: ticket.stateId))
                                        .cornerRadius(8)
                                    
                                    Spacer()
                                    
                                    Text("ID: #\(ticket.id)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("Created: \(formatDate(ticket.createdAt))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(stateColor(for: ticket.stateId).opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }
            .padding()
        }
        .navigationTitle("Create Ticket")
        .confirmationDialog("Add Attachment", isPresented: $showAttachmentOptions, titleVisibility: .visible) {
            Button("Choose from Library") {
                self.showPhotoLibrary = true
            }
            Button("Take Photo") {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    self.showCamera = true
                } else {
                    print("Camera not available on this device.")
                }
            }
            Button("Take Screenshot") {
                self.selectedImage = takeScreenshot()
            }
        }
        .photosPicker(isPresented: $showPhotoLibrary, selection: $selectedPhotoItem, matching: .images)
        .sheet(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera, selectedImage: $selectedImage)
        }
        .onChange(of: selectedPhotoItem) {
            Task {
                if let data = try? await selectedPhotoItem?.loadTransferable(type: Data.self) {
                    selectedImage = UIImage(data: data)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 4) {
                    Image("tetradapt-main-logo-BLKWHT")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 22)
                    Text("TETR")
                        .font(.system(size: 22, weight: .bold, design: .default))
                        .foregroundColor(.black)
                }
                .padding(.leading, 8)
            }
        }
        .onAppear {
            print("[DEBUG] 📱 CreateTicketView appeared - setting up listeners")
            loadTicketHistory()
            setupVoiceGuidedListeners()
            print("[DEBUG] 📱 Listeners setup complete")

            // Check if there are pending ticket details from voice command
            if let details = appState.pendingTicketDetails {
                print("[DEBUG] 📱 CreateTicketView: Loading voice command ticket details")
                print("[DEBUG] Subject: \(details.subject)")
                print("[DEBUG] Description: \(details.description)")
                print("[DEBUG] Voice Command: \(details.voiceCommand)")
                print("[DEBUG] Priority: \(details.priority)")

                // Populate the form fields
                withAnimation(.spring(response: 0.5)) {
                    self.subject = details.subject
                    self.description = details.description
                    self.voiceCommand = details.voiceCommand
                    self.showVoiceConfirmation = true

                    // Set priority based on voice command
                    if details.priority == "high" {
                        self.priority = .high
                    } else if details.priority == "low" {
                        self.priority = .low
                    } else {
                        self.priority = .normal
                    }
                }

                // Always ensure email is set
                if self.customerEmail.isEmpty || self.customerEmail == "user@homeadapt.us" {
                    self.customerEmail = "karthi@tetradapt.us"
                }
                print("[DEBUG] Email set to: \(self.customerEmail)")

                // Show priority selection with animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.spring(response: 0.5)) {
                        self.showPrioritySelection = true
                        self.showPriorityAnimation = true
                    }

                    // Pulse effect for priority buttons
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.animatePriorityButtons()
                    }
                }

                // Start auto-submit countdown after priority is selected
                self.startAutoSubmitCountdown()

                // Clear the pending details from AppState
                appState.pendingTicketDetails = nil
            }
        }
    }

    func submit() {
        // Cancel auto-submit timer if active
        autoSubmitTimer?.invalidate()
        autoSubmitTimer = nil

        isSubmitting = true
        resultMessage = nil

        // Add animation for submission
        withAnimation(.spring(response: 0.3)) {
            showVoiceConfirmation = false
        }

        let attachmentData = selectedImage?.jpegData(compressionQuality: 0.8)
        ZammadClient.shared.createTicket(subject: subject, body: description, customer: customerEmail.lowercased(), priority: priority.rawValue, attachment: attachmentData) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success:
                    withAnimation(.spring(response: 0.5)) {
                        resultMessage = "Ticket created successfully!"
                    }

                    // Clear form after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            subject = ""
                            description = ""
                            customerEmail = ""
                            selectedPhotoItem = nil
                            selectedImage = nil
                            voiceCommand = ""
                            showPrioritySelection = false
                            priority = .normal
                        }
                    }
                    loadTicketHistory()
                case .failure(let error):
                    resultMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func animatePriorityButtons() {
        // Create a pulse effect for priority selection
        for _ in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...0.3)) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    // This triggers re-render of priority buttons
                    self.showPriorityAnimation.toggle()
                }
            }
        }
    }

    private func startAutoSubmitCountdown() {
        autoSubmitCountdown = 5
        autoSubmitTimer?.invalidate()

        // Wait for priority selection first
        autoSubmitTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if self.priority != .normal || self.showPriorityAnimation {
                // Priority has been selected
                self.autoSubmitCountdown -= 1

                if self.autoSubmitCountdown <= 0 {
                    timer.invalidate()
                    // Auto-submit if all fields are filled
                    if !self.subject.isEmpty && !self.description.isEmpty && !self.customerEmail.isEmpty {
                        self.submit()
                    }
                }
            }
        }
    }
    

    private func loadTicketHistory() {
        isLoadingHistory = true
        print("DEBUG: Starting to load ticket history...")
        
        // For testing, let's also fetch all tickets without user filtering first
        ZammadClient.shared.fetchAllTickets { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let tickets):
                    print("DEBUG: Fetched \(tickets.count) total tickets from API")
                    // Show all tickets for now to see if any exist
                    self.ticketHistory = tickets.sorted(by: { $0.createdAt > $1.createdAt })
                    print("DEBUG: Showing all tickets: \(self.ticketHistory.count)")
                    self.isLoadingHistory = false
                case .failure(let error):
                    print("DEBUG: Error fetching tickets: \(error.localizedDescription)")
                    self.ticketHistory = []
                    self.isLoadingHistory = false
                }
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        return dateString
    }

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df
    }()
    
    private func takeScreenshot() -> UIImage? {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow }) else {
            return nil
        }

        let renderer = UIGraphicsImageRenderer(size: window.bounds.size)
        return renderer.image { context in
            window.layer.render(in: context.cgContext)
        }
    }

    private func setupVoiceGuidedListeners() {
        print("[DEBUG] 🎧 Setting up voice-guided listeners in CreateTicketView")

        // Listen for voice-guided form updates
        NotificationCenter.default.addObserver(
            forName: .voiceGuidedTicketUpdate,
            object: nil,
            queue: .main
        ) { notification in
            print("[DEBUG] 📨 ====== NOTIFICATION RECEIVED ======")
            print("[DEBUG] 📨 Notification name: voiceGuidedTicketUpdate")
            guard let userInfo = notification.userInfo else {
                print("[DEBUG] ❌ No userInfo in voiceGuidedTicketUpdate notification")
                return
            }
            print("[DEBUG] 📨 UserInfo received: \(userInfo)")
            print("[DEBUG] 📨 =====================================")

            // Check which field to animate
            let animateField = userInfo["animateField"] as? String

            // Animate subject field
            if let subject = userInfo["subject"] as? String,
               animateField == "subject" {
                self.animatedSubject = ""
                // Set the subject directly without animation to avoid corruption
                self.subject = subject
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.subjectFieldFocused = true
                    self.isVoiceGuided = true
                    self.voiceGuidedStep = "Filling subject..."
                }
                // Skip animation for now to avoid text corruption
                // animateText(subject, to: \.subject, animatedTo: \.animatedSubject, isAnimating: \.isAnimatingSubject)

                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        self.subjectFieldFocused = false
                    }
                }
            }

            // Animate description field
            if let description = userInfo["description"] as? String,
               animateField == "description" {
                self.animatedDescription = ""
                // Set the description directly without animation to avoid corruption
                self.description = description
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.descriptionFieldFocused = true
                    self.voiceGuidedStep = "Adding description..."
                }
                // Skip animation for now to avoid text corruption
                // animateText(description, to: \.description, animatedTo: \.animatedDescription, isAnimating: \.isAnimatingDescription)

                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        self.descriptionFieldFocused = false
                        self.voiceGuidedStep = "Details captured"
                    }
                }
            }

            // Animate priority selection
            if let priorityStr = userInfo["priority"] as? String,
               userInfo["animatePriority"] as? Bool == true {
                print("[DEBUG] 🎫 Animating priority selection: \(priorityStr)")

                // Set the priority based on voice input
                let newPriority: TicketPriority
                switch priorityStr.lowercased() {
                case "high", "urgent":
                    newPriority = .high
                case "low":
                    newPriority = .low
                default:
                    newPriority = .normal
                }

                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.voiceGuidedStep = "Setting priority to \(newPriority.displayName)..."
                    self.showPrioritySelection = true
                    self.showPriorityAnimation = true
                    self.priority = newPriority
                }

                // Visual and haptic feedback for priority
                let impact = UIImpactFeedbackGenerator(style: newPriority == .high ? .heavy : .medium)
                impact.impactOccurred()

                // Additional animation for urgent priority
                if newPriority == .high {
                    // Pulse animation for urgent
                    withAnimation(.easeInOut(duration: 0.3).repeatCount(2, autoreverses: true)) {
                        self.showPriorityAnimation = true
                    }
                }

                // Update step after delay with confirmation
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.voiceGuidedStep = "Priority set to \(self.priority.displayName)"

                        // Keep the priority visible but stop extra animations
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation {
                                self.showPriorityAnimation = false
                            }
                        }
                    }
                }
            }
        }

        // Listen for voice command to submit ticket (when user says "submit" or "send it")
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SubmitTicketVoiceCommand"),
            object: nil,
            queue: .main
        ) { _ in
            print("[DEBUG] 🎫 Voice command to submit ticket received")

            // Check if form is filled
            if !self.subject.isEmpty && !self.description.isEmpty && !self.customerEmail.isEmpty {
                // Trigger submission
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self.isVoiceGuided = true
                    self.voiceGuidedStep = "Submitting ticket..."
                    self.showSubmitAnimation = true
                    self.buttonPressed = true
                }

                // Actually submit after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.submit()
                }
            } else {
                print("[DEBUG] ❌ Form not complete, cannot submit")
            }
        }

        // Listen for voice-guided submission
        NotificationCenter.default.addObserver(
            forName: .voiceGuidedTicketSubmit,
            object: nil,
            queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo else {
                print("[DEBUG] ❌ No userInfo in voiceGuidedTicketSubmit notification")
                return
            }
            print("[DEBUG] 📨 Received voiceGuidedTicketSubmit: \(userInfo)")

            // Set form data if provided
            if let subject = userInfo["subject"] as? String {
                self.subject = subject
            }
            if let description = userInfo["description"] as? String {
                self.description = description
            }
            if let email = userInfo["email"] as? String {
                self.customerEmail = email
            }
            if let priorityStr = userInfo["priority"] as? String {
                switch priorityStr {
                case "high":
                    self.priority = .high
                case "low":
                    self.priority = .low
                default:
                    self.priority = .normal
                }
            }

            // Check if we should animate the button
            let shouldAnimateButton = userInfo["animateButton"] as? Bool ?? false

            if shouldAnimateButton {
                // Show voice guided indicator
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self.isVoiceGuided = true
                    self.voiceGuidedStep = "Submitting ticket to support system..."
                }

                // Animate submit button
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    self.showSubmitAnimation = true
                    self.buttonPressed = true
                }

                // Strong haptic feedback
                let notification = UINotificationFeedbackGenerator()
                notification.notificationOccurred(.success)

                // Simulate button press animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.2)) {
                        self.buttonPressed = false
                    }
                }

                // Submit the ticket with animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.simulateButtonPress()

                    // Update status during submission
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            self.voiceGuidedStep = "Creating ticket in Zammad..."
                        }
                    }

                    // Reset voice guided state after submission completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        withAnimation {
                            self.isVoiceGuided = false
                            self.voiceGuidedStep = ""
                            self.showSubmitAnimation = false
                        }
                    }
                }
            }
        }
    }

    private func animateText(_ text: String, to keyPath: WritableKeyPath<CreateTicketView, String>,
                           animatedTo animatedKeyPath: WritableKeyPath<CreateTicketView, String>,
                           isAnimating animatingKeyPath: WritableKeyPath<CreateTicketView, Bool>) {
        // Clear the fields and start animation
        isAnimatingSubject = (animatingKeyPath == \.isAnimatingSubject)
        isAnimatingDescription = (animatingKeyPath == \.isAnimatingDescription)

        if isAnimatingSubject {
            animatedSubject = ""
            subject = ""
        } else if isAnimatingDescription {
            animatedDescription = ""
            description = ""
        }

        let characters = Array(text)
        var currentIndex = 0

        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if currentIndex < characters.count {
                withAnimation(.easeInOut(duration: 0.1)) {
                    if self.isAnimatingSubject {
                        self.animatedSubject.append(characters[currentIndex])
                        self.subject = self.animatedSubject
                    } else if self.isAnimatingDescription {
                        self.animatedDescription.append(characters[currentIndex])
                        self.description = self.animatedDescription
                    }
                }
                currentIndex += 1

                // Add haptic feedback periodically
                if currentIndex % 5 == 0 {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
            } else {
                timer.invalidate()
                if self.isAnimatingSubject {
                    self.isAnimatingSubject = false
                } else if self.isAnimatingDescription {
                    self.isAnimatingDescription = false
                }
                // Final haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            }
        }
    }

    private func simulateButtonPress() {
        // Animate button press
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            self.buttonPressed = true
        }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                self.buttonPressed = false
            }

            // Actually submit the ticket
            self.submit()
        }
    }
}

 