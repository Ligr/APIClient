import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum HTTPRequestMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case delete = "DELETE"
    case patch = "PATCH"
    case put = "PUT"
}

public protocol APIEndpoint {

    associatedtype ResultType

    var requestMethod: HTTPRequestMethod { get }
    var baseUrl: URL { get }
    var path: String { get }
    var query: [String: String] { get }
    var headers: [String: String] { get }
}

public extension APIEndpoint {

    var requestMethod: HTTPRequestMethod {
        .get
    }

    var query: [String: String] {
        [:]
    }

    var headers: [String: String] {
        ["Accept": "application/json"]
    }

    var request: URLRequest {
        let url = baseUrl.appendingPathComponent(path)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        if !query.isEmpty {
            let queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
            components?.queryItems = queryItems
        }
        var request = URLRequest(url: components?.url ?? url)
        request.httpMethod = requestMethod.rawValue
        for header in headers {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        return request
    }

    func request<T: Encodable>(json: T, encoder: JSONEncoder = .init()) -> URLRequest {
        var request = self.request
        if let data = try? encoder.encode(json) {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = data
        }
        return request
    }
}
