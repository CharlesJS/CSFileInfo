//
//  ExtendedAttributeTests.swift
//
//
//  Created by Charles Srstka on 11/5/23.
//

import CSErrors
@testable import CSFileInfo
import System
import XCTest

final class ExtendedAttributeTests: XCTestCase {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

    lazy var fileWithNoExtendedAttributes = { self.tempDir.appending(path: UUID().uuidString) }()
    lazy var fileWithOneExtendedAttribute = { self.tempDir.appending(path: UUID().uuidString) }()
    lazy var fileWithMultipleExtendedAttributes = { self.tempDir.appending(path: UUID().uuidString) }()

    lazy var dirWithNoExtendedAttributes = { self.tempDir.appending(path: UUID().uuidString) }()
    lazy var dirWithOneExtendedAttribute = { self.tempDir.appending(path: UUID().uuidString) }()
    lazy var dirWithMultipleExtendedAttributes = { self.tempDir.appending(path: UUID().uuidString) }()

    lazy var linkWithNoExtendedAttributes = { self.tempDir.appending(path: UUID().uuidString) }()
    lazy var linkWithOneExtendedAttribute = { self.tempDir.appending(path: UUID().uuidString) }()
    lazy var linkWithMultipleExtendedAttributes = { self.tempDir.appending(path: UUID().uuidString) }()

    override func setUp() {
        try! FileManager.default.createDirectory(at: self.tempDir, withIntermediateDirectories: true)

        try! Data().write(to: self.fileWithNoExtendedAttributes)

        try! Data().write(to: self.fileWithOneExtendedAttribute)
        try! callPOSIXFunction(expect: .zero) { setxattr(self.fileWithOneExtendedAttribute.path, "foo", "lish", 4, 0, 0) }

        try! Data().write(to: self.fileWithMultipleExtendedAttributes)
        try! callPOSIXFunction(expect: .zero) {
            setxattr(self.fileWithMultipleExtendedAttributes.path, "bar", "barian", 6, 0, 0)
        }
        try! callPOSIXFunction(expect: .zero) {
            setxattr(self.fileWithMultipleExtendedAttributes.path, "baz", "zerk", 4, 0, 0)
        }

        try! FileManager.default.createDirectory(at: self.dirWithNoExtendedAttributes, withIntermediateDirectories: true)

        try! FileManager.default.createDirectory(at: self.dirWithOneExtendedAttribute, withIntermediateDirectories: true)
        try! callPOSIXFunction(expect: .zero) { setxattr(self.dirWithOneExtendedAttribute.path, "foo", "lish", 4, 0, 0) }

        try! FileManager.default.createDirectory(at: self.dirWithMultipleExtendedAttributes, withIntermediateDirectories: true)
        try! callPOSIXFunction(expect: .zero) {
            setxattr(self.dirWithMultipleExtendedAttributes.path, "bar", "barian", 6, 0, 0)
        }
        try! callPOSIXFunction(expect: .zero) {
            setxattr(self.dirWithMultipleExtendedAttributes.path, "baz", "zerk", 4, 0, 0)
        }

        try! FileManager.default.createSymbolicLink(
            at: self.linkWithNoExtendedAttributes,
            withDestinationURL: self.fileWithMultipleExtendedAttributes
        )

        try! FileManager.default.createSymbolicLink(
            at: self.linkWithOneExtendedAttribute,
            withDestinationURL: self.fileWithNoExtendedAttributes
        )

        let linkWithOneXattrFd = open(linkWithOneExtendedAttribute.path, O_RDWR | O_SYMLINK)
        defer { close(linkWithOneXattrFd) }
        try! callPOSIXFunction(expect: .zero) {
            fsetxattr(linkWithOneXattrFd, "foo", "lish", 4, 0, 0)
        }

        try! FileManager.default.createSymbolicLink(
            at: self.linkWithMultipleExtendedAttributes,
            withDestinationURL: self.dirWithNoExtendedAttributes
        )

        let linkWithMultipleXattrsFd = open(linkWithMultipleExtendedAttributes.path, O_RDWR | O_SYMLINK)
        defer { close(linkWithMultipleXattrsFd) }
        try! callPOSIXFunction(expect: .zero) {
            fsetxattr(linkWithMultipleXattrsFd, "bar", "barian", 6, 0, 0)
        }
        try! callPOSIXFunction(expect: .zero) {
            fsetxattr(linkWithMultipleXattrsFd, "baz", "zerk", 4, 0, 0)
        }
    }

