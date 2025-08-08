import Foundation

// MARK: - API Response Models
struct LoginResponse: Codable {
    let accessToken: String
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
    }
}

struct ImageData: Codable {
    let imageId: String?
    let filename: String?
    let description: String?
    let pageNumber: Int?
    let documentSource: String?
    let base64Data: String?
    let imageUrl: String?
    let filePath: String?
    let reference: String?
    let relevanceScore: Double?
    let sourceDocument: String?
    
    enum CodingKeys: String, CodingKey {
        case imageId = "image_id"
        case filename
        case description
        case pageNumber = "page_number"
        case documentSource = "document_source"
        case base64Data = "base64_data"
        case imageUrl = "image_url"
        case filePath = "file_path"
        case reference
        case relevanceScore = "relevance_score"
        case sourceDocument = "source_document"
    }
    
    init(from decoder: Decoder) throws {
        // First try to decode as a dictionary
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            // All fields are optional to handle different response formats
            self.imageId = try? container.decode(String.self, forKey: .imageId)
            self.filename = try? container.decode(String.self, forKey: .filename)
            self.description = try? container.decode(String.self, forKey: .description)
            self.pageNumber = try? container.decode(Int.self, forKey: .pageNumber)
            self.documentSource = try? container.decode(String.self, forKey: .documentSource)
            self.base64Data = try? container.decode(String.self, forKey: .base64Data)
            self.imageUrl = try? container.decode(String.self, forKey: .imageUrl)
            self.filePath = try? container.decode(String.self, forKey: .filePath)
            self.reference = try? container.decode(String.self, forKey: .reference)
            self.relevanceScore = try? container.decode(Double.self, forKey: .relevanceScore)
            self.sourceDocument = try? container.decode(String.self, forKey: .sourceDocument)
            
            // Debug print what we decoded
            print("[DEBUG] Decoded ImageData:")
            print("  - imageId: \(imageId ?? "nil")")
            print("  - filename: \(filename ?? "nil")")
            print("  - filePath: \(filePath ?? "nil")")
            print("  - has base64Data: \(base64Data != nil)")
            print("  - base64Data length: \(base64Data?.count ?? 0)")
            print("  - has imageUrl: \(imageUrl != nil)")
            print("  - description: \(description ?? "nil")")
        } else {
            // If it's not a dictionary, initialize with nil values
            self.imageId = nil
            self.filename = nil
            self.description = nil
            self.pageNumber = nil
            self.documentSource = nil
            self.base64Data = nil
            self.imageUrl = nil
            self.filePath = nil
            self.reference = nil
            self.relevanceScore = nil
            self.sourceDocument = nil
            print("[DEBUG] ImageData: Failed to decode, using nil values")
        }
    }
}

// MARK: - Source wrapper to handle v2 API response format
struct SourceWrapper: Codable {
    let document: String?
    let relevanceScore: Double?
    let topics: [String]?
    let chunkId: String?
    
    // Computed property for display value
    var value: String {
        return document ?? ""
    }
    
    enum CodingKeys: String, CodingKey {
        case document
        case relevanceScore = "relevance_score"
        case topics
        case chunkId = "chunk_id"
    }
    
    init(value: String) {
        self.document = value
        self.relevanceScore = nil
        self.topics = nil
        self.chunkId = nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.document = try? container.decode(String.self, forKey: .document)
        self.relevanceScore = try? container.decode(Double.self, forKey: .relevanceScore)
        self.topics = try? container.decode([String].self, forKey: .topics)
        self.chunkId = try? container.decode(String.self, forKey: .chunkId)
    }
}

// Helper to decode any type
struct AnyCodable: Codable {
    let value: Any
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable(value: $0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable(value: $0) })
        default:
            try container.encodeNil()
        }
    }
    
    init(value: Any) {
        self.value = value
    }
}

struct ChatResponse: Codable {
    let answer: String
    let sources: [SourceWrapper]
    let images: [ImageData]?
    let hasImages: Bool?
    let voiceAnswer: String?
    let pageReferences: [Int]?
    let pageStatement: String?
    let confidenceScore: Double?
    let processingTime: Double?
    let tokensUsed: Int?
    let modelUsed: String?
    let queryType: String?
    let followUpSuggestions: [String]?
    
