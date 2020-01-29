import XCTest
@testable import Cache

final class CacheTests: XCTestCase {
    
    private lazy var disk = DiskSetting(location: .cache, identifier: "json", storeDuration: .minutes(10), maxSize: .KB(10))
    private lazy var shortDisk = DiskSetting(location: .cache, identifier: "jsonShort", storeDuration: .seconds(5), maxSize: .B(50))
    private lazy var cache = CacheStore(diskSetting: disk)
    private lazy var shortCache = CacheStore(diskSetting: shortDisk)
    private let str = "Hello World"
    private lazy var data: Data = {
        return str.data(using: .utf8)!
    }()
    
    override func setUp() {
        try? cache.deleteAll()
        try? shortCache.deleteAll()
    }
    
    override func tearDown() {
        try? cache.deleteAll()
        try? shortCache.deleteAll()
    }
    
    
    func testPersistAndLoad() {
        try? cache.persist(cachable: CacheData(name: "Test", data: data))
        guard let dataFromCache = try? cache.load(name: "Test", type: CacheData.self).data else {
            XCTFail()
            return
        }
        
        let message = String(data: dataFromCache, encoding: .utf8)
        XCTAssertEqual(message, "Hello World")
    }
    
    func testPersistMultiple() {
        var batchData: [Cachable] = []
        for i in 0...100 {
            batchData.append(CacheData(name: "Batch\(i)", data: data))
        }
        try? cache.persist(cachables: batchData)
        
        var data = try? cache.load(name: "Batch10", type: CacheData.self).data
        XCTAssertEqual(data, self.data)
        
        data = try? cache.load(name: "Batch0", type: CacheData.self).data
        XCTAssertEqual(data, self.data)
        
        data = try? cache.load(name: "Batch73", type: CacheData.self).data
        XCTAssertEqual(data, self.data)
    }
    
    func testDeleteAll() {
        for i in 0...4 {
            try? cache.persist(cachable: CacheData(name: "Test\(i)", data: data))
        }
        try? cache.deleteAll()
        
        let data = try? cache.load(name: "Test2", type: CacheData.self).data
        if data != nil {
            XCTFail()
            return
        }
    }
    
    func testDeleteSingle() {
        try? cache.persist(cachable: CacheData(name: "A", data: data))
        try? cache.persist(cachable: CacheData(name: "B", data: data))
        try? cache.persist(cachable: CacheData(name: "C", data: data))
        try? cache.delete(name: "B")
        
        var data = try? cache.load(name: "B", type: CacheData.self).data
        if data != nil {
            XCTFail()
            return
        }
        
        data = try? cache.load(name: "A", type: CacheData.self).data
        XCTAssertEqual(data, self.data)
        data = try? cache.load(name: "C", type: CacheData.self).data
        XCTAssertEqual(data, self.data)
    }
    
    func testDuration() {
        try? shortCache.persist(cachable: CacheData(name: "Test", data: data))
        let _expectation = expectation(description: "Wait cache cleanup")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
            let data = try? self.shortCache.load(name: "Test", type: CacheData.self).data
            if data != nil {
                XCTFail()
                return
            }
            _expectation.fulfill()
        }
    
        waitForExpectations(timeout: 9, handler: nil)
    }
    
    func testSize() {
        try? shortCache.deleteAll()
        for i in 0...4 {
            try? shortCache.persist(cachable: CacheData(name: "Test\(i)", data: data))
        }
        
        var data = try? shortCache.load(name: "Test0", type: CacheData.self).data
        XCTAssertEqual(data, nil)
        
        data = try? shortCache.load(name: "Test1", type: CacheData.self).data
        XCTAssertEqual(data, self.data)
        data = try? shortCache.load(name: "Test2", type: CacheData.self).data
        XCTAssertEqual(data, self.data)
        data = try? shortCache.load(name: "Test3", type: CacheData.self).data
        XCTAssertEqual(data, self.data)
        data = try? shortCache.load(name: "Test4", type: CacheData.self).data
        XCTAssertEqual(data, self.data)
    }
}
