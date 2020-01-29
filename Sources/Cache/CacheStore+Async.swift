//
//  File.swift
//  
//
//  Created by fluidmobile on 29/01/2020.
//

import Foundation

extension CacheStore {
    
    typealias Completion = (Result<Void, Error>) -> Void
    typealias DataCompletion = (Result<Data?, Error>) -> Void
    
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
    
    public func load(name: String, completion: @escaping DataCompletion) {
        dispatch { [weak self] in
            guard let self = self else { return }
            do {
                let data = try self.load(name: name)
                completion(.success(data))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func persist(data: Cachable, completion: @escaping Completion) {
        dispatch { [weak self] in
            guard let self = self else { return }
            do {
                try self.persist(data: data)
                completion(.success)
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func persist(datas: [Cachable], completion: @escaping Completion) {
        dispatch { [weak self] in
            guard let self = self else { return }
            do {
                try self.persist(datas: datas)
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
