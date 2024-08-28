import Foundation

public protocol APIClient: Sendable {
    func request<Endpoint: APIEndpoint>(_ endpoint: Endpoint) async throws
    func request<Endpoint: APIEndpoint>(_ endpoint: Endpoint) async throws -> Endpoint.ResultType where Endpoint.ResultType: Decodable
    func request<Endpoint: APIEndpoint, DataType: Encodable>(_ endpoint: Endpoint, data: DataType) async throws
    func request<Endpoint: APIEndpoint, DataType: Encodable>(_ endpoint: Endpoint, data: DataType) async throws -> Endpoint.ResultType where Endpoint.ResultType: Decodable
}

public struct APIClientImpl: APIClient {

    private let httpClient: HTTPClient
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        decoder.dateDecodingStrategy = .formatted(formatter)
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    private let jsonEncoder: JSONEncoder

    public init(httpClient: HTTPClient = HTTPClientImpl(), jsonEncoder: JSONEncoder = .init()) {
        self.httpClient = httpClient
        self.jsonEncoder = jsonEncoder
    }

    public func request<Endpoint: APIEndpoint>(_ endpoint: Endpoint) async throws {
        let request = endpoint.request
        _ = try await httpClient.execute(request)
    }

    public func request<Endpoint: APIEndpoint>(_ endpoint: Endpoint) async throws -> Endpoint.ResultType where Endpoint.ResultType: Decodable {
        let request = endpoint.request
        let data = try await httpClient.execute(request)
        do {
            return try jsonDecoder.decode(Endpoint.ResultType.self, from: data.0)
        } catch {
            print("❌ failed to decode model '\(Endpoint.ResultType.self)' error: \(error), data: \(String(data: data.0, encoding: .utf8) ?? "nil")")
            throw error
        }
    }

    public func request<Endpoint: APIEndpoint, DataType: Encodable>(_ endpoint: Endpoint, data: DataType) async throws {
        let request = endpoint.request(json: data, encoder: jsonEncoder)
        _ = try await httpClient.execute(request)
    }

    public func request<Endpoint: APIEndpoint, DataType: Encodable>(_ endpoint: Endpoint, data: DataType) async throws -> Endpoint.ResultType where Endpoint.ResultType: Decodable {
        let request = endpoint.request(json: data, encoder: jsonEncoder)
        let data = try await httpClient.execute(request)
        do {
            return try jsonDecoder.decode(Endpoint.ResultType.self, from: data.0)
        } catch {
            print("❌ failed to decode model '\(Endpoint.ResultType.self)' error: \(error), data: \(String(data: data.0, encoding: .utf8) ?? "nil")")
            throw error
        }
    }
}
