//
//  DispatcherTest.swift
//  BeekeeperTests
//
//  Created by Andreas Ganske on 15.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import Testing
import Foundation
@testable import Beekeeper

struct MockSigner: Signer {
    let callback: (@Sendable (URLRequest) -> Void)?

    init(callback: (@Sendable (URLRequest) -> Void)? = nil) {
        self.callback = callback
    }
    
    func sign(request: inout URLRequest, date: Date) {
        callback?(request)
    }
}

//class MockAPI: API {
//
//    var encoder: JSONEncoder = JSONEncoder()
//    var decoder: JSONDecoder = JSONDecoder()
//
//    var response: () -> Any
//    
//    init(response: @escaping () -> Any) {
//        self.response = response
//    }
//
//    func request<T, U, E>(method: APIMethod,
//                          baseURL: URL,
//                          resource: String,
//                          headers: [String: String]?,
//                          params: [String: Any]?,
//                          body: T?,
//                          error: E.Type,
//                          decorator: ((inout URLRequest) -> Void)?) async throws -> U where T: Encodable, U: Decodable, E: (Error & Decodable) {
//        let value = response()
//        if let value = value as? U {
//            return value
//        } else if let error = value as? Error {
//            throw error
//        } else {
//            fatalError()
//        }
//    }
//}

struct MockRequester: AsynchronousRequester {
    
    let callback: @Sendable () async throws -> (Data, URLResponse)
    
    func data(
        for request: URLRequest
    ) async throws -> (Data, URLResponse) {
        try await callback()
    }
}

struct DispatcherTest {

    let url = URL(string: "example.org")!
    
    @Test
    func testDispatching() async throws {
        let signer = MockSigner()
        
        try await confirmation { confirm in
            let requester = MockRequester {
                confirm()
                return (Data(), HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!)
            }
            let dispatcher = URLDispatcher(baseURL: url, path: "/", signer: signer, requester: requester)
            
            let install = Date()
            let event = Event(id: "1", product: "0", timestamp: install.addingTimeInterval(1), name: "name", group: "group", detail: "detail", value: 42, previousEvent: "previous", previousEventTimestamp: install.day, install: install.day, custom: ["123", nil, "345"])
            
            try await dispatcher.dispatch(event: event)
        }
    }
    
    @Test
    func testDispatchingWithError() async throws {
        let signer = MockSigner()
        let expectedError = URLDispatcherError(error: "Test-Error")
        
        await confirmation { confirm in
            let requester = MockRequester {
                confirm()
                throw expectedError
            }
            let dispatcher = URLDispatcher(baseURL: url, path: "/", signer: signer, requester: requester)
            
            let install = Date()
            let event = Event(id: "1", product: "0", timestamp: install.addingTimeInterval(1), name: "name", group: "group", detail: "detail", value: 42, previousEvent: "previous", previousEventTimestamp: install.day, install: install.day, custom: ["123", nil, "345"])
            
            do {
                try await dispatcher.dispatch(event: event)
                Issue.record("An error should have occured")
            } catch {
                guard let error = error as? URLDispatcherError else {
                    Issue.record("An URLDispatcherError should have occured")
                    return
                }
                #expect(error.error == expectedError.error)
            }
        }
    }
}
