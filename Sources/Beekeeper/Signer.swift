//
//  Signer.swift
//  Beekeeper
//
//  Created by Andreas Ganske on 22.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import Foundation
import CryptoSwift

public protocol Signer: Sendable {
    func sign(request: inout URLRequest)
    func sign(request: inout URLRequest, date: Date)
}

public extension Signer {
    func sign(request: inout URLRequest) {
        sign(request: &request, date: Date())
    }
}

public struct SimpleSigner: Signer {
    
    let secret: String
    
    public init(secret: String) {
        self.secret = secret
    }
    
    public func sign(request: inout URLRequest, date: Date) {
        guard let body = request.httpBody else { return }
        let signature = try! HMAC(key: secret.bytes, variant: .sha2(.sha256)).authenticate(body.byteArray)
        request.setValue(signature.toBase64(), forHTTPHeaderField: "authorization")
    }
}

public struct RequestSigner: Signer {
    
    let secret: String
    
    public init(secret: String) {
        self.secret = secret
    }
    
    public func sign(request: inout URLRequest, date: Date) {
        let method = request.httpMethod ?? "GET"
        let path = request.url?.path ?? ""
        let contentType = request.value(forHTTPHeaderField: "content-type") ?? ""
        
        let dateFormatter = ISO8601DateFormatter()
        let dateString = dateFormatter.string(from: date)
        let body = request.httpBody
        let contentHash = body != nil ? Digest.sha1(body!.byteArray).toHexString() : ""
        
        let string = """
                     \(method)
                     \(contentHash)
                     \(contentType)
                     \(dateString)
                     \(path)
                     """
        
        let signature = try! HMAC(key: secret.bytes, variant: .sha2(.sha256)).authenticate(string.bytes)
        request.setValue(dateString, forHTTPHeaderField: "authorization-date")
        request.setValue(signature.toBase64(), forHTTPHeaderField: "authorization")
    }
}
