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
        case .high: return "High"
        }
    }
}

struct CreateTicketView: View {
    @State private var subject = ""
    @State private var description = ""
    @State private var customerEmail = ""
    @State private var isSubmitting = false
    @State private var resultMessage: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var priority: TicketPriority = .normal
    
    @State private var showAttachmentOptions = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var isDropTargeted = false
    @State private var ticketHistory: [Ticket] = []
    @State private var isLoadingHistory = false

    private var displayTickets: [Ticket] {
        // ALWAYS show dummy tickets for testing - ignore real ticket history for now
        let isoFormatter = ISO8601DateFormatter()
        let dummyTickets = (0..<10).map { i in
            Ticket(
                id: i + 1,
                title: "Support Ticket #\(i+1) - \(ticketTitles[i % ticketTitles.count])",
                stateId: (i % 4) + 1, // Cycle through all state types (1=New, 2=Open, 3=Pending, 4=Closed)
                createdAt: isoFormatter.string(from: Date().addingTimeInterval(-Double(i) * 3600)),
                customerId: 12345
            )
        }
        
        print("DEBUG: Generated \(dummyTickets.count) dummy tickets")
        return dummyTickets
    }
    
    private let ticketTitles = [
        "Microphone not working during voice commands",
        "Temperature control animation stuck in loop", 
        "App crashes when navigating to kitchen page",
        "Voice recognition not detecting room names",
        "Unable to reduce temperature below 70 degrees",
        "Floating microphone button disappears randomly",
        "Settings page won't save Home Assistant config",
        "Device cards not updating real-time status",
        "Sidebar overlay animation glitchy on iPad",
        "Support page scrolling performance issues"
    ]

    
    private func stateColor(for stateId: Int) -> Color {
        switch stateId {
        case 1: return .blue    // New
        case 2: return .orange  // Open
        case 3: return .yellow  // Pending
        case 4: return .green   // Closed
        default: return .gray
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Ticket Creation Form
                VStack(spacing: 16) {
                    // Subject
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Subject")
                            .font(.headline)
                        TextField("Enter ticket subject", text: $subject)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        TextEditor(text: $description)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                    
                    // Email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Email")
                            .font(.headline)
                        TextField("Enter your email", text: $customerEmail)
                            .keyboardType(.emailAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Priority
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Priority")
                            .font(.headline)
                        Picker("Priority", selection: $priority) {
                            ForEach(TicketPriority.allCases) { p in
                                Text(p.displayName).tag(p)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Submit Button
                    Button(action: submit) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Create Ticket")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(subject.isEmpty || description.isEmpty || customerEmail.isEmpty || isSubmitting)
                    
                    // Result Message
                    if let resultMessage = resultMessage {
                        Text(resultMessage)
                            .foregroundColor(resultMessage.contains("success") ? .green : .red)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // FORCE SHOW DUMMY TICKETS - SIMPLIFIED APPROACH
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Support Tickets")
                            .font(.title2)
                            .bold()
                        Spacer()
                        Text("10 tickets")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Force display exactly 10 tickets with no conditions
                    ForEach(0..<10, id: \.self) { i in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Support Ticket #\(i+1) - \(ticketTitles[i % ticketTitles.count])")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                let stateId = (i % 4) + 1
                                Text("State: \(["New", "Open", "Pending", "Closed"][stateId - 1])")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(stateColor(for: stateId))
                                    .cornerRadius(8)
                                
                                Spacer()
                                
                                Text("ID: #\(i+1)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Created: \(Date().addingTimeInterval(-Double(i) * 3600), formatter: dateFormatter)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(stateColor(for: (i % 4) + 1).opacity(0.3), lineWidth: 1)
                        )
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
            // Don't load ticket history for now - just use dummy tickets for testing
            // loadTicketHistory()
            print("DEBUG: CreateTicketView appeared, using dummy tickets for testing")
        }
        .overlay(alignment: .bottomTrailing) {
            GlobalMicrophoneOverlay()
        }
    }

    func submit() {
        isSubmitting = true
        resultMessage = nil
        let attachmentData = selectedImage?.jpegData(compressionQuality: 0.8)
        ZammadClient.shared.createTicket(subject: subject, body: description, customer: customerEmail.lowercased(), priority: priority.rawValue, attachment: attachmentData) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success:
                    resultMessage = "Ticket created successfully!"
                    subject = ""
                    description = ""
                    customerEmail = ""
                    selectedPhotoItem = nil
                    selectedImage = nil
                    loadTicketHistory()
                case .failure(let error):
                    resultMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func loadTicketHistory() {
        isLoadingHistory = true
        ZammadClient.shared.fetchCurrentUserId { [self] result in
            switch result {
            case .success(let userId):
                ZammadClient.shared.fetchAllTickets { result in
                    DispatchQueue.main.async {
                        isLoadingHistory = false
                        switch result {
                        case .success(let tickets):
                            self.ticketHistory = tickets
                                .filter { $0.customerId == userId }
                                .sorted(by: { $0.createdAt > $1.createdAt })
                        case .failure(let error):
                            print("Error fetching tickets: \(error.localizedDescription)")
                            self.ticketHistory = []
                        }
                    }
                }
            case .failure(let error):
                print("Error fetching user ID: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    isLoadingHistory = false
                    self.ticketHistory = []
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
} 