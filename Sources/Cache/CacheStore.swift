//
//  File.swift
//  
//
//  Created by Gil Biren on 28/01/2020.
//

import Foundation

class CacheStore {
    private let diskSetting: DiskSetting
    private let fileManager: FileManager
    let asyncQueue: DispatchQueue
    
    private typealias File = (date: Date, size: Int, filePath: String)
    
    public init(diskSetting: DiskSetting, fileManager: FileManager = FileManager.default, asyncQueue: DispatchQueue = .global(qos: .utility)) {
        self.diskSetting = diskSetting
        self.fileManager = fileManager
        self.asyncQueue = asyncQueue
    }
    
    public func cleanup() throws {
        guard let paths = paths() else { return }
        for name in paths {
            guard let filePath = locationPath()?.appendingPathComponent(name).relativePath else { continue }
            guard let date = try? fileManager.attributesOfItem(atPath: filePath)[FileAttributeKey.creationDate] as? Date else { continue }
            if Date().timeIntervalSince(date) > diskSetting.storeDuration.timeInterval() {
                try fileManager.removeItem(atPath: filePath)
            }
        }
        
        if size() > diskSetting.maxSize.byte() {
            guard let leftPaths = self.paths() else { return }
            var sorted: [File] = []
            for name in leftPaths {
                guard let filePath = locationPath()?.appendingPathComponent(name).relativePath else { continue }
                if let date = try? fileManager.attributesOfItem(atPath: filePath)[FileAttributeKey.creationDate] as? Date,
                    let size = try? fileManager.attributesOfItem(atPath: filePath)[FileAttributeKey.size] as? NSNumber {
                    sorted.append((date, size.intValue, filePath))
                }
            }
            sorted.sort { (lhs, rhs) -> Bool in
                return lhs.date.timeIntervalSince1970 < rhs.date.timeIntervalSince1970
            }
            
            if let oldest = sorted.first {
                try fileManager.removeItem(atPath: oldest.filePath)
                try cleanup()
            }
        }
    }
    
    public func deleteAll() throws {
        guard let path = locationPath() else { return }
        try fileManager.removeItem(atPath: path.relativePath)
    }
    
    public func delete(name: String) throws {
        try cleanup()
        guard let path = locationPath() else { return }
        try fileManager.removeItem(atPath: path.appendingPathComponent(name).relativePath)
    }
    
    public func load<T: Cachable>(name: String, type: T.Type) throws -> T? {
        try cleanup()
        guard let path = locationPath() else { return nil }
        let data = fileManager.contents(atPath: path.appendingPathComponent(name).relativePath)
        return T(name: name, data: data)
    }
    
    public func persist(cacheable: Cachable) throws {
        guard let path = locationPath() else { return }
        try fileManager.createDirectory(at: path, withIntermediateDirectories: true)
        fileManager.createFile(atPath: path.appendingPathComponent(cacheable.name).relativePath, contents: cacheable.data)
        try cleanup()
    }
    
    public func persist(cachables: [Cachable]) throws {
        guard let path = locationPath() else { return }
        try fileManager.createDirectory(at: path, withIntermediateDirectories: true)
        for data in cachables {
            fileManager.createFile(atPath: path.appendingPathComponent(data.name).relativePath, contents: data.data)
        }
        try cleanup()
    }
    
    // MARK: Private 
    
    private func paths() -> [String]? {
        guard let path = locationPath() else { return nil }
        return fileManager.subpaths(atPath: path.relativePath)
    }
    
    private func size() -> Int {
        guard let paths = paths() else { return 0 }
        var size = 0
        for name in paths {
            guard let filePath = locationPath()?.appendingPathComponent(name).relativePath else { continue }
            if let fileSize = try? fileManager.attributesOfItem(atPath: filePath)[FileAttributeKey.size] as? NSNumber {
                size += fileSize.intValue
            }
        }
        return size
    }
    
    private func locationPath() -> URL? {
        switch diskSetting.location {
        case .cache:
            return fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(diskSetting.identifier)
        case .secureContainer(let securityApplicationGroupIdentifier):
            return fileManager.containerURL(forSecurityApplicationGroupIdentifier: securityApplicationGroupIdentifier)?.appendingPathComponent(diskSetting.identifier)
        }
    }
}
