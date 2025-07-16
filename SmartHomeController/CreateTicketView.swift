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
            loadTicketHistory()
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
}

 