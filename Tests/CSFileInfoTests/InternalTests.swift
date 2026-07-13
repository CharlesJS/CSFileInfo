//
//  InternalTests.swift
//
//
//  Created by Charles Srstka on 9/12/23.
//

@testable import CSFileInfo
import Testing

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

@Suite
struct InternalTests {
    @Test
    func testHFSTypeCodeConversion() {
        #expect(String(hfsTypeCode: 0x61626364) == "abcd")
        #expect("abcd".hfsTypeCode == 0x61626364)
        #expect("abcde".hfsTypeCode == 0x61626364)
        #expect("abc".hfsTypeCode == 0x61626320)
        #expect("a".hfsTypeCode == 0x61202020)
    }

#if canImport(Darwin)
    @Test
    func testFSIDEquality() {
        #expect(fsidsEqual(fsid_t(val: (1, 2)), fsid_t(val: (1, 2))))
        #expect(!fsidsEqual(fsid_t(val: (1, 2)), fsid_t(val: (2, 2))))
        #expect(!fsidsEqual(fsid_t(val: (1, 2)), fsid_t(val: (1, 1))))
    }
#else
    @Test
    func testFSIDEquality() {
        #expect(fsidsEqual(fsid_t(__val: (1, 2)), fsid_t(__val: (1, 2))))
        #expect(!fsidsEqual(fsid_t(__val: (1, 2)), fsid_t(__val: (2, 2))))
        #expect(!fsidsEqual(fsid_t(__val: (1, 2)), fsid_t(__val: (1, 1))))
    }
#endif
}
