//
//  CacheAsyncTests.swift
//  
//
//  Created by fluidmobile on 29/01/2020.
//

import XCTest
@testable import Cache

final class CacheAsyncTests: XCTestCase {
    
    private lazy var disk = DiskSetting(location: .cache, identifier: "jsonAsync", storeDuration: .minutes(10), maxSize: .KB(10))
    private lazy var shortDisk = DiskSetting(location: .cache, identifier: "jsonShortAsync", storeDuration: .seconds(5), maxSize: .B(230))
    private lazy var cache = CacheStore(diskSetting: disk)
    private lazy var shortCache = CacheStore(diskSetting: shortDisk)
    private var str: String { "Hello World \(UUID().uuidString)" }
    private var content: (string: String, data: Data) {
        let string = str
        return (string, string.data(using: .utf8)!)
    }
    
    override func setUp() {
        try? cache.deleteAll()
        try? shortCache.deleteAll()
    }
    
    override func tearDown() {
        try? cache.deleteAll()
        try? shortCache.deleteAll()
    }
    
    
    func testPersistAndLoadAsync() {
        let content = self.content
        let filename = "Test . / ✊"
        var exp = expectation(description: "testPersistAndLoad")
        cache.persist(cachable: CacheData(name: filename, data: content.data), completion: { result in
            switch result {
            case .success:
                exp.fulfill()
            case .failure(let error):
                XCTFail("testPersistAndLoadAsync: failed! Error: \(error.localizedDescription)")
                return
            }
        })
        
        wait(for: [exp], timeout: 1)
        
        exp = expectation(description: "testPersistAndLoad")
        cache.load(name: filename, type: CacheData.self, completion: { result in
            switch result {
            case .success(let dataFromCache):
                guard let dataFromCache = dataFromCache?.data else {
                    XCTFail("testPersistAndLoadAsync: failed! load from cach returned nil")
                    return
                }
                let message = String(data: dataFromCache, encoding: .utf8)
                XCTAssertEqual(message, content.string, "testPersistAndLoadAsync: failed! \(message ?? "nil") != \(content.string)")
                exp.fulfill()
            case .failure(let error):
                XCTFail("testPersistAndLoadAsync: failed! Error: \(error)")
                return
            }
        })
        
        wait(for: [exp], timeout: 1)
         
    }
    
    func testPersistMultipleAsync() {
        var batchData: [Cachable] = []
        for i in 0...100 {
            batchData.append(CacheData(name: "Batch\(i)", data: content.data))
        }
        
        let exp = expectation(description: "testPersistMultipleAsync")
        cache.persist(cachables: batchData, completion: { result in
            switch result {
            case .success:
                self.cache.load(name: "Batch10", type: CacheData.self, completion: { result in
                    switch result {
                    case .success(let data):
                        XCTAssertEqual(data?.data, batchData[10].data, "\(String(describing: data?.data)) != \(String(describing: batchData[11].data))")
                        exp.fulfill()
                    case .failure(let error):
                        XCTFail("testPersistMultipleAsync: failed! Error: \(error)")
                        return
                    }
                })
            case .failure(let error):
                XCTFail("testPersistMultipleAsync: failed! Error: \(error)")
                return
            }
        })
        
        wait(for: [exp], timeout: 2)
    }
    
    func testDeleteAllAsync() {
        for i in 0...4 {
            try? cache.persist(cachable: CacheData(name: "Test\(i)", data: content.data))
        }
        let exp = expectation(description: "testDeleteAllAsync")
        cache.deleteAll(completion: { result in
            switch result {
            case .success:
                self.cache.load(name: "Test2", type: CacheData.self, completion: { result in
                    switch result {
                    case .success(let data):
                        if data?.data != nil {
                            XCTFail("testDeleteAllAsync: failed! Data != nil")
                            return
                        }
                        exp.fulfill()
                    case .failure(let error):
                        XCTFail("testDeleteAllAsync: failed! Error: \(error)")
                        return
                    }
                    
                })
            case .failure(let error):
                XCTFail("testDeleteAllAsync: failed! Error: \(error)")
                return
            }
        })
        
        wait(for: [exp], timeout: 2)
    }
    
