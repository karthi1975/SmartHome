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

        // Use actual field values from the form
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
        
        let payload: [String: Any] = [
            "title": subject,
            "group": group,
            "customer": customer,
            "priority": priority,
            "article": articlePayload
        ]

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
                print("Zammad error: \(httpResponse.statusCode) - \(bodyString)")
                let errorMessage = "Failed to create ticket (\(httpResponse.statusCode)): \(bodyString)"
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
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "ZammadClient", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let tickets = try decoder.decode([Ticket].self, from: data)
                completion(.success(tickets))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
} 
