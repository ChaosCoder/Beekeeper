//
//  Dispatcher.swift
//  Beekeeper
//
//  Created by Andreas Ganske on 15.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import Foundation
import ConvAPI
import PromiseKit

public protocol Dispatcher {
    var timeout: TimeInterval { get }
    var maxBatchSize: Int { get }
    func dispatch(event: Event) -> Promise<Void>
    func dispatch(events: [Event]) -> Promise<Void>
}

public struct URLDispatcherError: Codable, Error {
    public let error: String
}

public class URLDispatcher: Dispatcher {
    let baseURL: URL
    let path: String
    let backend: API
    let signer: Signer
    
    public let timeout: TimeInterval
    public var maxBatchSize: Int
    
    public init(baseURL: URL, path: String, signer: Signer, timeout: TimeInterval = 30, maxBatchSize: Int = 10, backend: API = ConvAPI()) {
        self.baseURL = baseURL
        self.path = path
        self.signer = signer
        self.timeout = timeout
        self.maxBatchSize = maxBatchSize
        self.backend = backend
    }
    
    public func dispatch(events: [Event]) -> Promise<Void> {
        return send(events: events)
    }
    
    public func dispatch(event: Event) -> Promise<Void> {
        return send(events: [event])
    }
    
    private func send(events: [Event]) -> Promise<Void> {
        return backend.request(method: .POST,
                               baseURL: baseURL,
                               resource: path,
                               headers: nil,
                               params: nil,
                               body: events,
                               error: URLDispatcherError.self,
                               decorator: signer.sign(request:))
    }
}
