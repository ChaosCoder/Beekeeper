//
//  JSONAPITests.swift
//  AUSTrackingTests
//
//  Created by Andreas Ganske on 15.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import XCTest
@testable import AUSTracking

class JSONAPITests: XCTestCase {
    
    struct Post: Codable, Equatable {
        let name: String
    }
    
    func testPostJSON() {
        let api = JSONAPI()
        
        let post = Post(name: "test")
        let url = URL(string: "https://putsreq.com")!
        
        let expect = self.expectation(description: "Completion")
        api.request(method: HTTPMethod.POST, baseURL: url, resource: "/2AqxIseyzrby33355GBr", body: post) { (result: Result<Post, BackendError>) in
            if case let .success(retrieved) = result {
                XCTAssertEqual(retrieved, post)
                expect.fulfill()
            } else {
                XCTFail()
            }
        }
        wait(for: [expect], timeout: 10)
    }
    
    func testGetJSON() {
        let api = JSONAPI()
        
        let url = URL(string: "https://putsreq.com")!
        let post = Post(name: "test")
        let params: [String: Any] = ["name": "test"]
        let expect = self.expectation(description: "Completion")
        
        api.request(method: HTTPMethod.GET, baseURL: url, resource: "/2AqxIseyzrby33355GBr", params: params) { (result: Result<Post, BackendError>) in
            if case let .success(retrieved) = result {
                XCTAssertEqual(retrieved, post)
                expect.fulfill()
            } else {
                XCTFail()
            }
        }
        wait(for: [expect], timeout: 10)
    }
    
}
