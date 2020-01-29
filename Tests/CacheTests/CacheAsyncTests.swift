//
//  CacheAsyncTests.swift
//  
//
//  Created by fluidmobile on 29/01/2020.
//

import XCTest
@testable import Cache

final class CacheAsyncTest: XCTestCase {
    
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
    
    
    func testPersistAndLoadAsync() {
        var exp = expectation(description: "testPersistAndLoad")
        cache.persist(data: CacheData(name: "Test", content: data), completion: { result in
            switch result {
            case .success:
                exp.fulfill()
            case .failure:
                XCTFail()
                return
            }
        })
        
        wait(for: [exp], timeout: 1)
        
        exp = expectation(description: "testPersistAndLoad")
        cache.load(name: "Test", completion: { result in
            switch result {
            case .success(let dataFromCache):
                guard let dataFromCache = dataFromCache else {
                    XCTFail()
                    return
                }
                let message = String(data: dataFromCache, encoding: .utf8)
                XCTAssertEqual(message, "Hello World")
                exp.fulfill()
            case .failure:
                XCTFail()
                return
            }
        })
        
        wait(for: [exp], timeout: 1)
         
    }
    
    func testPersistMultipleAsync() {
        var batchData: [Cachable] = []
        for i in 0...100 {
            batchData.append(CacheData(name: "Batch\(i)", content: data))
        }
        
        let exp = expectation(description: "testPersistMultipleAsync")
        cache.persist(datas: batchData, completion: { result in
            switch result {
            case .success:
                self.cache.load(name: "Batch10", completion: { result in
                    switch result {
                    case .success(let data):
                        XCTAssertEqual(data, self.data)
                        exp.fulfill()
                    case .failure:
                        XCTFail()
                        return
                    }
                })
            case .failure:
                XCTFail()
                return
            }
        })
        
        wait(for: [exp], timeout: 2)
    }
    
    func testDeleteAllAsync() {
        for i in 0...4 {
            try? cache.persist(data: CacheData(name: "Test\(i)", content: data))
        }
        let exp = expectation(description: "testDeleteAllAsync")
        cache.deleteAll(completion: { result in
            switch result {
            case .success:
                self.cache.load(name: "Test2", completion: { result in
                    switch result {
                    case .success(let data):
                        if data != nil {
                            XCTFail()
                            return
                        }
                        exp.fulfill()
                    case .failure:
                        XCTFail()
                        return
                    }
                    
                })
            case .failure:
                XCTFail()
                return
            }
        })
        
        wait(for: [exp], timeout: 2)
    }
    
    func testDeleteSingleAsync() {
        let datas = [CacheData(name: "A", content: data),
                     CacheData(name: "B", content: data),
                     CacheData(name: "C", content: data)]
        
        let exp = expectation(description: "testDeleteSingle")
        cache.persist(datas: datas, completion: { result in
            switch result {
            case .success:
                self.cache.delete(name: "B", completion: { result in
                    switch result {
                    case .success:
                        exp.fulfill()
                    case .failure:
                        XCTFail()
                        return
                    }
                })
            case .failure:
                XCTFail()
                return
            }
        })
        
        wait(for: [exp], timeout: 2)
        
        let expA = expectation(description: "testDeleteSingle")
        let expB = expectation(description: "testDeleteSingle")
        let expC = expectation(description: "testDeleteSingle")
        
        cache.load(name: "A", completion: { result in
            switch result {
            case .success(let data):
                 XCTAssertEqual(data, self.data)
                 expA.fulfill()
            case .failure:
                XCTFail()
                return
            }
        })
        
        cache.load(name: "B", completion: { result in
            switch result {
            case .success(let data):
                if data != nil {
                    XCTFail()
                    return
                }
                expB.fulfill()
            case .failure:
                XCTFail()
                return
            }
        })
        
        cache.load(name: "C", completion: { result in
            switch result {
            case .success(let data):
                 XCTAssertEqual(data, self.data)
                expC.fulfill()
            case .failure:
                XCTFail()
                return
            }
        })
        
        wait(for: [expA, expB, expC], timeout: 2)
    }
    
    func testDurationAsync() {
        let exp = expectation(description: "Wait cache cleanup")
        shortCache.persist(data: CacheData(name: "Test", content: data), completion: { result in
            switch result {
            case .success:
                DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                    let data = try? self.shortCache.load(name: "Test")
                    if data != nil {
                        XCTFail()
                        return
                    }
                    exp.fulfill()
                }
            case .failure:
                XCTFail()
                return
            }
        })
        
        wait(for: [exp], timeout: 9)
    }
    
    func testSizeAsync() {
        let exp = expectation(description: "testSizeAsync")
        let datas = [CacheData(name: "Test0", content: data),
                     CacheData(name: "Test1", content: data),
                     CacheData(name: "Test2", content: data),
                     CacheData(name: "Test3", content: data),
                     CacheData(name: "Test4", content: data)]
        
        shortCache.deleteAll(completion: { _ in
            self.shortCache.persist(datas: datas, completion: { result in
                switch result {
                case .success:
                    exp.fulfill()
                case .failure:
                    XCTFail()
                    return
                }
            })
        })
        
        wait(for: [exp], timeout: 2)
        
        let exp0 = expectation(description: "testSizeAsync")
        let exp1 = expectation(description: "testSizeAsync")
        let exp2 = expectation(description: "testSizeAsync")
        let exp3 = expectation(description: "testSizeAsync")
        let exp4 = expectation(description: "testSizeAsync")
        
        shortCache.load(name: "Test0", completion: { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data, nil)
                exp0.fulfill()
            case .failure:
                XCTFail()
                return
            }
        })
        
        shortCache.load(name: "Test1", completion: { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data, self.data)
                exp1.fulfill()
            case .failure:
                XCTFail()
                return
            }
        })
        
        shortCache.load(name: "Test2", completion: { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data, self.data)
                exp2.fulfill()
            case .failure:
                XCTFail()
                return
            }
        })
        
        shortCache.load(name: "Test3", completion: { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data, self.data)
                exp3.fulfill()
            case .failure:
                XCTFail()
                return
            }
        })
        
        shortCache.load(name: "Test4", completion: { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data, self.data)
                exp4.fulfill()
            case .failure:
                XCTFail()
                return
            }
        })

        wait(for: [exp0, exp1, exp2, exp3, exp4], timeout: 2)
    }
    
}
