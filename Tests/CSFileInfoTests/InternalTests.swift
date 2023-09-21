//
//  InternalTests.swift
//
//
//  Created by Charles Srstka on 9/12/23.
//

@testable import CSFileInfo
import XCTest

class InternalTests: XCTestCase {
    func testHFSTypeCodeConversion() {
        XCTAssertEqual(String(hfsTypeCode: 0x61626364), "abcd")
        XCTAssertEqual("abcd".hfsTypeCode, 0x61626364)
        XCTAssertEqual("abcde".hfsTypeCode, 0x61626364)
        XCTAssertEqual("abc".hfsTypeCode, 0x61626320)
        XCTAssertEqual("a".hfsTypeCode, 0x61202020)
    }

    func testFSIDEquality() {
        XCTAssertEqual(fsid_t(val: (1, 2)), fsid_t(val: (1, 2)))
        XCTAssertNotEqual(fsid_t(val: (1, 2)), fsid_t(val: (2, 2)))
        XCTAssertNotEqual(fsid_t(val: (1, 2)), fsid_t(val: (1, 1)))
    }
}