    override func tearDown() async throws {
        try FileManager.default.removeItem(at: self.tempDir)
    }

    func testAll() throws {
        for version in [10, 11, 12, 13] {
            try emulateOSVersion(version) {
                try self.testListExtendedAttributes()
                try self.testReadExtendedAttributes()
                try self.testWriteExtendedAttributes()
                try self.testWriteExtendedAttributesToSymlink()
                try self.testRemoveExtendedAttributes()
                try self.testRemoveExtendedAttributesFromLink()
            }
        }
    }

    private func makeXattr(key: String, value: String) -> ExtendedAttribute {
        ExtendedAttribute(key: key, data: value.utf8)
    }

    private func assertXattrs(_ url: URL, _ dict: [String : String], options: ExtendedAttribute.ReadOptions = []) {
        let xattrs = dict.map { self.makeXattr(key: $0.key, value: $0.value) }

#if Foundation
        XCTAssertEqual(try Set(ExtendedAttribute.list(at: url, options: options)), Set(xattrs))
#endif
        XCTAssertEqual(try Set(ExtendedAttribute.list(at: FilePath(url.path), options: options)), Set(xattrs))
        XCTAssertEqual(try Set(ExtendedAttribute.list(atPath: url.path, options: options)), Set(xattrs))
    }

    func testListExtendedAttributes() throws {
        func assertListEqual(_ url: URL, _ list: [String : String], options: ExtendedAttribute.ReadOptions = []) {
            let attrs = Set(list.map { self.makeXattr(key: $0.key, value: $0.value) })

#if Foundation
            XCTAssertEqual(try Set(ExtendedAttribute.list(at: url, options: options)), attrs)
#endif
            XCTAssertEqual(try Set(ExtendedAttribute.list(at: FilePath(url.path), options: options)), attrs)
            XCTAssertEqual(try Set(ExtendedAttribute.list(atPath: url.path, options: options)), attrs)

            let fdOptions: FileDescriptor.OpenOptions = options.contains(.noTraverseLink) ? .symlink : []
            let fd = try! FileDescriptor.open(url.path, .readOnly, options: fdOptions)
            defer { _ = try? fd.close() }

            XCTAssertEqual(try Set(ExtendedAttribute.list(at: fd, options: options)), attrs)
            XCTAssertEqual(try Set(ExtendedAttribute.list(atFileDescriptor: fd.rawValue, options: options)), attrs)
        }

        let nonexistentFile = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
#if Foundation
        XCTAssertThrowsError(try ExtendedAttribute.list(at: nonexistentFile)) { XCTAssertTrue($0.isFileNotFoundError) }
#endif
        XCTAssertThrowsError(try ExtendedAttribute.list(at: FilePath(nonexistentFile.path))) {
            XCTAssertTrue($0.isFileNotFoundError)
        }
        XCTAssertThrowsError(try ExtendedAttribute.list(atPath: nonexistentFile.path)) {
            XCTAssertTrue($0.isFileNotFoundError)
        }
        assertListEqual(self.fileWithNoExtendedAttributes, [:])
        assertListEqual(self.fileWithOneExtendedAttribute, ["foo" : "lish"])
        assertListEqual(self.fileWithMultipleExtendedAttributes, ["bar" : "barian", "baz" : "zerk"])

        assertListEqual(self.dirWithNoExtendedAttributes, [:])
        assertListEqual(self.dirWithOneExtendedAttribute, ["foo" : "lish"])
        assertListEqual(self.dirWithMultipleExtendedAttributes, ["bar" : "barian", "baz" : "zerk"])

        assertListEqual(self.linkWithNoExtendedAttributes, ["bar" : "barian", "baz" : "zerk"], options: [])
        assertListEqual(self.linkWithOneExtendedAttribute, [:], options: [])
        assertListEqual(self.linkWithMultipleExtendedAttributes, [:], options: [])

        assertListEqual(self.linkWithNoExtendedAttributes, [:], options: .noTraverseLink)
        assertListEqual(self.linkWithOneExtendedAttribute, ["foo" : "lish"], options: .noTraverseLink)
        assertListEqual(
            self.linkWithMultipleExtendedAttributes,
            ["bar" : "barian", "baz" : "zerk"],
            options: .noTraverseLink
        )
    }

