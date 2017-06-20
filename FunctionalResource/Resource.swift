//
//  Resource.swift
//  FunctionalResource
//
//  Created by Casey Persson on 6/19/17.
//  Copyright © 2017 Procore. All rights reserved.
//

import Foundation
import CoreData

enum PlaceholderError: Error {
    case something
}

enum Result<T> {
    case success(T)
    case failure(Error)
}

struct Resource {
    typealias DownloadedData = [String: AnyHashable]
    typealias Downloader = (_ completion: @escaping (Result<DownloadedData>) -> Void) -> Void
    typealias Importer = (DownloadedData) throws -> Void
    
    let download: Downloader
    let `import`: Importer
    
    func load() {
        self.download { result in
            switch(result) {
            case .success(let downloadedData):
                print("Download success, ready to import.")
                try! self.import(downloadedData)
            case .failure(let error):
                print("Download ERROR: \(error).")
            }
        }
    }
}

// MARK: Working with an immutable struct

struct Employee {
    let name: String
    let iq: Int
}

extension Employee {
    init(ir: Resource.DownloadedData) throws {
        guard let name = ir["name"] as? String else { throw PlaceholderError.something }
        guard let iq = ir["iq"] as? Int else { throw PlaceholderError.something }
        
        self.name = name
        self.iq = iq
    }
}

var theOnlyOne: Employee?

func employeeImport() -> Resource.Importer {
    return { data in
        let emp = try! Employee(ir: data)
        // I see we'd kind of like to return this... We *could* put it in an out-of-band location such as a global ;P
        theOnlyOne = emp
    }
}


// MARK: Working with a mutable struct or class

class Employee2 {
    var name: String?
    var iq: Int32?
}

extension Employee2 {
    // Note this member function is a Resource.Importer
    func `import`(ir: Resource.DownloadedData) throws {
        guard let name = ir["name"] as? String else { throw PlaceholderError.something }
        guard let iq = ir["iq"] as? Int else { throw PlaceholderError.something }
        
        self.name = name
        self.iq = Int32(iq)
    }
}

// MARK: Working with a CoreData Object

extension CDEmployee {
    // Note this member function is a Resource.Importer
    // Note, the exact same import code works whether applied on a CoreData object or Plain-old-data-object
    // TODO: Could take this a step further by using the same method in both cases. Might need to employ protocols or generics.
    func `import`(ir: Resource.DownloadedData) throws {
        guard let name = ir["name"] as? String else { throw PlaceholderError.something }
        guard let iq = ir["iq"] as? Int else { throw PlaceholderError.something }
        
        self.name = name
        self.iq = Int32(iq)
    }
}


protocol ManagedObject {
    func `import`(ir: Resource.DownloadedData) throws
}

extension CDEmployee: ManagedObject { }

extension ManagedObject where Self : CDEmployee {
    static func coreDataImporter(context: NSManagedObjectContext) -> Resource.Importer {
        return { ir in
            let newManagedObject = Self(context: context)
            context.performAndWait {
                do {
                    try newManagedObject.import(ir: ir)
                    try context.save()
                } catch {
                    context.rollback()
                }
            }
        }
    }
    
    private static func lookupDictionary(from managedObjects: [Self]) -> [String: Self] {
        return managedObjects.reduce([:]) { dict, managedObject in
            var dict = dict
            dict[managedObject.name!] = managedObject
            return dict
        }
    }

    /*
    static func findOrCreateImporter(in context: NSManagedObjectContext, scopedTo predicate: NSPredicate) -> Resource.Importer {
        return { ir in
            let fetchRequest = Self.fetchRequest()
            fetchRequest.predicate = predicate
            let localEntities = try context.fetch(fetchRequest)
            
            var lookup = lookupDictionary(from: localEntities)
            var remoteEntities = [Self]()
            
            //let importCache = try Self.preimport(ir, in: context)
            try ir.forEach { jsonHelper in
                let serverId: Int = try jsonHelper.value(forKey: Self.serverIdKey)
                let managedObject = lookup[serverId] ?? Self(entity: NSEntityDescription.entity(forEntityName: Self.entityName(), in: context)!, insertInto: context)
                
                try managedObject.from(jsonHelper, with: importCache)
                associateBlock?(managedObject)
                remoteEntities.append(managedObject)
                
                // Remove this entry from lookup so that we know what to delete at the end
                lookup[serverId] = nil
            }
            
            // Now delete leftovers from db
            if delete {
                lookup.forEach { context.delete($0.1) }
            }
            
            let newManagedObject = Self(context: context)
            context.performAndWait {
                do {
                    try newManagedObject.import(ir: ir)
                    try context.save()
                } catch {
                    context.rollback()
                }
            }
        }
    }
    */
}

