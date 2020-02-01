//
//  File.swift
//  
//
//  Created by Gil Biren on 29/01/2020.
//

#if !os(Linux)

import XCTest
@testable import Cache

class CacheImageTests: XCTestCase {
    private lazy var disk = DiskSetting(location: .cache, identifier: "images", storeDuration: .minutes(10), maxSize: .MB(10))
    private lazy var cache = CacheStore(diskSetting: disk)
    private static let url = URL(string: "https://upload.wikimedia.org/wikipedia/commons/4/47/PNG_transparency_demonstration_1.png")!
    
    static func properImageData() -> Data? {
        #if canImport(AppKit)
        guard let imageData = try? Data(contentsOf: url), let image = NSImage(data: imageData)?.pngData() else {
            return nil
        }
        return image
        #endif
        
        #if canImport(UIKit)
        guard let imageData = try? Data(contentsOf: url), let image = UIImage(data: imageData)?.pngData() else {
            return nil
        }
        return image
        #endif
    }
    
    func testImage() {
        guard let image = Self.properImageData() else {
            XCTFail("Download failed")
            return
        }
        let store = CacheImage(name: "image", data: image)
        try? cache.persist(cachable: store)
        let result = try? cache.load(name: "image", type: CacheImage.self)
        
        XCTAssertEqual(image, result?.data)
    }
}

#endif
