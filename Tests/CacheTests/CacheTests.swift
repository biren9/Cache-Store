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
        try? cache.persist(data: CacheData(name: "Test", content: data))
        guard let dataFromCache = try? cache.load(name: "Test") else {
            XCTFail()
            return
        }
        
        let message = String(data: dataFromCache, encoding: .utf8)
        XCTAssertEqual(message, "Hello World")
    }
    
    func testPersistMultiple() {
        var batchData: [Cachable] = []
        for i in 0...100 {
            batchData.append(CacheData(name: "Batch\(i)", content: data))
        }
        try? cache.persist(datas: batchData)
        
        var data = try? cache.load(name: "Batch10")
        XCTAssertEqual(data, self.data)
        
        data = try? cache.load(name: "Batch0")
        XCTAssertEqual(data, self.data)
        
        data = try? cache.load(name: "Batch73")
        XCTAssertEqual(data, self.data)
    }
    
    func testDeleteAll() {
        for i in 0...4 {
            try? cache.persist(data: CacheData(name: "Test\(i)", content: data))
        }
        try? cache.deleteAll()
        
        let data = try? cache.load(name: "Test2")
        if data != nil {
            XCTFail()
            return
        }
    }
    
    func testDeleteSingle() {
        try? cache.persist(data: CacheData(name: "A", content: data))
        try? cache.persist(data: CacheData(name: "B", content: data))
        try? cache.persist(data: CacheData(name: "C", content: data))
        try? cache.delete(name: "B")
        
        var data = try? cache.load(name: "B")
        if data != nil {
            XCTFail()
            return
        }
        
        data = try? cache.load(name: "A")
        XCTAssertEqual(data, self.data)
        data = try? cache.load(name: "C")
        XCTAssertEqual(data, self.data)
    }
    
    func testDuration() {
        try? shortCache.persist(data: CacheData(name: "Test", content: data))
        let _expectation = expectation(description: "Wait cache cleanup")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
            let data = try? self.shortCache.load(name: "Test")
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
            try? shortCache.persist(data: CacheData(name: "Test\(i)", content: data))
        }
        
        var data = try? shortCache.load(name: "Test0")
        XCTAssertEqual(data, nil)
        
        data = try? shortCache.load(name: "Test1")
        XCTAssertEqual(data, self.data)
        data = try? shortCache.load(name: "Test2")
        XCTAssertEqual(data, self.data)
        data = try? shortCache.load(name: "Test3")
        XCTAssertEqual(data, self.data)
        data = try? shortCache.load(name: "Test4")
        XCTAssertEqual(data, self.data)
    }
}
