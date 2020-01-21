//
//  Signer.swift
//  Beekeeper
//
//  Created by Andreas Ganske on 22.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import Foundation
import class CryptoSwift.HMAC
import struct CryptoSwift.Digest

public protocol Signer {
    func sign(request: inout URLRequest)
}

public class SimpleSigner: Signer {
    
    let secret: String
    
    public init(secret: String) {
        self.secret = secret
    }
    
    public func sign(request: inout URLRequest) {
        guard let body = request.httpBody else { return }
        let signature = try! HMAC(key: secret.bytes, variant: .sha256).authenticate(body.bytes)
        request.setValue(signature.toBase64(), forHTTPHeaderField: "authorization")
    }
}

public class RequestSigner: Signer {
    
    let secret: String
    
    public init(secret: String) {
        self.secret = secret
    }
    
    public func sign(request: inout URLRequest) {
        let method = request.httpMethod ?? "GET"
        let path = request.url?.path ?? ""
        let contentType = request.value(forHTTPHeaderField: "content-type") ?? ""
        
        let date = Date()
        let dateFormatter = ISO8601DateFormatter()
        let dateString = dateFormatter.string(from: date)
        let body = request.httpBody
        let contentHash = body != nil ? Digest.sha1(body!.bytes).toHexString() : ""
        
        let string = """
                     \(method)
                     \(contentHash)
                     \(contentType)
                     \(dateString)
                     \(path)
                     """
        
        let signature = try! HMAC(key: secret.bytes, variant: .sha256).authenticate(string.bytes)
        request.setValue(dateString, forHTTPHeaderField: "authorization-date")
        request.setValue(signature.toBase64(), forHTTPHeaderField: "authorization")
    }
}
