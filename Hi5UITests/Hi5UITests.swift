//
//  Hi5UITests.swift
//  Hi5UITests
//
//  Created by 李凯翔 on 2022/2/24.
//

import XCTest

class Hi5UITests: XCTestCase {

    var app:XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testUserInfoPageFunction(){
        
    }

}
