//
//  DispatcherTest.swift
//  BeekeeperTests
//
//  Created by Andreas Ganske on 15.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import XCTest
import ConvAPI
import PromiseKit
@testable import Beekeeper

class MockSigner: Signer {
    var callback: ((URLRequest) -> Void)? = nil

    func sign(request: inout URLRequest) {
        callback?(request)
    }
}

class MockAPI: API {

    var encoder: JSONEncoder = JSONEncoder()
    var decoder: JSONDecoder = JSONDecoder()

    var response: Any

    init(response: Any) {
        self.response = response
    }

    func request<T, U, E>(method: APIMethod,
                          baseURL: URL,
                          resource: String,
                          headers: [String: String]?,
                          params: [String: Any]?,
                          body: T?,
                          error: E.Type,
                          decorator: ((inout URLRequest) -> Void)?) -> Promise<U> where T: Encodable, U: Decodable, E: (Error & Decodable) {
        if let value = response as? U {
            return Promise.value(value)
        } else if let error = response as? Error {
            return Promise.init(error: error)
        } else {
            fatalError()
        }
    }
}

class DispatcherTest: XCTestCase {

    let url = URL(string: "example.org")!
    
    func testDispatching() {
        let signer = MockSigner()
        let mockBackend = MockAPI(response: EmptyResponse())

        let dispatcher = URLDispatcher(baseURL: url, path: "/", signer: signer, backend: mockBackend)
        
        let install = Date()
        let event = Event(id: "1", product: "0", timestamp: install.addingTimeInterval(1), name: "name", group: "group", detail: "detail", value: 42, previousEvent: "previous", previousEventTimestamp: install.day, install: install.day, custom: ["123", nil, "345"])
        
        let expectation = self.expectation(description: "Expectation")
        firstly {
            dispatcher.dispatch(event: event)
        }.catch { error in
            XCTFail("Unexpected error: \(error)")
        }.finally {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }
    
    func testDispatchingWithError() {
        let signer = MockSigner()
        let expectedError = URLDispatcherError(error: "Test-Error")
        let mockBackend = MockAPI(response: expectedError)
        let dispatcher = URLDispatcher(baseURL: url, path: "/", signer: signer, backend: mockBackend)
        
        let install = Date()
        let event = Event(id: "1", product: "0", timestamp: install.addingTimeInterval(1), name: "name", group: "group", detail: "detail", value: 42, previousEvent: "previous", previousEventTimestamp: install.day, install: install.day, custom: ["123", nil, "345"])
        
        let expectation = self.expectation(description: "Expectation")
        firstly {
            dispatcher.dispatch(event: event)
        }.done {
            XCTFail("An error should have occured")
        }.catch { error in
            guard let error = error as? URLDispatcherError else {
                return XCTFail()
            }
            XCTAssertEqual(error.error, expectedError.error)
        }.finally {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }
}