    func testReadExtendedAttributes() throws {
        func assertGetAttribute(url: URL, key: String, expectedAttribute: String, traverseLink: Bool = false) throws {
            let options: ExtendedAttribute.ReadOptions = traverseLink ? [] : [.noTraverseLink]

#if Foundation
            XCTAssertEqual(
                try String(decoding: ExtendedAttribute(at: url, key: key, options: options).data, as: UTF8.self),
                expectedAttribute
            )
#endif

            XCTAssertEqual(
                try String(
                    decoding: ExtendedAttribute(at: FilePath(url.path), key: key, options: options).data,
                    as: UTF8.self
                ),
                expectedAttribute
            )

            XCTAssertEqual(
                try String(decoding: ExtendedAttribute(atPath: url.path, key: key, options: options).data, as: UTF8.self),
                expectedAttribute
            )

            let openOptions: FileDescriptor.OpenOptions = options.contains(.noTraverseLink) ? .symlink : []
            let fd = try FileDescriptor.open(FilePath(url.path), .readOnly, options: openOptions)
            defer { _ = try? fd.close() }

            let fdOptions = options.subtracting(.noTraverseLink)

            XCTAssertEqual(
                try String(
                    decoding: ExtendedAttribute(at: fd, key: key, options: fdOptions).data,
                    as: UTF8.self
                ),
                expectedAttribute
            )

            XCTAssertEqual(
                try String(
                    decoding: ExtendedAttribute(atFileDescriptor: fd.rawValue, key: key, options: fdOptions).data,
                    as: UTF8.self
                ),
                expectedAttribute
            )
        }

        func assertThrowsError<E: Error & Equatable>(url: URL, key: String, error: E, traverseLink: Bool = false) {
            let options: ExtendedAttribute.ReadOptions = traverseLink ? [] : [.noTraverseLink]

#if Foundation
            XCTAssertThrowsError(try ExtendedAttribute(at: url, key: key, options: options)) {
                XCTAssertEqual(($0 as NSError).domain, (error as NSError).domain)
                XCTAssertEqual(($0 as NSError).code, (error as NSError).code)
            }
#endif

            XCTAssertThrowsError(try ExtendedAttribute(at: FilePath(url.path), key: key, options: options)) {
                XCTAssertEqual(($0 as NSError).domain, (error as NSError).domain)
                XCTAssertEqual(($0 as NSError).code, (error as NSError).code)
            }

            XCTAssertThrowsError(try ExtendedAttribute(atPath: url.path, key: key, options: options)) {
                XCTAssertEqual(($0 as NSError).domain, (error as NSError).domain)
                XCTAssertEqual(($0 as NSError).code, (error as NSError).code)
            }
        }

        let nonexistentFile = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
#if Foundation
        assertThrowsError(url: nonexistentFile, key: "foo", error: CocoaError(.fileReadNoSuchFile))
#else
        assertThrowsError(url: nonexistentFile, key: "foo", error: Errno.noSuchFileOrDirectory)
#endif

        assertThrowsError(url: self.fileWithNoExtendedAttributes, key: "foo", error: Errno.attributeNotFound)

        try assertGetAttribute(url: self.fileWithOneExtendedAttribute, key: "foo", expectedAttribute: "lish")
        assertThrowsError(url: self.fileWithOneExtendedAttribute, key: "bar", error: Errno.attributeNotFound)

        try assertGetAttribute(url: self.fileWithMultipleExtendedAttributes, key: "bar", expectedAttribute: "barian")
        try assertGetAttribute(url: self.fileWithMultipleExtendedAttributes, key: "baz", expectedAttribute: "zerk")
        assertThrowsError(url: self.fileWithMultipleExtendedAttributes, key: "foo", error: Errno.attributeNotFound)

        assertThrowsError(url: self.dirWithNoExtendedAttributes, key: "foo", error: Errno.attributeNotFound)

        try assertGetAttribute(url: self.dirWithOneExtendedAttribute, key: "foo", expectedAttribute: "lish")
        assertThrowsError(url: self.dirWithOneExtendedAttribute, key: "bar", error: Errno.attributeNotFound)

        try assertGetAttribute(url: self.dirWithMultipleExtendedAttributes, key: "bar", expectedAttribute: "barian")
        try assertGetAttribute(url: self.dirWithMultipleExtendedAttributes, key: "baz", expectedAttribute: "zerk")
        assertThrowsError(url: self.dirWithMultipleExtendedAttributes, key: "foo", error: Errno.attributeNotFound)

        assertThrowsError(
            url: self.linkWithNoExtendedAttributes,
            key: "foo",
            error: Errno.attributeNotFound,
            traverseLink: false
        )

        try assertGetAttribute(
            url: self.linkWithOneExtendedAttribute,
            key: "foo",
            expectedAttribute: "lish",
            traverseLink: false
        )
        assertThrowsError(
            url: self.linkWithOneExtendedAttribute,
            key: "bar",
            error: Errno.attributeNotFound,
            traverseLink: false
        )

        try assertGetAttribute(
            url: self.linkWithMultipleExtendedAttributes,
            key: "bar",
            expectedAttribute: "barian",
            traverseLink: false
        )
        try assertGetAttribute(
            url: self.linkWithMultipleExtendedAttributes,
            key: "baz",
            expectedAttribute: "zerk",
            traverseLink: false
        )
        assertThrowsError(
            url: self.linkWithMultipleExtendedAttributes,
            key: "foo",
            error: Errno.attributeNotFound,
            traverseLink: false
        )

        try assertGetAttribute(
            url: self.linkWithNoExtendedAttributes,
            key: "bar",
            expectedAttribute: "barian",
            traverseLink: true
        )
        try assertGetAttribute(
            url: self.linkWithNoExtendedAttributes,
            key: "baz",
            expectedAttribute: "zerk",
            traverseLink: true
        )
        assertThrowsError(
            url: self.linkWithNoExtendedAttributes,
            key: "foo",
            error: Errno.attributeNotFound,
            traverseLink: true
        )

        assertThrowsError(
            url: self.linkWithOneExtendedAttribute,
            key: "foo",
            error: Errno.attributeNotFound,
            traverseLink: true
        )
        assertThrowsError(
            url: self.linkWithOneExtendedAttribute,
            key: "bar",
            error: Errno.attributeNotFound,
            traverseLink: true
        )

        assertThrowsError(
            url: self.linkWithMultipleExtendedAttributes,
            key: "foo",
            error: Errno.attributeNotFound,
            traverseLink: true
        )
        assertThrowsError(
            url: self.linkWithMultipleExtendedAttributes,
            key: "bar",
            error: Errno.attributeNotFound,
            traverseLink: true
        )
    }