    func testDeleteSingleAsync() {
        let datas = [CacheData(name: "A", data: content.data),
                     CacheData(name: "B", data: content.data),
                     CacheData(name: "C", data: content.data)]
        
        let exp = expectation(description: "testDeleteSingle")
        cache.persist(cachables: datas, completion: { result in
            switch result {
            case .success:
                self.cache.delete(name: "B", completion: { result in
                    switch result {
                    case .success:
                        exp.fulfill()
                    case .failure(let error):
                        XCTFail("testDeleteSingleAsync: failed! Error: \(error)")
                        return
                    }
                })
            case .failure(let error):
                XCTFail("testDeleteSingleAsync: failed! Error: \(error)")
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
                XCTAssertEqual(data?.data, datas[0].data, "\(String(describing: data?.data)) != \(String(describing:datas[0].data))")
                expA.fulfill()
            case .failure(let error):
                XCTFail("testDeleteSingleAsync: failed! Error: \(error)")
                return
            }
        })
        
        cache.load(name: "B", type: CacheData.self, completion: { result in
            switch result {
            case .success(let data):
                if data?.data != nil {
                    XCTFail("DATA is not empty")
                    return
                }
                expB.fulfill()
            case .failure(let error):
                XCTFail("testDeleteSingleAsync: failed! Error: \(error)")
                return
            }
        })
        
        cache.load(name: "C", type: CacheData.self, completion: { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data?.data, datas[2].data, "\(String(describing: data?.data)) != \(String(describing:datas[2].data))")
                expC.fulfill()
            case .failure(let error):
                XCTFail("testDeleteSingleAsync: failed! Error: \(error)")
                return
            }
        })
        
        wait(for: [expA, expB, expC], timeout: 2)
    }
    
    func testDurationAsync() {
//        let exp = expectation(description: "Wait cache cleanup")
//        shortCache.persist(cachable: CacheData(name: "Test", data: content.data), completion: { result in
//            switch result {
//            case .success:
//                DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
//                    let data = try? self.shortCache.load(name: "Test", type: CacheData.self).data
//                    if data != nil {
//                        XCTFail("DATA is not empty")
//                        return
//                    }
//                    exp.fulfill()
//                }
//            case .failure(let error):
//                XCTFail("testDurationAsync: failed! Error: \(error)")
//                return
//            }
//        })
//        
//        wait(for: [exp], timeout: 9)
    }
    
    func testSizeAsync() {
        let exp = expectation(description: "testSizeAsync")
        let datas = [CacheData(name: "Test0", data: content.data),
                     CacheData(name: "Test1", data: content.data),
                     CacheData(name: "Test2", data: content.data),
                     CacheData(name: "Test3", data: content.data),
                     CacheData(name: "Test4", data: content.data)]
        
        shortCache.deleteAll(completion: { _ in
            self.shortCache.persist(cachables: datas, completion: { result in
                switch result {
                case .success:
                    exp.fulfill()
                case .failure(let error):
                    XCTFail("testSizeAsync: failed! Error: \(error)")
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
                XCTAssertEqual(data?.data, nil, "DATA is not nil")
                exp0.fulfill()
            case .failure(let error):
                XCTFail("testSizeAsync: failed! Error: \(error)")
                return
            }
        })
        
        shortCache.load(name: "Test1", type: CacheData.self, completion: { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data?.data, datas[1].data)
                exp1.fulfill()
            case .failure(let error):
                XCTFail("testSizeAsync: failed! Error: \(error)")
                return
            }
        })
        
        shortCache.load(name: "Test2", type: CacheData.self, completion: { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data?.data, datas[2].data)
                exp2.fulfill()
            case .failure(let error):
                XCTFail("testSizeAsync: failed! Error: \(error)")
                return
            }
        })
        
        shortCache.load(name: "Test3", type: CacheData.self, completion: { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data?.data, datas[3].data)
                exp3.fulfill()
            case .failure(let error):
                XCTFail("testSizeAsync: failed! Error: \(error)")
                return
            }
        })
        
        shortCache.load(name: "Test4", type: CacheData.self, completion: { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data?.data, datas[4].data)
                exp4.fulfill()
            case .failure(let error):
                XCTFail("testSizeAsync: failed! Error: \(error)")
                return
            }
        })

        wait(for: [exp0, exp1, exp2, exp3, exp4], timeout: 2)
    }
    
    func testInfoAsync() {
        let exp = expectation(description: "testInfoAsync")
        let dateBefore = Date()
        let cachable = CacheData(name: "TestSize", data: content.data)
        try? cache.persist(cachable: cachable)
        cache.info(name: "TestSize", completion: { result in
            switch result {
            case .success(let infos):
                let dateAfter = Date()
                
                XCTAssertEqual(infos.size, cachable.data?.count ?? 0, "Size not equal: \(infos.size) != 11")
                XCTAssertTrue(infos.creationDate >= dateBefore && infos.creationDate <= dateAfter,
                              "Date before: \(dateBefore) - Date create: \(infos.creationDate) - Date after: \(dateAfter)")
                XCTAssertTrue(infos.modifiedDate >= dateBefore && infos.modifiedDate <= dateAfter,
                              "Date before: \(dateBefore) - Date modified: \(infos.modifiedDate) - Date after: \(dateAfter)")
                exp.fulfill()
            case .failure(let error):
                XCTFail("testInfoAsync: failed! Error: \(error)")
                return
            }
        })
        wait(for: [exp], timeout: 2)
    }
    
    static var allTests = [
        ("testInfoAsync", testInfoAsync),
        ("testSizeAsync", testSizeAsync),
        ("testDurationAsync", testDurationAsync),
        ("testDeleteSingleAsync", testDeleteSingleAsync),
        ("testDeleteAllAsync", testDeleteAllAsync),
        ("testPersistMultipleAsync", testPersistMultipleAsync),
        ("testPersistAndLoadAsync", testPersistAndLoadAsync)
    ]
}
