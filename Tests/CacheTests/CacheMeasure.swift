//
//  File.swift
//  
//
//  Created by Gil Biren on 28/01/2020.
//

import XCTest
@testable import Cache

final class CacheMeasure: XCTestCase {
    private lazy var disk = DiskSetting(location: .cache, identifier: "json", storeDuration: .minutes(10), maxSize: .MB(10))
    private lazy var cache = CacheStore(diskSetting: disk)
    private let str = "Hello World"
    private lazy var data: Data = {
        return str.data(using: .utf8)!
    }()
    
    override func setUp() {
        try? cache.deleteAll()
    }
    
    override func tearDown() {
        try? cache.deleteAll()
    }
    
    func testMeasure() {
        measure {
            for i in 0..<10 {
                try? cache.persist(data: CacheData(name: "Test\(i)", content: data))
            }
            try? cache.deleteAll()
        }
    }
}
