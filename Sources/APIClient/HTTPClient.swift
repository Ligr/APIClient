import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol HTTPClient: Sendable {
    func execute(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct HTTPClientImpl: HTTPClient {

    enum Errors: Error {
        case dataIsMissing
    }

    private let urlSession: URLSession

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    public func execute(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let data: Data
        let urlResponse: URLResponse
//        #if DEBUG
        do {
            let body = String(data: request.httpBody ?? Data(), encoding: .utf8)
            print("[\(Date())] HTTP request: \(request), body: \(body ?? "nil")")
            (data, urlResponse) = try await urlSession.data(for: request)
//            if let str = String(data: data, encoding: .utf8) {
//                print(str)
//            }
        } catch {
            print("❌ \(error.localizedDescription)")
            throw error
        }
//        #else
//        (data, urlResponse) = try await urlSession.data(for: request)
//        #endif
        guard let httpUrlResponse = urlResponse as? HTTPURLResponse, 200 ... 299 ~= httpUrlResponse.statusCode else {
            print("❌ HTTP request '\(request.url?.absoluteString ?? "nil")' failed")
//            #if DEBUG
            if let str = String(data: data, encoding: .utf8) {
                print("❌ \(str)")
            }
//            #endif
            let error = URLError(.badServerResponse)
            throw error
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