    enum CodingKeys: String, CodingKey {
        case answer, sources, images
        case hasImages = "has_images"
        case voiceAnswer = "voice_answer"
        case pageReferences = "page_references"
        case pageStatement = "page_statement"
        case confidenceScore = "confidence_score"
        case processingTime = "processing_time"
        case tokensUsed = "tokens_used"
        case modelUsed = "model_used"
        case queryType = "query_type"
        case followUpSuggestions = "follow_up_suggestions"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        self.answer = try container.decode(String.self, forKey: .answer)
        
        // Handle sources - v2 API returns structured sources
        if let sourcesArray = try? container.decode([SourceWrapper].self, forKey: .sources) {
            self.sources = sourcesArray
        } else if let sourceStrings = try? container.decode([String].self, forKey: .sources) {
            self.sources = sourceStrings.map { SourceWrapper(value: $0) }
        } else {
            self.sources = []
        }
        
        // Optional fields with defaults
        self.images = try? container.decode([ImageData].self, forKey: .images)
        self.hasImages = try? container.decode(Bool.self, forKey: .hasImages)
        self.voiceAnswer = try? container.decode(String.self, forKey: .voiceAnswer)
        self.pageReferences = try? container.decode([Int].self, forKey: .pageReferences)
        self.pageStatement = try? container.decode(String.self, forKey: .pageStatement)
        self.confidenceScore = try? container.decode(Double.self, forKey: .confidenceScore)
        self.processingTime = try? container.decode(Double.self, forKey: .processingTime)
        self.tokensUsed = try? container.decode(Int.self, forKey: .tokensUsed)
        self.modelUsed = try? container.decode(String.self, forKey: .modelUsed)
        self.queryType = try? container.decode(String.self, forKey: .queryType)
        self.followUpSuggestions = try? container.decode([String].self, forKey: .followUpSuggestions)
    }
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatRequest: Codable {
    let query: String
    let topicFilter: String?
    let nResults: Int
    let useAdvancedSearch: Bool
    
    enum CodingKeys: String, CodingKey {
        case query
        case topicFilter = "topic_filter"
        case nResults = "n_results"
        case useAdvancedSearch = "use_advanced_search"
    }
}

// MARK: - API Error
enum HealthEducationAPIError: LocalizedError {
    case notAuthenticated
    case invalidCredentials
    case invalidAPIKey
    case tokenExpired
    case rateLimitExceeded
    case serverError(String)
    case networkError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please log in first"
        case .invalidCredentials:
            return "Invalid username or password"
        case .invalidAPIKey:
            return "Invalid API key"
        case .tokenExpired:
            return "Session expired. Please log in again"
        case .rateLimitExceeded:
            return "Too many requests. Please try again later"
        case .serverError(let message):
            return "Server error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to process server response"
        }
    }
}

// MARK: - Health Education API Service
class HealthEducationAPI: ObservableObject {
    static let shared = HealthEducationAPI()
    
    private var settings = HealthEducationSettings.shared
    
    private var baseURL: String {
        return settings.apiBaseURL
    }
    
    var token: String {
        return settings.apiToken
    }
    
    @Published var isAuthenticated: Bool = false
    
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.waitsForConnectivity = true
        self.session = URLSession(configuration: configuration)
        
