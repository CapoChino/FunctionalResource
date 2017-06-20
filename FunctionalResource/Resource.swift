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

// MARK: Mocks
class ProHttp {
    static func get(url: URL, completion: @escaping (Result<[String: AnyHashable]>) -> Void) {
        let data: [String: AnyHashable] = ["foo": 1, "name": "bradley"]
        let result = Result.success(data)
        print("Downloading: \(result)")
        completion(result)
    }
}

// MARK: Simple

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

//func importSimpleObject(simpleObject: SimpleObject) -> Resource.Importer {
//    return { ir in
//        guard let name = ir["name"] as? String else { throw PlaceholderError.something }
//        guard let foo = ir["foo"] as? Int else { throw PlaceholderError.something }
//
//        simpleObject.name = name
//        simpleObject.foo = foo
//    }
//}


// MARK: CoreData

class Punch: NSManagedObject {
    @NSManaged var name: String
    @NSManaged var foo: Int
}

func importPunch(_ punch: Punch) -> Resource.Importer {
    return { ir in
        guard let name = ir["name"] as? String else { throw PlaceholderError.something }
        guard let foo = ir["foo"] as? Int else { throw PlaceholderError.something }
        
        punch.name = name
        punch.foo = foo
        print("Imported: \(punch)")
    }
}

extension Punch {
    
    func `import`() -> Resource.Importer {
        return importPunch(self)
    }
    
    static func all() -> Resource {
        let download: Resource.Downloader = { completion in
            print("Attempting download.")
            ProHttp.get(url: URL(fileURLWithPath: "")) { proHttpData in
                let parsed = proHttpData as Result<Resource.DownloadedData>
                completion(parsed)
            }
        }
        
        let punchImporter: Resource.Importer = {
            let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            print("\(Punch.entity())")
            let punch = Punch.init(entity: Punch.entity(), insertInto: context)
            
            let importer: Resource.Importer = { ir in
                context.performAndWait {
                    do {
                        try punch.import()(ir)
                        try context.save()
                    } catch {
                        context.rollback()
                    }
                }
            }
            return importer
        }()
        
        return Resource(download: download, import: punchImporter)
    }
    
}




