import Foundation

public protocol HTTPClient {
    func execute(_ request: URLRequest) async throws -> (Data, URLResponse)
}

public struct HTTPClientImpl: HTTPClient {

    private let urlSession: URLSession

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    public func execute(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let data: (Data, URLResponse)
        #if DEBUG
        do {
            data = try await urlSession.data(for: request)
            if let str = String(data: data.0, encoding: .utf8) {
                print(str)
            }
        } catch {
            print("❌ \(error.localizedDescription)")
            throw error
        }
        #else
        data = try await urlSession.data(for: request)
        #endif
        guard let urlResponse = data.1 as? HTTPURLResponse, 200 ... 299 ~= urlResponse.statusCode else {
            print("❌ HTTP request '\(request.url?.absoluteString ?? "nil")' failed")
            #if DEBUG
            if let str = String(data: data.0, encoding: .utf8) {
                print(str)
            }
            #endif
            let error = URLError(.badServerResponse)
            throw error
        }
        return data
    }
}