        // Token is hardcoded in settings, always authenticated
        isAuthenticated = true
        settings.isConfigured = true
        print("[DEBUG] HealthEducationAPI initialized with token: \(settings.apiToken.prefix(20))...")
    }
    
    // MARK: - Refresh Token (call this when token expires)
    func refreshToken() async -> String? {
        print("[DEBUG] Refreshing authentication token...")
        
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let credentials = "username=admin&password=admin123"
        request.httpBody = credentials.data(using: .utf8)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("[DEBUG] Failed to refresh token")
                return nil
            }
            
            let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
            let newToken = loginResponse.accessToken
            
            // Save the new token
            settings.saveCredentials(username: "admin", token: newToken)
            print("[DEBUG] Token refreshed successfully: \(newToken.prefix(20))...")
            print("[DEBUG] Copy this token to update the hardcoded value in HealthEducationSettings.swift")
            print("[DEBUG] Full token: \(newToken)")
            
            return newToken
        } catch {
            print("[DEBUG] Error refreshing token: \(error)")
            return nil
        }
    }
    
    // MARK: - Login
    func login(username: String, password: String) async throws {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let credentials = "username=\(username)&password=\(password)"
        request.httpBody = credentials.data(using: .utf8)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HealthEducationAPIError.serverError("Invalid response")
            }
            
            switch httpResponse.statusCode {
            case 200:
                let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                settings.saveCredentials(username: username, token: loginResponse.accessToken)
                isAuthenticated = true
                print("[DEBUG] Login successful, token saved: \(loginResponse.accessToken.prefix(20))...")
            case 401, 403:
                throw HealthEducationAPIError.invalidCredentials
            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw HealthEducationAPIError.serverError(errorMessage)
            }
        } catch let error as HealthEducationAPIError {
            throw error
        } catch {
            throw HealthEducationAPIError.networkError(error)
        }
    }
    
    // MARK: - Check Authentication
    func checkAuthentication() -> Bool {
        // Always authenticated with hardcoded token
        isAuthenticated = true
        return true
    }
    
    // MARK: - Chat Query
    func askQuestion(_ query: String, chatHistory: [ChatMessage] = [], includeImages: Bool = true) async throws -> ChatResponse {
        // Check authentication
        guard checkAuthentication() else {
            throw HealthEducationAPIError.notAuthenticated
        }
        
        // Use the authenticated v2 endpoint for image support
        let url = URL(string: "\(baseURL)/api/v2/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let chatRequest = ChatRequest(
            query: query,
            topicFilter: "",
            nResults: 5,
            useAdvancedSearch: true
        )
        
        // Debug: Print request details
        print("[DEBUG] API Request to \(url.absoluteString):")
        print("[DEBUG] Query: '\(query)'")
        print("[DEBUG] Topic Filter: (empty)")
        print("[DEBUG] N Results: 5")
        print("[DEBUG] Use Advanced Search: true")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        request.httpBody = try encoder.encode(chatRequest)
        
        // Debug print the request body
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("[DEBUG] Request Body:")
            print(bodyString)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HealthEducationAPIError.serverError("Invalid response")
            }
            
            switch httpResponse.statusCode {
            case 200:
                // Debug: Print raw response
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("[DEBUG] API Response (200 OK):")
                    print(jsonString)
                    
                    // Try to parse as JSON for better debugging
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        if let images = json["images"] as? [[String: Any]] {
                            print("[DEBUG] Images in response: \(images.count)")
                            for (index, image) in images.enumerated() {
                                print("[DEBUG] Image \(index + 1):")
                                print("  - image_id: \(image["image_id"] ?? "nil")")
                                print("  - has base64_data: \(image["base64_data"] != nil)")
                                print("  - has image_url: \(image["image_url"] != nil)")
                                print("  - description: \(image["description"] ?? "nil")")
                            }
                        } else {
                            print("[DEBUG] No images field in response")
                        }
                    }
                }
                
                do {
                    let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
                    print("[DEBUG] Successfully decoded ChatResponse:")
                    print("  - Answer length: \(chatResponse.answer.count)")
                    print("  - Images count: \(chatResponse.images?.count ?? 0)")
                    print("  - Sources count: \(chatResponse.sources.count)")
                    return chatResponse
                } catch {
                    print("[DEBUG] Decoding error: \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("[DEBUG] Failed to decode response: \(jsonString)")
                    }
                    throw HealthEducationAPIError.decodingError(error)
                }
            case 401:
                // Token expired, try to refresh
                print("[DEBUG] Token expired (401), attempting to refresh...")
                if let newToken = await refreshToken() {
                    // Retry the request with new token
                    request.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                    let (retryData, retryResponse) = try await session.data(for: request)
                    
                    if let retryHttpResponse = retryResponse as? HTTPURLResponse,
                       retryHttpResponse.statusCode == 200 {
                        // Successful retry with new token
                        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: retryData)
                        return chatResponse
                    }
                }
                throw HealthEducationAPIError.tokenExpired
            case 403:
                throw HealthEducationAPIError.serverError("Forbidden")
            case 429:
                throw HealthEducationAPIError.rateLimitExceeded
            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("[DEBUG] API Error (\(httpResponse.statusCode)): \(errorMessage)")
                throw HealthEducationAPIError.serverError(errorMessage)
            }
        } catch let error as HealthEducationAPIError {
            throw error
        } catch let error as DecodingError {
            throw HealthEducationAPIError.decodingError(error)
        } catch {
            throw HealthEducationAPIError.networkError(error)
        }
    }
    
    // MARK: - Load Image from URL
    func loadImage(from path: String) async throws -> Data {
        // No authentication needed
        
        let fullURL = "\(baseURL)\(path)"
        guard let url = URL(string: fullURL) else {
            throw HealthEducationAPIError.serverError("Invalid image URL")
        }
        
        var request = URLRequest(url: url)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HealthEducationAPIError.serverError("Invalid response")
            }
            
            guard httpResponse.statusCode == 200 else {
                throw HealthEducationAPIError.serverError("Failed to load image: \(httpResponse.statusCode)")
            }
            
            return data
        } catch {
            throw HealthEducationAPIError.networkError(error)
        }
    }
    
    // MARK: - Health Check
    func checkHealth() async throws -> Bool {
        let url = URL(string: "\(baseURL)/health")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            
            return httpResponse.statusCode == 200
        } catch {
            return false
        }
    }
    
    // MARK: - Get Suggested Topics
    func getSuggestedTopics() -> [String] {
        // Return hardcoded topics for now since the endpoint doesn't have a topics endpoint
        return [
            "Autonomic Dysreflexia",
            "Blood Pressure Management",
            "Bladder Care",
            "Bowel Management",
            "Pressure Injury Prevention",
            "Spasticity Management",
            "Pain Management",
            "Exercise and Mobility",
            "Mental Health",
            "Nutrition"
        ]
    }
    
    // MARK: - Logout
    func logout() {
        settings.clearSettings()
        isAuthenticated = false
    }
    
    // MARK: - Get Current User
    func getCurrentUsername() -> String {
        return settings.username
    }
    
    // MARK: - Auto Login
    func performAutoLogin() async {
        // Token is hardcoded, no need for auto-login
        print("[DEBUG] Using hardcoded token, skipping auto-login")
        print("[DEBUG] Token: \(settings.apiToken.prefix(20))...")
        isAuthenticated = true
        settings.isConfigured = true
    }
    
    // MARK: - Test API Connection
    func testAPIConnection() async {
        print("[DEBUG] Testing API Connection...")
        do {
            // Test 1: Try the exact query from admin portal
            let testResponse = try await askQuestion("what is blood pressure in AD?", includeImages: true)
            print("[DEBUG] Test API Response:")
            print("  - Answer length: \(testResponse.answer.count)")
            print("  - Images count: \(testResponse.images?.count ?? 0)")
            print("  - Has images: \(testResponse.images != nil && !testResponse.images!.isEmpty)")
            
            if let images = testResponse.images {
                for (index, img) in images.enumerated() {
                    print("[DEBUG] Test Image \(index + 1):")
                    print("  - ID: \(img.imageId)")
                    print("  - Has base64: \(img.base64Data != nil)")
                    print("  - Has URL: \(img.imageUrl != nil)")
                    print("  - Description: \(img.description ?? "nil")")
                }
            } else {
                print("[DEBUG] No images returned. Checking alternative endpoints...")
                
                // Try alternative endpoint if v2 doesn't return images
                let altUrl = URL(string: "\(baseURL)/chat")!
                var altRequest = URLRequest(url: altUrl)
                altRequest.httpMethod = "POST"
                altRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let altChatRequest = ChatRequest(
                    query: "what is blood pressure in AD?",
                    topicFilter: "",
                    nResults: 5,
                    useAdvancedSearch: true
                )
                
                altRequest.httpBody = try JSONEncoder().encode(altChatRequest)
                
                let (data, response) = try await session.data(for: altRequest)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("[DEBUG] Alternative endpoint response:")
                        print(jsonString)
                    }
                }
            }
        } catch {
            print("[DEBUG] Test API Error: \(error)")
        }
    }
}