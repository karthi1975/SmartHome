import SwiftUI

struct HealthEducationView: View {
    @StateObject private var viewModel = HealthEducationViewModel.shared
    @EnvironmentObject var callManager: CallManager
    @State private var showingTopics = false
    @State private var showingSettings = false
    @FocusState private var isInputFocused: Bool
    @State private var hasNewContent = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Messages with new content indicator
            ZStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message, viewModel: viewModel)
                                    .id(message.id)
                            }
                            
                            if viewModel.isLoading {
                                LoadingBubble()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                // New Content Indicator
                if hasNewContent {
                    VStack {
                        HStack {
                            Spacer()
                            Text("📍 New content available")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(red: 172/255, green: 32/255, blue: 41/255))
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(radius: 4)
                                .scaleEffect(hasNewContent ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: hasNewContent)
                            Spacer()
                        }
                        .padding(.top, 8)
                        Spacer()
                    }
                }
            }
            
            // Suggested questions (if no messages yet)
            if viewModel.messages.count <= 1 {
                suggestedQuestionsView
            }
            
            // Input area
            inputArea
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .onAppear {
            print("[DEBUG] 👁️ HealthEducationView appeared")
            print("[DEBUG] 👁️ Current messages count: \(viewModel.messages.count)")
            print("[DEBUG] 👁️ Is configured: \(viewModel.isConfigured)")
            
            viewModel.setCallManager(callManager)
            viewModel.checkConfiguration()
            
            // CRITICAL: Set current page and context for voice recognition
            callManager.currentPage = "health education"
            callManager.switchToHealthEducationContext()
            print("[DEBUG] 👁️🎯 Set page to 'health education' and switched context")
            
            // Post notification that we're on health education page
            NotificationCenter.default.post(name: .pageChanged, object: "Health Education")
        }
        .onChange(of: viewModel.messages.count) { newCount in
            print("[DEBUG] 👁️ Messages count changed to: \(newCount)")
            if newCount > 0 {
                print("[DEBUG] 👁️ Last message is from user: \(viewModel.messages.last?.isUser ?? false)")
                print("[DEBUG] 👁️ Last message content: \(viewModel.messages.last?.content ?? "nil")")
                print("[DEBUG] 👁️ Last message has images: \(viewModel.messages.last?.images != nil)")
                print("[DEBUG] 👁️ Last message images count: \(viewModel.messages.last?.images?.count ?? 0)")
                
                // Show new content indicator for assistant messages
                if let lastMessage = viewModel.messages.last, !lastMessage.isUser {
                    withAnimation {
                        hasNewContent = true
                    }
                    // Hide indicator after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            hasNewContent = false
                        }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Re-check configuration when app comes to foreground
            viewModel.checkConfiguration()
        }
        .sheet(isPresented: $showingTopics) {
            TopicsSheet(topics: viewModel.topics)
        }
        .sheet(isPresented: $showingSettings) {
            HealthEducationSettingsView()
                .onDisappear {
                    viewModel.checkConfiguration()
                }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
            if viewModel.messages.last?.isUser == true {
                Button("Retry") {
                    viewModel.retryLastMessage()
                }
            }
        } message: {
            Text(viewModel.error ?? "")
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Health Education")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Ask questions about SCI care")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.isConfigured ? .secondary : Color(red: 172/255, green: 32/255, blue: 41/255))
                        .overlay(
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 8, y: -8)
                                .opacity(viewModel.isConfigured ? 0 : 1)
                        )
                }
                
                Button(action: { showingTopics = true }) {
                    Image(systemName: "list.bullet")
                        .font(.title2)
                        .foregroundColor(Color(red: 172/255, green: 32/255, blue: 41/255))
                }
                .disabled(!viewModel.isConfigured)
                
                // Test button - DIRECT API TEST
                Button(action: {
                    print("[DEBUG] 🧪🔴 TEST BUTTON PRESSED - DIRECT API CALL")
                    
                    // Method 1: Direct message processing
                    let testQuery = "What is autonomic dysreflexia?"
                    print("[DEBUG] 🧪 Sending test query: '\(testQuery)'")
                    viewModel.handleUserMessage(testQuery)
                    
                    // Method 2: All other tests after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        print("[DEBUG] 🧪 Running additional tests")
                        viewModel.testUIUpdate()
                        viewModel.testVoiceResponse()
                        viewModel.testRESTAPI()
                        viewModel.testCompleteVoiceFlow()
                    }
                }) {
                    Image(systemName: "testtube.2")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Button(action: { viewModel.clearChat() }) {
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 2)
    }
    
    // MARK: - Suggested Questions
    private var suggestedQuestionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggested Questions:")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.suggestedQuestions, id: \.self) { question in
                        Button(action: {
                            viewModel.currentInput = question
                            viewModel.sendMessage()
                        }) {
                            Text(question)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(red: 172/255, green: 32/255, blue: 41/255).opacity(0.1))
                                .foregroundColor(Color(red: 172/255, green: 32/255, blue: 41/255))
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Input Area
    private var inputArea: some View {
        VStack(spacing: 0) {
            if viewModel.showVoiceAnimation {
                VoiceInputAnimation(transcribedText: viewModel.transcribedText, isProcessing: viewModel.isLoading)
                    .frame(height: 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            HStack(spacing: 12) {
                // Voice input button
                Button(action: {
                    if viewModel.isListening {
                        viewModel.stopVoiceInput()
                    } else {
                        viewModel.startVoiceInput()
                    }
                }) {
                    Image(systemName: viewModel.isListening ? "mic.fill" : "mic")
                        .font(.title2)
                        .foregroundColor(viewModel.isListening ? .red : Color(red: 172/255, green: 32/255, blue: 41/255))
                        .scaleEffect(viewModel.isListening ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: viewModel.isListening)
                }
                
                // Text input
                HStack {
                    TextField("Ask a health question...", text: $viewModel.currentInput)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($isInputFocused)
                        .onSubmit {
                            viewModel.sendMessage()
                        }
                    
                    if !viewModel.currentInput.isEmpty {
                        Button(action: {
                            viewModel.currentInput = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                
                // Send button
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundColor(viewModel.currentInput.isEmpty ? .gray : Color(red: 172/255, green: 32/255, blue: 41/255))
                }
                .disabled(viewModel.currentInput.isEmpty || viewModel.isLoading)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .animation(.spring(), value: viewModel.showVoiceAnimation)
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: HealthChatMessage
    let viewModel: HealthEducationViewModel
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                // Main text content
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(message.isUser ? Color(red: 172/255, green: 32/255, blue: 41/255) : Color(.systemGray5))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(16)
                    .textSelection(.enabled)  // Allow text selection for copying
                    .onAppear {
                        if !message.isUser {
                            print("[DEBUG] MessageBubble appeared for assistant message:")
                            print("  - Content length: \(message.content.count) chars")
                            print("  - Has decodedImages: \(message.decodedImages != nil)")
                            print("  - DecodedImages count: \(message.decodedImages?.count ?? 0)")
                            print("  - Has images metadata: \(message.images != nil)")
                            print("  - Images metadata count: \(message.images?.count ?? 0)")
                        }
                    }
                
                // Images with metadata
                if let imageMetadata = message.images, !imageMetadata.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        if let decodedImages = message.decodedImages, !decodedImages.isEmpty {
                            // Display decoded images
                            if decodedImages.count == 1 {
                            // Single image - show full width
                            if let imageData = decodedImages.first,
                               let metadata = imageMetadata.first,
                               let uiImage = UIImage(data: imageData) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 300)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color(.systemGray4), lineWidth: 1)
                                        )
                                    
                                    // Image metadata
                                    if let description = metadata.description {
                                        Text(description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack(spacing: 12) {
                                        if let pageNumber = metadata.pageNumber {
                                            Label("Page \(pageNumber)", systemImage: "doc.text")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        if let source = metadata.documentSource {
                                            Text(source)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        } else if decodedImages.count == 2 {
                            // Two images - show side by side
                            HStack(spacing: 8) {
                                ForEach(Array(zip(decodedImages, imageMetadata).enumerated()), id: \.offset) { index, pair in
                                    let (imageData, metadata) = pair
                                    if let uiImage = UIImage(data: imageData) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(maxHeight: 200)
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                                )
                                            
                                            if let description = metadata.description {
                                                Text(description)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(2)
                                            }
                                        }
                                    } else {
                                        // Debug: Print why image failed to display
                                        Text("Failed to display image \(index + 1)")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .onAppear {
                                                print("[DEBUG] Failed to display image \(index + 1):")
                                                print("  - Image data size: \(imageData.count) bytes")
                                                print("  - Can create UIImage: \(UIImage(data: imageData) != nil)")
                                            }
                                    }
                                }
                            }
                        } else {
                            // Three or more images - scrollable
                            ScrollView(.horizontal, showsIndicators: true) {
                                HStack(spacing: 12) {
                                    ForEach(Array(zip(decodedImages, imageMetadata).enumerated()), id: \.offset) { index, pair in
                                        let (imageData, metadata) = pair
                                        VStack(alignment: .leading, spacing: 4) {
                                            if let uiImage = UIImage(data: imageData) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 200, height: 200)
                                                    .cornerRadius(8)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                                    )
                                            } else {
                                                // Debug: Print why image failed to display
                                                Text("Failed to display image \(index + 1)")
                                                    .font(.caption)
                                                    .foregroundColor(.red)
                                                    .onAppear {
                                                        print("[DEBUG] Failed to display scrollable image \(index + 1):")
                                                        print("  - Image data size: \(imageData.count) bytes")
                                                        print("  - Can create UIImage: \(UIImage(data: imageData) != nil)")
                                                    }
                                            }
                                            
                                            // Compact metadata for scrollable view
                                            if let description = metadata.description {
                                                Text(description)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(2)
                                                    .frame(width: 200)
                                            }
                                            
                                            if let pageNumber = metadata.pageNumber {
                                                Text("Page \(pageNumber)")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                            .frame(height: 250)
                        }
                        } else {
                            // Show placeholder when images are expected but not decoded
                            HStack {
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text("Loading \(imageMetadata.count) image(s)...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            
                            // Show image descriptions even if images failed to load
                            ForEach(Array(imageMetadata.enumerated()), id: \.offset) { index, metadata in
                                VStack(alignment: .leading, spacing: 4) {
                                    if let filename = metadata.filename {
                                        Text("📄 \(filename)")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                    }
                                    if let description = metadata.description {
                                        Text("• \(description)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    if let pageNumber = metadata.pageNumber {
                                        Text("Page \(pageNumber)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                
                // Follow-up suggestions
                if let suggestions = message.followUpSuggestions, !suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Suggested follow-ups:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button(action: {
                                viewModel.useFollowUpSuggestion(suggestion)
                            }) {
                                Text("• \(suggestion)")
                                    .font(.caption)
                                    .foregroundColor(Color(red: 172/255, green: 32/255, blue: 41/255))
                                    .multilineTextAlignment(.leading)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 4)
                }
                
                // Metadata
                HStack(spacing: 12) {
                    if let sources = message.sources, !sources.isEmpty {
                        // Show document sources
                        let uniqueDocuments = Set(sources.compactMap { $0.components(separatedBy: ".").first })
                        
                        if !uniqueDocuments.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.text")
                                    .font(.caption2)
                                Text(uniqueDocuments.count > 2 ? "\(uniqueDocuments.count) sources" : uniqueDocuments.joined(separator: ", "))
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                        }
                    }
                    
                    if let pageRefs = message.pageReferences, !pageRefs.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "bookmark")
                                .font(.caption2)
                            Text("Pages: \(pageRefs.map(String.init).joined(separator: ", "))")
                                .font(.caption2)
                                .lineLimit(1)
                        }
                    }
                    
                    if let confidence = message.confidence, confidence > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.shield")
                                .font(.caption2)
                            Text("\(Int(confidence * 100))%")
                                .font(.caption2)
                        }
                    }
                    
                    if let modelUsed = message.modelUsed {
                        // Filter out VAPI model references
                        let filteredModel = modelUsed.lowercased().contains("vapi") ? nil : modelUsed
                        if let model = filteredModel {
                            HStack(spacing: 4) {
                                Image(systemName: "cpu")
                                    .font(.caption2)
                                Text(model.components(separatedBy: "-").first ?? model)
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
                .padding(.top, 4)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser { Spacer() }
        }
    }
}

// MARK: - Loading Bubble
struct LoadingBubble: View {
    @State private var animationAmount = 0.0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationAmount)
                        .opacity(animationAmount)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animationAmount
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemGray5))
            .cornerRadius(16)
            .onAppear {
                animationAmount = 1.0
            }
            
            Spacer()
        }
    }
}

// MARK: - Voice Input Animation
struct VoiceInputAnimation: View {
    let transcribedText: String
    let isProcessing: Bool
    @State private var animationAmount = 1.0
    
    var body: some View {
        VStack(spacing: 8) {
            // Voice wave animation
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isProcessing ? .orange : Color(red: 172/255, green: 32/255, blue: 41/255))
                        .frame(width: 4, height: CGFloat.random(in: 10...40))
                        .animation(
                            Animation.easeInOut(duration: 0.5)
                                .repeatForever()
                                .delay(Double(index) * 0.1),
                            value: animationAmount
                        )
                }
            }
            .frame(height: 40)
            .onAppear {
                animationAmount = 2.0
            }
            
            // Status text
            if isProcessing {
                Text("Processing...")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else if !transcribedText.isEmpty {
                Text(transcribedText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.horizontal)
            } else {
                Text("Listening...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Topics Sheet
struct TopicsSheet: View {
    let topics: [String]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List(topics, id: \.self) { topic in
                HStack {
                    Image(systemName: topicIcon(for: topic))
                        .foregroundColor(Color(red: 172/255, green: 32/255, blue: 41/255))
                        .frame(width: 24)
                    Text(topic)
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Health Topics")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
    
    private func topicIcon(for topic: String) -> String {
        switch topic.lowercased() {
        case let t where t.contains("pressure"):
            return "heart.circle"
        case let t where t.contains("bladder"):
            return "drop.circle"
        case let t where t.contains("bowel"):
            return "pills.circle"
        case let t where t.contains("injury"):
            return "bandage"
        case let t where t.contains("exercise") || t.contains("mobility"):
            return "figure.walk.circle"
        case let t where t.contains("mental"):
            return "brain"
        case let t where t.contains("nutrition"):
            return "leaf.circle"
        case let t where t.contains("pain"):
            return "waveform.path.ecg"
        case let t where t.contains("spasticity"):
            return "waveform.circle"
        default:
            return "book.circle"
        }
    }
}

// MARK: - Preview
struct HealthEducationView_Previews: PreviewProvider {
    static var previews: some View {
        HealthEducationView()
            .environmentObject(CallManager())
    }
}