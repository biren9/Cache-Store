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
        cache.persist(cachable: CacheData(name: "Test", data: data), completion: { result in
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
        cache.load(name: "Test", type: CacheData.self, completion: { result in
            switch result {
            case .success(let dataFromCache):
                guard let dataFromCache = dataFromCache?.data else {
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
            batchData.append(CacheData(name: "Batch\(i)", data: data))
        }
        
        let exp = expectation(description: "testPersistMultipleAsync")
        cache.persist(cachables: batchData, completion: { result in
            switch result {
            case .success:
                self.cache.load(name: "Batch10", type: CacheData.self, completion: { result in
                    switch result {
                    case .success(let data):
                        XCTAssertEqual(data?.data, self.data)
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
            try? cache.persist(cachable: CacheData(name: "Test\(i)", data: data))
        }
        let exp = expectation(description: "testDeleteAllAsync")
        cache.deleteAll(completion: { result in
            switch result {
            case .success:
                self.cache.load(name: "Test2", type: CacheData.self, completion: { result in
                    switch result {
                    case .success(let data):
                        if data?.data != nil {
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
        let datas = [CacheData(name: "A", data: data),
                     CacheData(name: "B", data: data),
                     CacheData(name: "C", data: data)]
        
        let exp = expectation(description: "testDeleteSingle")
        cache.persist(cachables: datas, completion: { result in
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
        
        cache.load(name: "A", type: CacheData.self, completion: { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data?.data, self.data)
                expA.fulfill()
            case .failure:
                XCTFail()
                return
            }
        })
        
        cache.load(name: "B", type: CacheData.self, completion: { result in
            switch result {
            case .success(let data):
                if data?.data != nil {
                    XCTFail()
                    return
                }
                expB.fulfill()
            case .failure:
                XCTFail()
                return
            }
        })
        
        cache.load(name: "C", type: CacheData.self, completion: { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data?.data, self.data)
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
        shortCache.persist(cachable: CacheData(name: "Test", data: data), completion: { result in
            switch result {
            case .success:
                DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                    let data = try? self.shortCache.load(name: "Test", type: CacheData.self).data
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
        let datas = [CacheData(name: "Test0", data: data),
                     CacheData(name: "Test1", data: data),
                     CacheData(name: "Test2", data: data),
                     CacheData(name: "Test3", data: data),
                     CacheData(name: "Test4", data: data)]
        
        shortCache.deleteAll(completion: { _ in
            self.shortCache.persist(cachables: datas, completion: { result in
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
        
        shortCache.load(name: "Test0", type: CacheData.self, completion: { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data?.data, nil)
                exp0.fulfill()
            case .failure:
                XCTFail()
                return
            }
        })
        
        shortCache.load(name: "Test1", type: CacheData.self, completion: { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data?.data, self.data)
                exp1.fulfill()
            case .failure:
                XCTFail()
                return
            }
        })
        
        shortCache.load(name: "Test2", type: CacheData.self, completion: { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data?.data, self.data)
                exp2.fulfill()
            case .failure:
                XCTFail()
                return
            }
        })
        
        shortCache.load(name: "Test3", type: CacheData.self, completion: { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data?.data, self.data)
                exp3.fulfill()
            case .failure:
                XCTFail()
                return
            }
        })
        
        shortCache.load(name: "Test4", type: CacheData.self, completion: { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data?.data, self.data)
                exp4.fulfill()
            case .failure:
                XCTFail()
                return
            }
        })

        wait(for: [exp0, exp1, exp2, exp3, exp4], timeout: 2)
    }
    
    func testInfoAsync() {
        let exp = expectation(description: "testInfoAsync")
        let dateBefore = Date()
        try? cache.persist(cachable: CacheData(name: "TestSize", data: data))
        cache.info(name: "TestSize", completion: { result in
            switch result {
            case .success(let infos):
                let dateAfter = Date()
                
                XCTAssertEqual(infos.size, 11)
                XCTAssert(infos.creationDate >= dateBefore && infos.creationDate <= dateAfter)
                XCTAssert(infos.modifiedDate >= dateBefore && infos.modifiedDate <= dateAfter)
                exp.fulfill()
            case .failure:
                XCTFail()
                return
            }
        })
        wait(for: [exp], timeout: 2)
    }
    
}
