//
//  File.swift
//  
//
//  Created by Gil Biren on 28/01/2020.
//

import Foundation

class CacheStore {
    private let diskSetting: DiskSetting
    
    public init(diskSetting: DiskSetting) {
        self.diskSetting = diskSetting
    }
    
    public func cleanup() throws {
        guard let paths = paths() else { return }
        for name in paths {
            guard let filePath = locationPath()?.appendingPathComponent(name).relativePath else { continue }
            guard let date = try? FileManager.default.attributesOfItem(atPath: filePath)[FileAttributeKey.creationDate] as? Date else { continue }
            if Date().timeIntervalSince(date) > diskSetting.storeDuration.timeInterval() {
                try FileManager.default.removeItem(atPath: filePath)
            }
        }
        
        if size() > diskSetting.maxSize.byte() {
            guard let leftPaths = self.paths() else { return }
            var sorted: [(Date, Int, String)] = []
            for name in leftPaths {
                guard let filePath = locationPath()?.appendingPathComponent(name).relativePath else { continue }
                if let date = try? FileManager.default.attributesOfItem(atPath: filePath)[FileAttributeKey.creationDate] as? Date,
                    let size = try? FileManager.default.attributesOfItem(atPath: filePath)[FileAttributeKey.size] as? NSNumber {
                    sorted.append((date, size.intValue, filePath))
                }
            }
            sorted.sort { (lhs, rhs) -> Bool in
                return lhs.0.timeIntervalSince1970 < rhs.0.timeIntervalSince1970
            }
            
            if let oldest = sorted.first {
                try FileManager.default.removeItem(atPath: oldest.2)
                try cleanup()
            }
        }
    }
    
    public func deleteAll() throws {
        guard let path = locationPath() else { return }
        try FileManager.default.removeItem(atPath: path.relativePath)
    }
    
    public func delete(name: String) throws {
        try cleanup()
        guard let path = locationPath() else { return }
        try FileManager.default.removeItem(atPath: path.appendingPathComponent(name).relativePath)
    }
    
    public func load(name: String) throws -> Data? {
        try cleanup()
        guard let path = locationPath() else { return nil }
        return FileManager.default.contents(atPath: path.appendingPathComponent(name).relativePath)
    }
    
    public func persist(data: Data, name: String) throws {
        guard let path = locationPath() else { return }
        try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: path.appendingPathComponent(name).relativePath, contents: data)
        try cleanup()
    }
    
    // MARK: Private 
    
    private func paths() -> [String]? {
        guard let path = locationPath() else { return nil }
        return FileManager.default.subpaths(atPath: path.relativePath)
    }
    
    private func size() -> Int {
        guard let paths = paths() else { return 0 }
        var size = 0
        for name in paths {
            guard let filePath = locationPath()?.appendingPathComponent(name).relativePath else { continue }
            if let fileSize = try? FileManager.default.attributesOfItem(atPath: filePath)[FileAttributeKey.size] as? NSNumber {
                size += fileSize.intValue
            }
        }
        return size
    }
    
    private func locationPath() -> URL? {
        switch diskSetting.location {
        case .cache:
            return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(diskSetting.identifier)
        case .secureContainer(let securityApplicationGroupIdentifier):
            return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: securityApplicationGroupIdentifier)?.appendingPathComponent(diskSetting.identifier)
        }
    }
}
