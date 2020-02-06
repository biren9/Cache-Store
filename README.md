# Cache-Store [![Build Status](https://travis-ci.org/biren9/Cache-Store.svg?branch=master)](https://travis-ci.org/biren9/Cache-Store) ![Swift Version](https://img.shields.io/badge/Swift-5.1-blue)

## Description
Cache-Store is a lightweight caching package to cache any data object locally. You can create multiple so called rate disks, which have a maximum lifetime and size. If this is exceeded, the oldest files are automatically deleted.

## Usage

### DiskSetting
Location: specifies the location of the file to be persisted.
Identifier: a string to identify the disk. **Importent:** The identifier of each DiskSetting has to be unique
StoreDuration: specifies the maximum lifetime of each file.
MaxSize: specifies the maximum size of the whole DiskSetting

```swift
import Cache

let disk = DiskSetting(location: .cache, identifier: "jsonAsync", storeDuration: .minutes(10), maxSize: .MB(5))
```

### Cachable
Cachable is a protocol.
```swift
public protocol Cachable {
    var name: String { get }
    var data: Data? { get }
    
    init(name: String, data: Data?)
}
```
Every cachable object can be saved. It is important that the information to be stored is all located in the Data property.
Currently, there are already models that comply with the protocol to transfer Data or UIImage / NSImage.

- [x] CacheData: Data
- [x] CacheImage: UIImage / NSImage

### CacheStore
The cache store has for every call a sync and an async api.
```swift
init(diskSetting: DiskSetting, fileManager: FileManager = FileManager.default, asyncQueue: DispatchQueue = .global(qos: .utility))
```
The following sync operations are available:
 - cleanup() throws
 - deleteAll() throws
 - delete(name: String) throws 
 - load<T: Cachable>(name: String, type: T.Type) throws -> T
 - persist(cachable: Cachable) throws
 - persist(cachables: [Cachable]) throws
 - info(name: String) throws -> FileInformation

The async api is identical. Each call has a completion parameter.
instead of these methods throwing an error, a Result<Cachable | Void | ..., Error> returns.

## Known Bugs
[  ] Under linux, files are written to disk together, which means that the creation date is identical. This means that there is no longer any conclusion as to which file has been there the longest and which will be deleted is not predictable.
