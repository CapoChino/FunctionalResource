//
//  FunctionalResourceTests.swift
//  FunctionalResourceTests
//
//  Created by Casey Persson on 6/19/17.
//  Copyright © 2017 Procore. All rights reserved.
//

import XCTest
import CoreData
@testable import FunctionalResource

// MARK: Mocks


class FunctionalResourceTests: XCTestCase {
    
    var mainMoc: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        mainMoc = setUpInMemoryManagedObjectContext()
    }
    
    func setUpInMemoryManagedObjectContext() -> NSManagedObjectContext {
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
        
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        } catch {
            print("Adding in-memory persistent store failed")
        }
        
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        return managedObjectContext
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSimpleDownloadError() {
        let downloadCalled = self.expectation(description: "download called")
        let simpleResourceError = Resource(
            download: { completion in
                completion(Result.failure(PlaceholderError.something))
                downloadCalled.fulfill()
        },
            import: { downloadedData in
                XCTFail("This should never happen!")
        }
        )
        simpleResourceError.load()
        self.waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testSimpleDownloadSuccess() {
        let theData = ["answer": "fourty-two"]
        let downloadCalled = self.expectation(description: "download called")
        let importCalled = self.expectation(description: "import called")
        let simpleResourceError = Resource(
            download: { completion in
                completion(Result.success(theData))
                downloadCalled.fulfill()
        },
            import: { downloadedData in
                XCTAssertEqual(downloadedData, theData)
                importCalled.fulfill()
        }
        )
        simpleResourceError.load()
        self.waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testSimpleImport() {
        let data: Resource.DownloadedData = ["iq" : 319, "name" : "Bradley"]
        let bradley = try! Employee(ir: data)
        XCTAssertEqual(bradley.name, "Bradley")
        XCTAssertEqual(bradley.iq, 319)
    }
    
    func testOutOfBand() {
        let data: Resource.DownloadedData = ["iq" : 319, "name" : "Bradley"]
        try! employeeImport()(data)
        let bradley = theOnlyOne!
        XCTAssertEqual(bradley.name, "Bradley")
        XCTAssertEqual(bradley.iq, 319)
    }
    
    func testMutableImport() {
        let testData: Resource.DownloadedData = ["iq" : 319, "name" : "Bradley"]
        let employee: Employee2 = Employee2()
        let simpleResourceError = Resource(
            download: { completion in
                completion(Result.success(testData))
        },
            // Wow, cool, the member function is a Resource.Importer
            import: employee.import
        )
        simpleResourceError.load()
        XCTAssertEqual(employee.name, "Bradley")
        XCTAssertEqual(employee.iq, 319)
    }
    
    func testCoreDataImport() {
        let testData: Resource.DownloadedData = ["iq" : 319, "name" : "Bradley"]
        
        let employee = CDEmployee.init(entity: CDEmployee.entity(), insertInto: mainMoc)
        let simpleResourceError = Resource(
            download: { completion in
                completion(Result.success(testData))
        },
            // Wow, cool, the member function is a Resource.Importer
            import: employee.import
        )
        simpleResourceError.load()
        XCTAssertEqual(employee.name, "Bradley")
        XCTAssertEqual(employee.iq, 319)
    }
    
    // Note the above 2 aren't super-useful because they only import directly onto a given object. Let's make an importer that creates the object to import to.
    
    
}