    func testWriteExtendedAttributes() throws {
        let testFile = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try Data().write(to: testFile)
        defer { _ = try? FileManager.default.removeItem(at: testFile) }

        self.assertXattrs(testFile, [:])

#if Foundation
        try self.makeXattr(key: "one", value: "uno").write(to: testFile)
#else
        try self.makeXattr(key: "one", value: "uno").write(to: FilePath(testFile.path))
#endif
        self.assertXattrs(testFile, ["one": "uno"])

        try self.makeXattr(key: "two", value: "dos").write(to: FilePath(testFile.path))
        self.assertXattrs(testFile, ["one": "uno", "two": "dos"])

        try self.makeXattr(key: "three", value: "tres").write(toPath: testFile.path)
        self.assertXattrs(testFile, ["one": "uno", "two": "dos", "three": "tres"])

#if Foundation
        try ExtendedAttribute.write(
            [
                .init(key: "four", data: "cuatro".data(using: .utf8)!),
                .init(key: "five", data: "cinco".data(using: .utf8)!)
            ],
            to: testFile
        )
#else
        try ExtendedAttribute.write(
            [
                .init(key: "four", data: "cuatro".data(using: .utf8)!),
                .init(key: "five", data: "cinco".data(using: .utf8)!)
            ],
            to: FilePath(testFile.path)
        )
#endif
        self.assertXattrs(testFile, ["one": "uno", "two": "dos", "three": "tres", "four": "cuatro", "five": "cinco"])

        try ExtendedAttribute.write(
            [
                .init(key: "six", data: "seis".data(using: .utf8)!),
                .init(key: "seven", data: "siete".data(using: .utf8)!)
            ],
            to: FilePath(testFile.path)
        )
        self.assertXattrs(
            testFile,
            ["one": "uno", "two": "dos", "three": "tres", "four": "cuatro", "five": "cinco", "six": "seis", "seven": "siete"]
        )
        
        try ExtendedAttribute.write(
            [
                .init(key: "eight", data: "ocho".data(using: .utf8)!),
                .init(key: "nine", data: "nueve".data(using: .utf8)!)
            ],
            toPath: testFile.path
        )
        self.assertXattrs(
            testFile,
            [
                "one": "uno", "two": "dos", "three": "tres", "four": "cuatro", "five": "cinco",
                "six": "seis", "seven": "siete", "eight": "ocho", "nine": "nueve"
            ]
        )

        let fd = try FileDescriptor.open(FilePath(testFile.path), .writeOnly)
        defer { _ = try? fd.close() }

        try self.makeXattr(key: "ten", value: "diez").write(to: fd)
        self.assertXattrs(
            testFile,
            [
                "one": "uno", "two": "dos", "three": "tres", "four": "cuatro", "five": "cinco",
                "six": "seis", "seven": "siete", "eight": "ocho", "nine": "nueve", "ten": "diez"
            ]
        )

        try self.makeXattr(key: "eleven", value: "once").write(toFileDescriptor: fd.rawValue)
        self.assertXattrs(
            testFile,
            [
                "one": "uno", "two": "dos", "three": "tres", "four": "cuatro", "five": "cinco",
                "six": "seis", "seven": "siete", "eight": "ocho", "nine": "nueve", "ten": "diez", "eleven": "once"
            ]
        )
    }

