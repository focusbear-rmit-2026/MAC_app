import Foundation

enum ManagedAPIError: Error {
    case authentication, invalidResponse, status(Int), transport
}

/// Uses the existing Auth0 credential manager, but never logs credentials or page data.
struct ManagedAPIIdentity: Equatable {
    let userId: String
    let deviceId: String

    func matches(user: String?, device: String) -> Bool {
        !userId.isEmpty && !deviceId.isEmpty && user == userId && device == deviceId
    }
}

final class ManagedBlockingAPI {
    static let shared = ManagedBlockingAPI()
    private let session: URLSession

    init(session: URLSession = .shared) { self.session = session }

    func request<Response: Decodable>(_ route: String, identity: ManagedAPIIdentity, method: String = "GET", body: Data? = nil,
                                     completion: @escaping (Result<Response, ManagedAPIError>) -> Void) {
        DispatchQueue.main.async {
            guard let delegate = appdelegate, identity.matches(user: delegate.user?.userId, device: currentDeviceId) else {
                completion(.failure(.authentication)); return
            }
            // The caller supplies the identity before any asynchronous credential lookup.
            let userId = identity.userId
            let deviceId = identity.deviceId
            delegate.credentialsManager.credentials { result in
                guard case .success(let credentials) = result else {
                    DispatchQueue.main.async { completion(.failure(.authentication)) }; return
                }
                DispatchQueue.main.async {
                    guard delegate.user?.userId == userId, currentDeviceId == deviceId else {
                        completion(.failure(.authentication)); return
                    }
                    self.send(route, method: method, body: body, token: credentials.accessToken,
                              userId: userId, deviceId: deviceId, completion: completion)
                }
            }
        }
    }

    private func send<Response: Decodable>(_ route: String, method: String, body: Data?, token: String,
                                          userId: String, deviceId: String,
                                          completion: @escaping (Result<Response, ManagedAPIError>) -> Void) {
        guard let url = URL(string: baseUrl + "/managed-blocking/" + route), url.scheme == "https" else {
            completion(.failure(.invalidResponse)); return
        }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 12)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("mac-os", forHTTPHeaderField: "platform")
        request.setValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
        request.setValue(userId, forHTTPHeaderField: "x-focus-bear-user-id")
        request.setValue(deviceId, forHTTPHeaderField: "device-id")
        request.setValue(deviceId, forHTTPHeaderField: "device_id")
        session.dataTask(with: request) { data, response, error in
            let result: Result<Response, ManagedAPIError>
            if error != nil { result = .failure(.transport) }
            else if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
                result = .failure(.status(response.statusCode))
            } else if let data = data, let decoded = try? ManagedJSON.decoder().decode(Response.self, from: data) {
                result = .success(decoded)
            } else { result = .failure(.invalidResponse) }
            DispatchQueue.main.async {
                guard appdelegate?.user?.userId == userId, currentDeviceId == deviceId else {
                    completion(.failure(.authentication)); return
                }
                completion(result)
            }
        }.resume()
    }
}

struct ManagedURLCheck: Encodable {
    var url: String
    var tabTitle: String?
    var deviceId: String
    var eventId: String
}

struct ManagedViolationEvent: Codable, Identifiable {
    var eventId: String
    var deviceId: String
    var policyId: String
    var policyRevision: Int
    var domain: String
    var resourceHash: String
    var categoryIds: [String]
    var observedAt: String
    var id: String { eventId }
}

struct ManagedViolationBatch: Encodable { var events: [ManagedViolationEvent] }
struct ManagedViolationResults: Decodable {
    struct Item: Decodable {
        var eventId: String
        var status: String
        var violationId: String?
        var code: String?
        var retryable: Bool?
    }
    var results: [Item]
}

struct ManagedDeviceReceipt: Encodable {
    struct AppliedPolicy: Encodable {
        var id: String
        var kind: String
        var revision: Int
    }
    var deviceId: String
    var snapshotId: String
    var appliedPolicies: [AppliedPolicy]
    var clientVersion: String
    var platform = "macos"
    var clockStatus: String
    var permissionStatus: String
    var syncStatus: String
    var enforcementStatus: String
    var observedAt: String
}

struct ManagedEmptyResponse: Decodable {}

struct ManagedCreateSettingsRequest: Encodable {
    var deviceId: String
    var scope: [String]
    var baseRevision: Int
}

struct ManagedProposeSettingsChanges: Encodable {
    var deviceId: String
    var changes: ManagedPolicyChanges
}

struct ManagedAppealExplanation: Encodable { var explanation: String }
