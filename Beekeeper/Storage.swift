//
//  Storage.swift
//  Beekeeper
//
//  Created by Andreas Ganske on 14.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import Foundation

public protocol Storage {
    func value<T: Decodable>(for key: String) -> T?
    mutating func set<T: Encodable>(value: T, for key: String) throws
    
    mutating func set(string: String, for key: String)
    func string(forKey key: String) throws -> String?
    
    mutating func removeValue(for key: String)
}

extension UserDefaults: Storage {
    
    public func value<T: Decodable>(for key: String) -> T? {
        guard let saved = data(forKey: key),
            let value = try? JSONDecoder().decode(T.self, from: saved) else {
                return nil
        }
        return value
    }
    
    public func set<T: Encodable>(value: T, for key: String) throws {
        let data = try JSONEncoder().encode(value)
        set(data, forKey: key)
    }
    
    public func set(string: String, for key: String) {
        set(string, forKey: key)
    }
    
    public func removeValue(for key: String) {
        removeObject(forKey: key)
    }
}
