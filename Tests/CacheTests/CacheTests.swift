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
        try? cache.persist(data: data, name: "Test")
        guard let dataFromCache = try? cache.load(name: "Test") else {
            XCTFail()
            return
        }
        
        let message = String(data: dataFromCache, encoding: .utf8)
        XCTAssertEqual(message, "Hello World")
    }
    
    func testDeleteAll() {
        try? cache.persist(data: data, name: "Test0")
        try? cache.persist(data: data, name: "Test1")
        try? cache.persist(data: data, name: "Test2")
        try? cache.persist(data: data, name: "Test3")
        try? cache.persist(data: data, name: "Test4")
        try? cache.deleteAll()
        
        let data = try? cache.load(name: "Test2")
        if data != nil {
            XCTFail()
            return
        }
    }
    
    func testDeleteSingle() {
        try? cache.persist(data: data, name: "A")
        try? cache.persist(data: data, name: "B")
        try? cache.persist(data: data, name: "C")
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
        try? shortCache.persist(data: data, name: "Test")
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
        try? shortCache.persist(data: data, name: "Test0")
        try? shortCache.persist(data: data, name: "Test1")
        try? shortCache.persist(data: data, name: "Test2")
        try? shortCache.persist(data: data, name: "Test3")
        try? shortCache.persist(data: data, name: "Test4")
        
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
