//
//  Dispatcher.swift
//  Beekeeper
//
//  Created by Andreas Ganske on 15.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import Foundation
import JSONAPI
import Result

struct None: Codable {}

public protocol Dispatcher {
    var timeout: TimeInterval { get }
    var maxBatchSize: Int { get }
    func dispatch(event: Event, completion: @escaping (Error?) -> Void)
    func dispatch(events: [Event], completion: @escaping (Error?) -> Void)
}

public class URLDispatcher: Dispatcher {
    let baseURL: URL
    let path: String
    let backend: API
    let signer: Signer
    
    public let timeout: TimeInterval
    public var maxBatchSize: Int
    
    public init(baseURL: URL, path: String, signer: Signer, timeout: TimeInterval = 10, maxBatchSize: Int = 10, backend: API = JSONAPI()) {
        self.baseURL = baseURL
        self.path = path
        self.signer = signer
        self.timeout = timeout
        self.maxBatchSize = maxBatchSize
        self.backend = backend
    }
    
    public func dispatch(events: [Event], completion: @escaping (Error?) -> Void) {
        send(events: events, completion: completion)
    }
    
    public func dispatch(event: Event, completion: @escaping (Error?) -> Void) {
        send(events: [event], completion: completion)
    }
    
    private func send(events: [Event], completion: @escaping (Error?) -> Void) {
        backend.trigger(method: .POST, baseURL: baseURL, resource: path, headers: nil, params: nil, body: events,
                        decorator: signer.sign, completion: completion)
    }
}
