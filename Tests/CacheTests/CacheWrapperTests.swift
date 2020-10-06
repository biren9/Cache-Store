//
//  File.swift
//  
//
//  Created by Gil Biren on 06/10/2020.
//

import XCTest
@testable import Cache

final class CacheWrapperTests: XCTestCase {
    private lazy var disk = DiskSetting(location: .cache, identifier: "json", storeDuration: .minutes(10), maxSize: .KB(10))
    private lazy var cache = CacheStore(diskSetting: disk)
    
    struct TestObject: Codable, Equatable {
        let string: String
        let int: Int
        let float: Float
        let array: [Int]
    }
    
    
    override func setUp() {
        try? cache.deleteAll()
    }
    
    override func tearDown() {
        try? cache.deleteAll()
    }
    
    func testPersistAndLoadWrapper() {
        let startUpObject = TestObject(string: "test_string 123", int: 989, float: 3.17, array: [0,2,3])
        
        try? cache.persist(cachable: CacheWrapper(name: "TEST", value: startUpObject))
        guard let loadedObject = (try? cache.load(name: "TEST", type: CacheWrapper<TestObject>.self))?.value else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(startUpObject, loadedObject, "Invalid Result! Date is not equal")
    }
    
    static var allTests = [
        ("testPersistAndLoadWrapper", testPersistAndLoadWrapper)
    ]
}
