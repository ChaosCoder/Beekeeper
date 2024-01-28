//
//  DispatcherTest.swift
//  BeekeeperTests
//
//  Created by Andreas Ganske on 15.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import XCTest
import ConvAPI
@testable import Beekeeper

class MockSigner: Signer {
    var callback: ((URLRequest) -> Void)? = nil

    func sign(request: inout URLRequest, date: Date) {
        callback?(request)
    }
}

class MockAPI: API {

    var encoder: JSONEncoder = JSONEncoder()
    var decoder: JSONDecoder = JSONDecoder()

    var response: () -> Any
    
    init(response: @escaping () -> Any) {
        self.response = response
    }

    func request<T, U, E>(method: APIMethod,
                          baseURL: URL,
                          resource: String,
                          headers: [String: String]?,
                          params: [String: Any]?,
                          body: T?,
                          error: E.Type,
                          decorator: ((inout URLRequest) -> Void)?) async throws -> U where T: Encodable, U: Decodable, E: (Error & Decodable) {
        let value = response()
        if let value = value as? U {
            return value
        } else if let error = value as? Error {
            throw error
        } else {
            fatalError()
        }
    }
}

class DispatcherTest: XCTestCase {

    let url = URL(string: "example.org")!
    
    func testDispatching() async throws {
        let signer = MockSigner()
        let expectation = self.expectation(description: "Expectation")
        
        let mockBackend = MockAPI {
            expectation.fulfill()
            return EmptyResponse()
        }

        let dispatcher = URLDispatcher(baseURL: url, path: "/", signer: signer, backend: mockBackend)
        
        let install = Date()
        let event = Event(id: "1", product: "0", timestamp: install.addingTimeInterval(1), name: "name", group: "group", detail: "detail", value: 42, previousEvent: "previous", previousEventTimestamp: install.day, install: install.day, custom: ["123", nil, "345"])
        
        try await  dispatcher.dispatch(event: event)
        await fulfillment(of: [expectation])
    }
    
    func testDispatchingWithError() async throws {
        let signer = MockSigner()
        let expectedError = URLDispatcherError(error: "Test-Error")
        let expectation = self.expectation(description: "Expectation")
        let mockBackend = MockAPI {
            expectation.fulfill()
            return expectedError
        }
        let dispatcher = URLDispatcher(baseURL: url, path: "/", signer: signer, backend: mockBackend)
        
        let install = Date()
        let event = Event(id: "1", product: "0", timestamp: install.addingTimeInterval(1), name: "name", group: "group", detail: "detail", value: 42, previousEvent: "previous", previousEventTimestamp: install.day, install: install.day, custom: ["123", nil, "345"])
        
        do {
            try await dispatcher.dispatch(event: event)
            XCTFail("An error should have occured")
        } catch {
            guard let error = error as? URLDispatcherError else {
                return XCTFail()
            }
            XCTAssertEqual(error.error, expectedError.error)
        }
        
        await fulfillment(of: [expectation])
    }
}
