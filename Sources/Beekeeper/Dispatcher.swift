//
//  Dispatcher.swift
//  Beekeeper
//
//  Created by Andreas Ganske on 15.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import Foundation

public protocol Dispatcher: Sendable {
    var timeout: TimeInterval { get }
    var maxBatchSize: Int { get }
    func dispatch(event: Event) async throws
    func dispatch(events: [Event]) async throws
}

public struct URLDispatcherError: Codable, Error {
    public let error: String
}

public protocol AsynchronousRequester: Sendable {
    func data(
        for request: URLRequest
    ) async throws -> (Data, URLResponse)
}

extension URLSession: AsynchronousRequester {}

public struct URLDispatcher: Dispatcher {
    let baseURL: URL
    let path: String
    let signer: Signer
    let requester: AsynchronousRequester
    let encoder: JSONEncoder
    let decoder: JSONDecoder
    
    public let timeout: TimeInterval
    public let maxBatchSize: Int
    
    public init(baseURL: URL, path: String, signer: Signer, timeout: TimeInterval = 30, maxBatchSize: Int = 10, encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder(), requester: AsynchronousRequester = URLSession.shared) {
        self.baseURL = baseURL
        self.path = path
        self.signer = signer
        self.timeout = timeout
        self.maxBatchSize = maxBatchSize
        self.encoder = encoder
        self.decoder = decoder
        self.requester = requester
    }
    
    public func dispatch(events: [Event]) async throws {
        try await send(events: events)
    }
    
    public func dispatch(event: Event) async throws {
        try await send(events: [event])
    }
    
    private func send(events: [Event]) async throws {
        guard let resourceURL = URL(string: baseURL.absoluteString + path),
              let urlComponents = URLComponents(url: resourceURL, resolvingAgainstBaseURL: false) else {
            throw RequestError.invalidRequest
        }
        
        guard let url = urlComponents.url else {
            throw RequestError.invalidRequest
        }
        
        let bodyData = try encoder.encode(events)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await requester.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RequestError.invalidHTTPResponse
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            guard !data.isEmpty else {
                throw RequestError.emptyErrorResponse(httpStatusCode: httpResponse.statusCode)
            }
            let appError = try decoder.decode(URLDispatcherError.self, from: data)
            throw appError
        }
        
        return
    }
}
