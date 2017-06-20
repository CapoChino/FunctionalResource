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
        let simpleResourceError = Resource(
            download: { completion in
                completion(Result.failure(PlaceholderError.something))
        },
            import: { downloadedData in
                XCTFail("This should never happen!")
        }
        )
        simpleResourceError.load()
    }
    
    func testSimpleDownloadSuccess() {
        let theData = ["answer": "fourty-two"]
        let exp = self.expectation(description: "import called")
        let simpleResourceError = Resource(
            download: { completion in
                completion(Result.success(theData))
        },
            import: { downloadedData in
                XCTAssertEqual(downloadedData, theData)
                exp.fulfill()
        }
        )
        simpleResourceError.load()
        self.waitForExpectations(timeout: 2, handler: nil)
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
