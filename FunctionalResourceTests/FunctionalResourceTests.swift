//
//  FunctionalResourceTests.swift
//  FunctionalResourceTests
//
//  Created by Casey Persson on 6/19/17.
//  Copyright © 2017 Procore. All rights reserved.
//

import XCTest
@testable import FunctionalResource

// MARK: Mocks


class FunctionalResourceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
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
    
    
//    func testExample() {
//        let r = Punch.all()
//        //let r = simpleResourceError
//        //let r = simpleResourceSuccess
//        r.download { result in
//            switch(result) {
//            case .success(let downloadedData):
//                print("Download success, ready to import.")
//                try! r.import(downloadedData)
//            case .failure(let error):
//                print("Download ERROR: \(error).")
//            }
//        }
//    }
}