    func testWriteExtendedAttributesToSymlink() throws {
        let orig = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let link = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)

        try Data().write(to: orig)
        defer { _ = try? FileManager.default.removeItem(at: orig) }

        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: orig)
        defer { _ = try? FileManager.default.removeItem(at: link) }

#if Foundation
        try self.makeXattr(key: "a", value: "A").write(to: link, options: .noTraverseLink)
        try self.makeXattr(key: "b", value: "B").write(to: link, options: [])
#else
        try self.makeXattr(key: "a", value: "A").write(to: FilePath(link.path), options: .noTraverseLink)
        try self.makeXattr(key: "b", value: "B").write(to: FilePath(link.path), options: [])
#endif
        self.assertXattrs(link, ["a": "A"], options: .noTraverseLink)
        self.assertXattrs(orig, ["b": "B"], options: .noTraverseLink)

        try self.makeXattr(key: "c", value: "C").write(to: FilePath(link.path), options: .noTraverseLink)
        try self.makeXattr(key: "d", value: "D").write(to: FilePath(link.path), options: [])
        self.assertXattrs(link, ["a": "A", "c": "C"], options: .noTraverseLink)
        self.assertXattrs(orig, ["b": "B", "d": "D"], options: .noTraverseLink)

        try self.makeXattr(key: "e", value: "E").write(toPath: link.path, options: .noTraverseLink)
        try self.makeXattr(key: "f", value: "F").write(toPath: link.path, options: [])
        self.assertXattrs(link, ["a": "A", "c": "C", "e": "E"], options: .noTraverseLink)
        self.assertXattrs(orig, ["b": "B", "d": "D", "f": "F"], options: .noTraverseLink)

#if Foundation
        try ExtendedAttribute.write(
            [self.makeXattr(key: "g", value: "G"), self.makeXattr(key: "h", value: "H")],
            to: link,
            options: .noTraverseLink
        )
        try ExtendedAttribute.write(
            [self.makeXattr(key: "i", value: "I"), self.makeXattr(key: "j", value: "J")],
            to: link,
            options: []
        )
#else
        try ExtendedAttribute.write(
            [self.makeXattr(key: "g", value: "G"), self.makeXattr(key: "h", value: "H")],
            to: FilePath(link.path),
            options: .noTraverseLink
        )
        try ExtendedAttribute.write(
            [self.makeXattr(key: "i", value: "I"), self.makeXattr(key: "j", value: "J")],
            to: FilePath(link.path),
            options: []
        )
