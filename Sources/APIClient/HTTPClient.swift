import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol HTTPClient: Sendable {
    func execute(_ request: URLRequest) async throws(APIClientError) -> (Data, HTTPURLResponse)
}

public struct HTTPClientImpl: HTTPClient {

    enum Errors: Error {
        case dataIsMissing
    }

    private let urlSession: URLSession
    private let debug: Bool

    public init(urlSession: URLSession = .shared, debug: Bool = false) {
        self.urlSession = urlSession
        self.debug = debug
    }

    public func execute(_ request: URLRequest) async throws(APIClientError) -> (Data, HTTPURLResponse) {
        let data: Data
        let urlResponse: URLResponse
        if debug {
            do {
                let body = String(data: request.httpBody ?? Data(), encoding: .utf8)
                print("🛜 [\(Date())] HTTP request: \(request), body: \(body ?? "nil")")
                (data, urlResponse) = try await urlSession.data(for: request)
                if let str = String(data: data, encoding: .utf8) {
                    print("🛜 HTTP response: \(str)")
                }
            } catch {
                print("❌ URLSession error: \(error)")
                throw .urlSession(error)
            }
        } else {
            do {
                (data, urlResponse) = try await urlSession.data(for: request)
            } catch {
                throw .urlSession(error)
            }
        }
        guard let httpUrlResponse = urlResponse as? HTTPURLResponse else {
            throw .unknown
        }
        guard 200 ... 299 ~= httpUrlResponse.statusCode else {
            print("❌ HTTP request '\(request.url?.absoluteString ?? "nil")' failed")
            if debug {
                if let str = String(data: data, encoding: .utf8) {
                    print("❌ HTTP response: \(str)")
                }
            }
            switch httpUrlResponse.statusCode {
            case 400: throw .badRequest
            case 401: throw .unauthorized
            case 403: throw .forbidden
            case 404: throw .notFound
            case 500: throw .internalServerError
            case 502: throw .badGateway
            case 503: throw .serviceUnavailable
            default: throw .unsupportedStatusCode
            }
        }
        return (data, httpUrlResponse)
    }
}

#if canImport(FoundationNetworking)
// FoundationNetworking is missing this API
extension URLSession {
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await withUnsafeThrowingContinuation { continuation in
            let task = self.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data, let response {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: HTTPClientImpl.Errors.dataIsMissing)
                }
            }
            task.resume()
        }
    }
}
#endif
