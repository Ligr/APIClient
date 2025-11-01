import Foundation

public enum APIClientError: Error {

    case unknown
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case internalServerError
    case badGateway
    case serviceUnavailable
    case unsupportedStatusCode
    case urlSession(Error)

}