#endif
        self.assertXattrs(link, ["a": "A", "c": "C", "e": "E", "g": "G", "h": "H"], options: .noTraverseLink)
        self.assertXattrs(orig, ["b": "B", "d": "D", "f": "F", "i": "I", "j": "J"], options: .noTraverseLink)

        try ExtendedAttribute.write(
            [self.makeXattr(key: "k", value: "K"), self.makeXattr(key: "l", value: "L")],
            to: FilePath(link.path),
            options: .noTraverseLink
        )
        try ExtendedAttribute.write(
            [self.makeXattr(key: "m", value: "M"), self.makeXattr(key: "n", value: "N")],
            to: FilePath(link.path),
            options: []
        )
        self.assertXattrs(
            link,
            ["a": "A", "c": "C", "e": "E", "g": "G", "h": "H", "k": "K", "l": "L"],
            options: .noTraverseLink
        )
        self.assertXattrs(
            orig,
            ["b": "B", "d": "D", "f": "F", "i": "I", "j": "J", "m": "M", "n": "N"],
            options: .noTraverseLink
        )

        try ExtendedAttribute.write(
            [self.makeXattr(key: "o", value: "O"), self.makeXattr(key: "p", value: "P")],
            toPath: link.path,
            options: .noTraverseLink
        )
        try ExtendedAttribute.write(
            [self.makeXattr(key: "q", value: "Q"), self.makeXattr(key: "r", value: "R")],
            toPath: link.path,
            options: []
        )
        self.assertXattrs(
            link,
            ["a": "A", "c": "C", "e": "E", "g": "G", "h": "H", "k": "K", "l": "L", "o": "O", "p": "P"],
            options: .noTraverseLink
        )
        self.assertXattrs(
            orig,
            ["b": "B", "d": "D", "f": "F", "i": "I", "j": "J", "m": "M", "n": "N", "q": "Q", "r": "R"],
            options: .noTraverseLink
        )
    }

    func testRemoveExtendedAttributes() throws {
        let testFile = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try Data().write(to: testFile)
        defer { _ = try? FileManager.default.removeItem(at: testFile) }

        for eachChar in "abcdefghi" {
#if Foundation
            try self.makeXattr(key: String(eachChar), value: String(eachChar).uppercased()).write(to: testFile)
#else
            try self.makeXattr(key: String(eachChar), value: String(eachChar).uppercased()).write(toPath: testFile.path)
#endif
        }

        self.assertXattrs(
            testFile,
            ["a": "A", "b": "B", "c": "C", "d": "D", "e": "E", "f": "F", "g": "G", "h": "H", "i": "I"]
        )

#if Foundation
        try ExtendedAttribute.remove(keys: ["a", "b"], at: testFile)
#else
        try ExtendedAttribute.remove(keys: ["a", "b"], atPath: testFile.path)
#endif
        self.assertXattrs(testFile, ["c": "C", "d": "D", "e": "E", "f": "F", "g": "G", "h": "H", "i": "I"])

        try ExtendedAttribute.remove(keys: ["c", "d"], at: FilePath(testFile.path))
        self.assertXattrs(testFile, ["e": "E", "f": "F", "g": "G", "h": "H", "i": "I"])

        try ExtendedAttribute.remove(keys: ["e", "f", "g"], atPath: testFile.path)
        self.assertXattrs(testFile, ["h": "H", "i": "I"])

        let fd = try FileDescriptor.open(FilePath(testFile.path), .writeOnly)
        defer { _ = try? fd.close() }

        try ExtendedAttribute.remove(keys: ["h"], at: fd)
        self.assertXattrs(testFile, ["i": "I"])

        try ExtendedAttribute.remove(keys: ["i"], atFileDescriptor: fd.rawValue)
        self.assertXattrs(testFile, [:])
    }

    func testRemoveExtendedAttributesFromLink() throws {
        let orig = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try Data().write(to: orig)
        defer { _ = try? FileManager.default.removeItem(at: orig) }

        let link = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: orig)
        defer { _ = try? FileManager.default.removeItem(at: link) }

        for eachChar in "abcdefghijkl" {
            let xattr = self.makeXattr(key: String(eachChar), value: String(eachChar).uppercased())

#if Foundation
            try xattr.write(to: orig)
            try xattr.write(to: link, options: .noTraverseLink)
#else
            try xattr.write(to: FilePath(orig.path))
            try xattr.write(to: FilePath(link.path), options: .noTraverseLink)
#endif
        }

        self.assertXattrs( orig, [
            "a": "A", "b": "B", "c": "C", "d": "D", "e": "E", "f": "F",
            "g": "G", "h": "H", "i": "I", "j": "J", "k": "K", "l": "L"
        ])
        self.assertXattrs(
            link,
            [
                "a": "A", "b": "B", "c": "C", "d": "D", "e": "E", "f": "F",
                "g": "G", "h": "H", "i": "I", "j": "J", "k": "K", "l": "L"
            ],
            options: .noTraverseLink
        )

