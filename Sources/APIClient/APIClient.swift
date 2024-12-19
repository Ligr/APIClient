import Foundation

public protocol APIClient: Sendable {
    func request<Endpoint: APIEndpoint>(_ endpoint: Endpoint) async throws
    func request<Endpoint: APIEndpoint, DataType: Encodable>(_ endpoint: Endpoint, data: DataType) async throws
    func request<Endpoint: APIEndpoint>(_ endpoint: Endpoint) async throws -> Endpoint.ResultType where Endpoint.ResultType: Decodable
    func request<Endpoint: APIEndpoint, DataType: Encodable>(_ endpoint: Endpoint, data: DataType) async throws -> Endpoint.ResultType where Endpoint.ResultType: Decodable
    func request<Endpoint: APIEndpoint>(_ endpoint: Endpoint, form: [String: String]) async throws -> Endpoint.ResultType where Endpoint.ResultType: Decodable
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

    public func request<Endpoint: APIEndpoint>(_ endpoint: Endpoint) async throws {
        let request = endpoint.request
        _ = try await httpClient.execute(request)
    }

    public func request<Endpoint: APIEndpoint, DataType: Encodable>(_ endpoint: Endpoint, data: DataType) async throws {
        let request = endpoint.request(json: data, encoder: jsonEncoder)
        _ = try await httpClient.execute(request)
    }

    public func request<Endpoint: APIEndpoint>(_ endpoint: Endpoint) async throws -> Endpoint.ResultType where Endpoint.ResultType: Decodable {
        let request = endpoint.request
        return try await requestDecodable(request)
    }

    public func request<Endpoint: APIEndpoint>(_ endpoint: Endpoint, form: [String: String]) async throws -> Endpoint.ResultType where Endpoint.ResultType: Decodable {
        let request = endpoint.request(form: form)
        return try await requestDecodable(request)
    }

    public func request<Endpoint: APIEndpoint, DataType: Encodable>(_ endpoint: Endpoint, data: DataType) async throws -> Endpoint.ResultType where Endpoint.ResultType: Decodable {
        let request = endpoint.request(json: data, encoder: jsonEncoder)
        return try await requestDecodable(request)
    }

    // MARK: - Helpers

    private func requestDecodable<ResultType: Decodable>(_ request: URLRequest) async throws -> ResultType {
        let data = try await httpClient.execute(request)
        do {
            return try jsonDecoder.decode(ResultType.self, from: data.0)
        } catch {
            print("❌ failed to decode model '\(ResultType.self)' error: \(error), data: \(String(data: data.0, encoding: .utf8) ?? "nil")")
            throw error
        }
    }
}
