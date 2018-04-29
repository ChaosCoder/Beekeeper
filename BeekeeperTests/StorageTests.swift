//
//  StorageTests.swift
//  BeekeeperTests
//
//  Created by Andreas Ganske on 20.04.18.
//  Copyright © 2018 Andreas Ganske. All rights reserved.
//

import XCTest
@testable import Beekeeper

class StorageTests: XCTestCase {
    
    struct Test: Codable, Equatable {
        let value: String
    }
    
    func testSettingAndGetting() {
        let test = Test(value: "test1")
        var userDefaults: Storage = UserDefaults.standard
        
        try! userDefaults.set(value: test, for: "key1")
        let recovered: Test? = userDefaults.value(for: "key1")
        XCTAssertEqual(test, recovered)
    }
    
    func testRemovingValue() {
        let test = Test(value: "test2")
        var userDefaults: Storage = UserDefaults.standard
        
        try! userDefaults.set(value: test, for: "key2")
        userDefaults.removeValue(for: "key2")
    
        let recovered: Test? = userDefaults.value(for: "key2")
        XCTAssertNil(recovered)
    }
    
}