#if Foundation
        try ExtendedAttribute.remove(keys: ["a", "b"], at: link, options: .noTraverseLink)
        try ExtendedAttribute.remove(keys: ["c", "d"], at: link, options: [])
#else
        try ExtendedAttribute.remove(keys: ["a", "b"], at: FilePath(link.path), options: .noTraverseLink)
        try ExtendedAttribute.remove(keys: ["c", "d"], at: FilePath(link.path), options: [])
#endif
        self.assertXattrs(
            orig,
            ["a": "A", "b": "B", "e": "E", "f": "F", "g": "G", "h": "H", "i": "I", "j": "J", "k": "K", "l": "L"]
        )
        self.assertXattrs(
            link,
            ["c": "C", "d": "D", "e": "E", "f": "F", "g": "G", "h": "H", "i": "I", "j": "J", "k": "K", "l": "L"],
            options: .noTraverseLink
        )

        try ExtendedAttribute.remove(keys: ["e", "f"], at: FilePath(link.path), options: .noTraverseLink)
        try ExtendedAttribute.remove(keys: ["g", "h"], at: FilePath(link.path), options: [])
        self.assertXattrs(orig, ["a": "A", "b": "B", "e": "E", "f": "F", "i": "I", "j": "J", "k": "K", "l": "L"])
        self.assertXattrs(
            link,
            ["c": "C", "d": "D", "g": "G", "h": "H", "i": "I", "j": "J", "k": "K", "l": "L"],
            options: .noTraverseLink
        )
        
        try ExtendedAttribute.remove(keys: ["i", "j"], atPath: link.path, options: .noTraverseLink)
        try ExtendedAttribute.remove(keys: ["k", "l"], atPath: link.path, options: [])
        self.assertXattrs(orig, ["a": "A", "b": "B", "e": "E", "f": "F", "i": "I", "j": "J"])
        self.assertXattrs(link, ["c": "C", "d": "D", "g": "G", "h": "H", "k": "K", "l": "L"], options: .noTraverseLink)
    }

#if Foundation
    func testFailsWithNonFileURLs() {
        let nonFileURL = URL(string: "https://www.charlessoft.com/index.html")!

        XCTAssertThrowsError(try ExtendedAttribute.list(at: nonFileURL)) {
            XCTAssertEqual(($0 as? CocoaError)?.code, .fileReadUnsupportedScheme)
        }

        XCTAssertThrowsError(try ExtendedAttribute(at: nonFileURL, key: "foo")) {
            XCTAssertEqual(($0 as? CocoaError)?.code, .fileReadUnsupportedScheme)
        }

        XCTAssertThrowsError(try ExtendedAttribute(key: "key", data: Data()).write(to: nonFileURL)) {
            XCTAssertEqual(($0 as? CocoaError)?.code, .fileWriteUnsupportedScheme)
        }

        XCTAssertThrowsError(try ExtendedAttribute.write(["1", "2"].map { .init(key: $0, data: Data()) }, to: nonFileURL)) {
            XCTAssertEqual(($0 as? CocoaError)?.code, .fileWriteUnsupportedScheme)
        }

        XCTAssertThrowsError(try ExtendedAttribute.remove(keys: ["k1", "k2"], at: nonFileURL)) {
            XCTAssertEqual(($0 as? CocoaError)?.code, .fileWriteUnsupportedScheme)
        }
    }
#endif
}
