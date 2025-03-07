import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol APIClient: Sendable {
    @discardableResult
    func request<Endpoint: APIEndpoint>(_ endpoint: Endpoint) async throws -> HTTPURLResponse
    @discardableResult
    func request<Endpoint: APIEndpoint, DataType: Encodable>(_ endpoint: Endpoint, data: DataType) async throws -> HTTPURLResponse
    func request<Endpoint: APIEndpoint>(_ endpoint: Endpoint) async throws -> (Endpoint.ResultType, HTTPURLResponse) where Endpoint.ResultType: Decodable
    func request<Endpoint: APIEndpoint, DataType: Encodable>(_ endpoint: Endpoint, data: DataType) async throws -> (Endpoint.ResultType, HTTPURLResponse) where Endpoint.ResultType: Decodable
    func request<Endpoint: APIEndpoint>(_ endpoint: Endpoint, form: [String: String]) async throws -> (Endpoint.ResultType, HTTPURLResponse) where Endpoint.ResultType: Decodable
}

public struct APIClientImpl: APIClient {

    private let httpClient: HTTPClient
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    public init(httpClient: HTTPClient = HTTPClientImpl(), jsonEncoder: JSONEncoder = .init(), jsonDecoder: JSONDecoder = .init()) {
        self.httpClient = httpClient
        self.jsonEncoder = jsonEncoder
        self.jsonDecoder = jsonDecoder
    }

    @discardableResult
    public func request<Endpoint: APIEndpoint>(_ endpoint: Endpoint) async throws -> HTTPURLResponse {
        let request = endpoint.request
        return try await httpClient.execute(request).1
    }

    @discardableResult
    public func request<Endpoint: APIEndpoint, DataType: Encodable>(_ endpoint: Endpoint, data: DataType) async throws -> HTTPURLResponse {
        let request = endpoint.request(json: data, encoder: jsonEncoder)
        return try await httpClient.execute(request).1
    }

    public func request<Endpoint: APIEndpoint>(_ endpoint: Endpoint) async throws -> (Endpoint.ResultType, HTTPURLResponse) where Endpoint.ResultType: Decodable {
        let request = endpoint.request
        return try await requestDecodable(request)
    }

    public func request<Endpoint: APIEndpoint>(_ endpoint: Endpoint, form: [String: String]) async throws -> (Endpoint.ResultType, HTTPURLResponse) where Endpoint.ResultType: Decodable {
        let request = endpoint.request(form: form)
        return try await requestDecodable(request)
    }

    public func request<Endpoint: APIEndpoint, DataType: Encodable>(_ endpoint: Endpoint, data: DataType) async throws -> (Endpoint.ResultType, HTTPURLResponse) where Endpoint.ResultType: Decodable {
        let request = endpoint.request(json: data, encoder: jsonEncoder)
        return try await requestDecodable(request)
    }

    // MARK: - Helpers

    private func requestDecodable<ResultType: Decodable>(_ request: URLRequest) async throws -> (ResultType, HTTPURLResponse) {
        let data = try await httpClient.execute(request)
        do {
            let result = try jsonDecoder.decode(ResultType.self, from: data.0)
            return (result, data.1)
        } catch {
            print("❌ failed to decode model '\(ResultType.self)' error: \(error), data: \(String(data: data.0, encoding: .utf8) ?? "nil")")
            throw error
        }
    }
}
