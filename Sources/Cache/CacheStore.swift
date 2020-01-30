//
//  File.swift
//  
//
//  Created by Gil Biren on 28/01/2020.
//

import Foundation

public class CacheStore {
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
        let paths = try self.paths() ?? []
        for name in paths {
            guard let filePath = locationPath()?.appendingPathComponent(name).relativePath else {
                throw CacheError.invalidFilePath
            }
            guard let date = try fileManager.attributesOfItem(atPath: filePath)[FileAttributeKey.creationDate] as? Date else { continue }
            if Date().timeIntervalSince(date) > diskSetting.storeDuration.timeInterval() {
                try fileManager.removeItem(atPath: filePath)
            }
        }
        
        if size() > diskSetting.maxSize.byte() {
            let leftPaths = try self.paths() ?? []
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
        guard let path = locationPath() else { throw CacheError.invalidFilePath }
        try fileManager.removeItem(atPath: path.relativePath)
    }
    
    public func delete(name: String) throws {
        try cleanup()
        guard let path = locationPath() else { throw CacheError.invalidFilePath }
        try fileManager.removeItem(atPath: path.appendingPathComponent(name).relativePath)
    }
    
    public func load<T: Cachable>(name: String, type: T.Type) throws -> T {
        try cleanup()
        guard let path = locationPath() else { throw CacheError.invalidFilePath }
        let data = fileManager.contents(atPath: path.appendingPathComponent(name).relativePath)
        return T(name: name, data: data)
    }
    
    public func persist(cachable: Cachable) throws {
        try persistWithoutClean(cachable: cachable)
        try cleanup()
    }
    
    public func persist(cachables: [Cachable]) throws {
        for cachable in cachables {
            try persistWithoutClean(cachable: cachable)
        }
        try cleanup()
    }
    
    public func info(name: String) throws -> FileInformation {
        try cleanup()
        guard let path = locationPath()?.appendingPathComponent(name).relativePath else { throw CacheError.invalidFilePath }
        let infos = try fileManager.attributesOfItem(atPath: path)
        let size = (infos[FileAttributeKey.size] as? NSNumber)?.intValue ?? -1
        let creationDate = (infos[FileAttributeKey.creationDate] as? Date) ?? Date(timeIntervalSince1970: 0)
        let modifiedDate = (infos[FileAttributeKey.modificationDate] as? Date) ?? Date(timeIntervalSince1970: 0)
        return FileInformation(size: size,
                               creationDate: creationDate,
                               modifiedDate: modifiedDate)
    }
    
    // MARK: Private 
    
    private func paths() throws -> [String]? {
        guard let path = locationPath() else { throw CacheError.invalidFilePath }
        return fileManager.subpaths(atPath: path.relativePath)
    }
    
    private func size() -> Int {
        guard let paths = try? paths() else { return 0 }
        var size = 0
        for name in paths {
            guard let filePath = locationPath()?.appendingPathComponent(name).relativePath else { continue }
            if let fileSize = try? fileManager.attributesOfItem(atPath: filePath)[FileAttributeKey.size] as? NSNumber {
                size += fileSize.intValue
            }
        }
        return size
    }
    
    private func persistWithoutClean(cachable: Cachable) throws {
        if cachable.data?.count ?? 0 > diskSetting.maxSize.byte() {
            throw CacheError.fileSizeLargerThanAllowed
        }
        
        guard let path = locationPath() else { throw CacheError.invalidFilePath }
        try fileManager.createDirectory(at: path, withIntermediateDirectories: true)
        fileManager.createFile(atPath: path.appendingPathComponent(cachable.name).relativePath, contents: cachable.data, attributes: [FileAttributeKey.creationDate: Date()])
    }
    
    private func locationPath() -> URL? {
        switch diskSetting.location {
        case .cache:
            return fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(diskSetting.identifier)
        case .custom(let url):
            return url
            
        #if !os(Linux)
        case .secureContainer(let securityApplicationGroupIdentifier):
            return fileManager.containerURL(forSecurityApplicationGroupIdentifier: securityApplicationGroupIdentifier)?.appendingPathComponent(diskSetting.identifier)
        #endif
        }
    }
}
