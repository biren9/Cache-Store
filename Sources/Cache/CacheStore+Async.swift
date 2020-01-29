//
//  File.swift
//  
//
//  Created by fluidmobile on 29/01/2020.
//

import Foundation

extension CacheStore {
    
    typealias Completion = (Result<Void, Error>) -> Void
    
    public func cleanup(completion: @escaping Completion) {
        dispatch { [weak self] in
            guard let self = self else { return }
            do {
                try self.cleanup()
                completion(.success)
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func deleteAll(completion: @escaping Completion) {
        dispatch { [weak self] in
            guard let self = self else { return }
            do {
                try self.deleteAll()
                completion(.success)
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func delete(name: String, completion: @escaping Completion) {
        dispatch { [weak self] in
            guard let self = self else { return }
            do {
                try self.delete(name: name)
                completion(.success)
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func load<T: Cachable>(name: String, type: T.Type, completion: @escaping (Result<T?, Error>) -> Void) {
        dispatch { [weak self] in
            guard let self = self else { return }
            do {
                let data = try self.load(name: name, type: type)
                completion(.success(data))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func persist(cachable: Cachable, completion: @escaping Completion) {
        dispatch { [weak self] in
            guard let self = self else { return }
            do {
                try self.persist(cachable: cachable)
                completion(.success)
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func persist(cachables: [Cachable], completion: @escaping Completion) {
        dispatch { [weak self] in
            guard let self = self else { return }
            do {
                try self.persist(cachables: cachables)
                completion(.success)
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func dispatch(_ block: @escaping () -> Void) {
        asyncQueue.async {
            block()
        }
    }
}
