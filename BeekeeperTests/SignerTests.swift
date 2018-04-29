//
//  SignerTests.swift
//  BeekeeperTests
//
//  Created by Andreas Ganske on 22.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import XCTest
@testable import Beekeeper

class SignerTests: XCTestCase {
    func testSignature() {
        let signer = RequestSigner(secret: "1234")
        
        let url = URL(string: "https://example.com/path")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = "body".data(using: .utf8)
        signer.sign(request: &urlRequest)
        let signature = urlRequest.value(forHTTPHeaderField: "Authorization")
        let authorizationDate = urlRequest.value(forHTTPHeaderField: "Authorization-Date")
        XCTAssertNotNil(signature)
        XCTAssertNotNil(authorizationDate)
    }
}
