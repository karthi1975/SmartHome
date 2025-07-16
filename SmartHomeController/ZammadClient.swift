import Foundation

private struct User: Decodable {
    let id: Int
}

struct Ticket: Decodable, Identifiable {
    let id: Int
    let title: String
    let stateId: Int
    let createdAt: String
    let customerId: Int

    var state: String {
        switch stateId {
        case 1: return "New"
        case 2: return "Open"
        case 3: return "Pending"
        case 4: return "Closed"
        default: return "Unknown"
        }
    }
}

// Helper struct to decode the nested search result from Zammad
private struct ZammadSearchResult: Decodable {
    let assets: Assets
    
    struct Assets: Decodable {
        let Ticket: [Ticket]
    }
}

class ZammadClient {
    static let shared = ZammadClient()
    private init() {}
    
    private var config: ZammadConfig {
        return ZammadConfig.load()
    }
    
    private var baseURL: URL {
        return URL(string: config.baseURL) ?? URL(string: "http://localhost:8080/api/v1")!
    }
    
    private var apiToken: String {
        return config.apiToken
    }

    func createTicket(subject: String, body: String, customer: String, group: String = "Users", priority: String = "2 normal", attachment: Data?, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = baseURL.appendingPathComponent("tickets")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Token token=\(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Debug logging
        if UserDefaults.standard.bool(forKey: "DebugLoggingEnabled") {
            print("DEBUG: Creating ticket with URL: \(url)")
            print("DEBUG: Using token: \(apiToken)")
            print("DEBUG: Authorization header: Token token=\(apiToken)")
        }

        // Use Zammad API format as per documentation
        var articlePayload: [String: Any] = [
            "subject": subject,
            "body": body,
            "type": "note",
            "internal": false
        ]

        if let attachmentData = attachment {
            let base64String = attachmentData.base64EncodedString()
            let attachmentPayload: [String: Any] = [
                "filename": "attachment.jpg",
                "data": base64String,
                "mime-type": "image/jpeg"
            ]
            articlePayload["attachments"] = [attachmentPayload]
        }
        
        // Format according to Zammad API documentation
        let payload: [String: Any] = [
            "title": subject,
            "group": group,
            "customer": customer,
            "priority": priority,
            "article": articlePayload
        ]
        
        if UserDefaults.standard.bool(forKey: "DebugLoggingEnabled") {
            if let payloadData = try? JSONSerialization.data(withJSONObject: payload),
               let payloadString = String(data: payloadData, encoding: .utf8) {
                print("DEBUG: Payload: \(payloadString)")
            }
        }

        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "Zammad", code: 2, userInfo: [NSLocalizedDescriptionKey: "No HTTP response"])))
                return
            }
            if !(200...299).contains(httpResponse.statusCode) {
                let bodyString = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<no body>"
                if UserDefaults.standard.bool(forKey: "DebugLoggingEnabled") {
                    print("Zammad error: \(httpResponse.statusCode) - \(bodyString)")
                }
                
                let errorMessage: String
                switch httpResponse.statusCode {
                case 401:
                    errorMessage = "Authentication failed. Check your API token."
                case 403:
                    errorMessage = "Permission denied. Token needs 'ticket.agent' or 'ticket.customer' permissions."
                case 422:
                    errorMessage = "Invalid data. Check required fields: title, group, customer, article."
                case 500:
                    errorMessage = "Server error. Please try again later."
                default:
                    errorMessage = "Failed to create ticket (\(httpResponse.statusCode)): \(bodyString)"
                }
                
                completion(.failure(NSError(domain: "Zammad", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                return
            }
            completion(.success(()))
        }.resume()
    }

    func fetchCurrentUserId(completion: @escaping (Result<Int, Error>) -> Void) {
        let url = baseURL.appendingPathComponent("users/me")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Token token=\(apiToken)", forHTTPHeaderField: "Authorization")
        
        // Debug logging
        if UserDefaults.standard.bool(forKey: "DebugLoggingEnabled") {
            print("DEBUG: Testing token with URL: \(url)")
            print("DEBUG: Token: \(apiToken)")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "ZammadClient", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data from users/me"])))
                return
            }
            do {
                let user = try JSONDecoder().decode(User.self, from: data)
                completion(.success(user.id))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func fetchAllTickets(completion: @escaping (Result<[Ticket], Error>) -> Void) {
        let url = baseURL.appendingPathComponent("tickets")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Token token=\(apiToken)", forHTTPHeaderField: "Authorization")
        
        // Always debug for ticket fetching
        print("DEBUG: Fetching tickets from URL: \(url)")
        print("DEBUG: Using token: \(apiToken)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("DEBUG: Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("DEBUG: No HTTP response")
                completion(.failure(NSError(domain: "ZammadClient", code: 2, userInfo: [NSLocalizedDescriptionKey: "No HTTP response"])))
                return
            }
            
            print("DEBUG: HTTP response status: \(httpResponse.statusCode)")
            
            guard let data = data else {
                print("DEBUG: No data received")
                completion(.failure(NSError(domain: "ZammadClient", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("DEBUG: Response data: \(responseString)")
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let tickets = try decoder.decode([Ticket].self, from: data)
                print("DEBUG: Successfully decoded \(tickets.count) tickets")
                completion(.success(tickets))
            } catch {
                print("DEBUG: JSON decode error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Test function to try different token formats
    func testTokenFormats(completion: @escaping (Result<String, Error>) -> Void) {
        let url = baseURL.appendingPathComponent("users/me")
        
        // Try different token formats
        let tokenFormats = [
            "Token token=\(apiToken)",
            "Bearer \(apiToken)",
            "Token \(apiToken)",
            apiToken
        ]
        
        func tryNextFormat(index: Int) {
            guard index < tokenFormats.count else {
                completion(.failure(NSError(domain: "ZammadClient", code: 401, userInfo: [NSLocalizedDescriptionKey: "All token formats failed"])))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(tokenFormats[index], forHTTPHeaderField: "Authorization")
            
            if UserDefaults.standard.bool(forKey: "DebugLoggingEnabled") {
                print("DEBUG: Trying token format #\(index + 1): \(tokenFormats[index])")
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let httpResponse = response as? HTTPURLResponse {
                    if UserDefaults.standard.bool(forKey: "DebugLoggingEnabled") {
                        print("DEBUG: Format #\(index + 1) response: \(httpResponse.statusCode)")
                    }
                    if httpResponse.statusCode == 200 {
                        completion(.success("Format #\(index + 1) works: \(tokenFormats[index])"))
                        return
                    }
                }
                
                // Try next format
                tryNextFormat(index: index + 1)
            }.resume()
        }
        
        tryNextFormat(index: 0)
    }
} 
