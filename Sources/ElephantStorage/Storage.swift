//
//  Storage.swift
//  
//
//  Created by Andreas Hausberger on 16.05.21.
//

import CoreData
import Combine

public class ElephantStorage<T: NSManagedObject> {
    
    private var context: NSManagedObjectContext
    
    /// Public init.
    /// - Parameter context: Valid NSManagedObjectContext that can be used to save objects.
    /// - Note: You may want to extend Storage to incorporate a parameter-less convenience init with an existing context.
    public init (context: NSManagedObjectContext) {
        self.context = context
    }
    
    /// Creates a publisher for a new Object.
    /// - Returns: AnyPublisher with a new Object. No failure
    public func createNewObject() -> AnyPublisher<T, Never> {
        return Just(T(context: self.context))
            .eraseToAnyPublisher()
    }
    
    /// Saves a given object in the context.
    /// - Parameters:
    ///   - object: Object to save.
    ///   - isUpdate: Determines whether object already exists in context (== update), or is new (!= update).
    /// - Returns: AnyPublisher with saved object.
    public func saveObject(_ object: T, isUpdate: Bool) -> AnyPublisher<T, StorageError> {
        return Future { promise in
            do {
                if isUpdate {
                    try self.context.save()
                    promise(.success(object))
                }
                else {
                    self.context.insert(object)
                    try self.context.save()
                    promise(.success(object))
                }
            }
            catch {
                promise(.failure(.WriteError))
            }
        }.eraseToAnyPublisher()
    }
    
    public func deleteObject(_ object: T) -> AnyPublisher<T, StorageError> {
        return Future { promise in
            self.context.delete(object)
            do {
                try self.context.save()
                promise(.success(object))
            }
            catch {
                promise(.failure(.DeleteError))
            }
        }.eraseToAnyPublisher()
    }
    
    /// Returns all objects with the given Entity Name.
    /// - Parameter entityName: Entity Name (see database, Data Model).
    /// - Returns: AnyPublisher with Array of Objects. NotFoundError if no objects were found in Database, ReadError if the operation could not be completed.
    public func getAllObjects(entityName: String) -> AnyPublisher<[T], StorageError> {
        return Future { promise in
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            do {
                if let results = try self.context.fetch(request) as? [T] {
                    promise(.success(results))
                }
                else {
                    promise(.failure(.NotFoundError))
                }
            }
            catch {
                promise(.failure(.ReadError))
            }
        }.eraseToAnyPublisher()
    }
    
    /// Returns all objects with a given NSPredicate
    /// - Parameters:
    ///   - predicate: `NSPredicate` describing the rules for object selection
    ///   - entityName: `String`Name of the Entity
    /// - Returns: `AnyPublisher` with array of Objects. NotFoundError if no objects were found in Database, ReadError if the operation could not be completed.
    public func getObjects(with predicate: NSPredicate, entityName: String) -> AnyPublisher<[T], StorageError> {
        publish { promise in
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            request.predicate = predicate
            
            do {
                if let results = try self.context.fetch(request) as? [T] {
                    promise(.success(results))
                }
                else {
                    promise(.failure(.NotFoundError))
                }
            }
            catch {
                promise(.failure(.ReadError))
            }
        }
    }
        
    private func publish<R>(_ resolution: @escaping (Future<R, StorageError>.Promise) -> ())->AnyPublisher<R, StorageError> {
        Future(resolution).eraseToAnyPublisher()
    }
    
}
