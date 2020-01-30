//
//  File.swift
//  
//
//  Created by Gil Biren on 28/01/2020.
//

import XCTest
@testable import Cache

final class CacheMeasure: XCTestCase {
    private lazy var disk = DiskSetting(location: .cache, identifier: "jsonMeasure", storeDuration: .minutes(10), maxSize: .MB(10))
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
    
    func testMeasureSingle() {
        measure {
            for i in 0..<10 {
                try? cache.persist(cachable: CacheData(name: "Test\(i)", data: data))
            }
            try? cache.deleteAll()
        }
    }
    
    func testMeasureBatch() {
        var datas: [Cachable] = []
        for i in 0..<10 {
            datas.append(CacheData(name: "Test\(i)", data: data))
        }
        measure {
            try? cache.persist(cachables: datas)
            try? cache.deleteAll()
        }
    }
    
    static var allTests = [
        ("testMeasureSingle", testMeasureSingle),
        ("testMeasureBatch", testMeasureBatch)
    ]
}
