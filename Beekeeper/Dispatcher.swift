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
    func dispatch(event: Event, completion: @escaping (RequestError<URLDispatcherError>?) -> Void)
    func dispatch(events: [Event], completion: @escaping (RequestError<URLDispatcherError>?) -> Void)
}

public class URLDispatcherError: Codable, Error {
    public let error: String
}

public class URLDispatcher: Dispatcher {
    let baseURL: URL
    let path: String
    let backend: API
    let signer: Signer
    
    public let timeout: TimeInterval
    public var maxBatchSize: Int
    
    public init(baseURL: URL, path: String, signer: Signer, timeout: TimeInterval = 30, maxBatchSize: Int = 10, backend: API = JSONAPI()) {
        self.baseURL = baseURL
        self.path = path
        self.signer = signer
        self.timeout = timeout
        self.maxBatchSize = maxBatchSize
        self.backend = backend
    }
    
    public func dispatch(events: [Event], completion: @escaping (RequestError<URLDispatcherError>?) -> Void) {
        send(events: events, completion: completion)
    }
    
    public func dispatch(event: Event, completion: @escaping (RequestError<URLDispatcherError>?) -> Void) {
        send(events: [event], completion: completion)
    }
    
    private func send(events: [Event], completion: @escaping (RequestError<URLDispatcherError>?) -> Void) {
        backend.request(method: .POST, baseURL: baseURL, resource: path, headers: nil, params: nil, body: events,
                        decorator: signer.sign, completion: { (response: Result<None, RequestError<URLDispatcherError>>) in
                            switch response {
                            case .success(_):
                                completion(nil)
                            case .failure(let error):
                                completion(error)
                            }
        })
    }
}
