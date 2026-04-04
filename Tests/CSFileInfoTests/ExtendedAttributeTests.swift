//
//  ExtendedAttributeTests.swift
//
//
//  Created by Charles Srstka on 11/5/23.
//

import CSErrors
@testable import CSFileInfo
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(SystemPackage)
import SystemPackage
#else
import System
#endif

private struct Scope: SuiteTrait, TestScoping {
    @TaskLocal static var tempDir: URL! = nil

    @TaskLocal static var fileWithNoExtendedAttributes: URL! = nil
    @TaskLocal static var fileWithOneExtendedAttribute: URL! = nil
    @TaskLocal static var fileWithMultipleExtendedAttributes: URL! = nil

    @TaskLocal static var dirWithNoExtendedAttributes: URL! = nil
    @TaskLocal static var dirWithOneExtendedAttribute: URL! = nil
    @TaskLocal static var dirWithMultipleExtendedAttributes: URL! = nil

    @TaskLocal static var linkWithNoExtendedAttributes: URL! = nil
    @TaskLocal static var linkWithOneExtendedAttribute: URL! = nil
    @TaskLocal static var linkWithMultipleExtendedAttributes: URL! = nil

    func provideScope(for test: Test, testCase: Test.Case?, performing f: @Sendable () async throws -> Void) async throws {
        let tempDir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileNoXattr = tempDir.appending(path: UUID().uuidString)
        try Data().write(to: fileNoXattr)

        let file1Xattr = tempDir.appending(path: UUID().uuidString)
        try Data().write(to: file1Xattr)
        try callPOSIXFunction(expect: .zero) { setxattr(file1Xattr.path, "foo", "lish", 4, 0, 0) }

        let fileMultiXattrs = tempDir.appending(path: UUID().uuidString)
        try Data().write(to: fileMultiXattrs)
        try callPOSIXFunction(expect: .zero) {
            setxattr(fileMultiXattrs.path, "bar", "barian", 6, 0, 0)
        }
        try callPOSIXFunction(expect: .zero) {
            setxattr(fileMultiXattrs.path, "baz", "zerk", 4, 0, 0)
        }

        let dirNoXattr = tempDir.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dirNoXattr, withIntermediateDirectories: true)

        let dirOneXattr = tempDir.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dirOneXattr, withIntermediateDirectories: true)
        try callPOSIXFunction(expect: .zero) { setxattr(dirOneXattr.path, "foo", "lish", 4, 0, 0) }

        let dirMultiXattrs = tempDir.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dirMultiXattrs, withIntermediateDirectories: true)
        try callPOSIXFunction(expect: .zero) {
            setxattr(dirMultiXattrs.path, "bar", "barian", 6, 0, 0)
        }
        try callPOSIXFunction(expect: .zero) {
            setxattr(dirMultiXattrs.path, "baz", "zerk", 4, 0, 0)
        }

        let linkNoXattr = tempDir.appending(path: UUID().uuidString)
        try FileManager.default.createSymbolicLink(
            at: linkNoXattr,
            withDestinationURL: fileMultiXattrs
        )

        let linkOneXattr = tempDir.appending(path: UUID().uuidString)
        try FileManager.default.createSymbolicLink(
            at: linkOneXattr,
            withDestinationURL: fileNoXattr
        )

        let linkWithOneXattrFd = open(linkOneXattr.path, O_RDWR | O_SYMLINK)
        defer { close(linkWithOneXattrFd) }
        try callPOSIXFunction(expect: .zero) {
            fsetxattr(linkWithOneXattrFd, "foo", "lish", 4, 0, 0)
        }

        let linkMultiXattr = tempDir.appending(path: UUID().uuidString)
        try FileManager.default.createSymbolicLink(
            at: linkMultiXattr,
            withDestinationURL: dirNoXattr
        )

        let linkWithMultipleXattrsFd = open(linkMultiXattr.path, O_RDWR | O_SYMLINK)
        defer { close(linkWithMultipleXattrsFd) }
        try callPOSIXFunction(expect: .zero) {
            fsetxattr(linkWithMultipleXattrsFd, "bar", "barian", 6, 0, 0)
        }
        try callPOSIXFunction(expect: .zero) {
            fsetxattr(linkWithMultipleXattrsFd, "baz", "zerk", 4, 0, 0)
        }

        // Pyramid of Doooooooooooom (is there any way to set task local vars in bulk?)
        try await Self.$tempDir.withValue(tempDir) {
            try await Self.$fileWithNoExtendedAttributes.withValue(fileNoXattr) {
                try await Self.$fileWithOneExtendedAttribute.withValue(file1Xattr) {
                    try await Self.$fileWithMultipleExtendedAttributes.withValue(fileMultiXattrs) {
                        try await Self.$dirWithNoExtendedAttributes.withValue(dirNoXattr) {
                            try await Self.$dirWithOneExtendedAttribute.withValue(dirOneXattr) {
                                try await Self.$dirWithMultipleExtendedAttributes.withValue(dirMultiXattrs) {
                                    try await Self.$linkWithNoExtendedAttributes.withValue(linkNoXattr) {
                                        try await Self.$linkWithOneExtendedAttribute.withValue(linkOneXattr) {
                                            try await Self.$linkWithMultipleExtendedAttributes.withValue(linkMultiXattr) {
                                                try await f()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Suite(Scope())
struct ExtendedAttributeTests {
    @Test(arguments: [10, 11, 12, 13, .max])
    func testOSVersion(version: Int) throws {
        try emulateOSVersion(version) {
            try self.testListExtendedAttributes()
            try self.testReadExtendedAttributes()
            try self.testWriteExtendedAttributes()
            try self.testWriteExtendedAttributesToSymlink()
            try self.testRemoveExtendedAttributes()
            try self.testRemoveExtendedAttributesFromLink()
        }
    }

    private func makeXattr(key: String, value: String) -> ExtendedAttribute {
        ExtendedAttribute(key: key, data: value.utf8)
    }

    private func assertXattrs(_ url: URL, _ dict: [String : String], options: ExtendedAttribute.ReadOptions = []) throws {
        let xattrs = dict.map { self.makeXattr(key: $0.key, value: $0.value) }

#if Foundation
        #expect(try Set(ExtendedAttribute.list(at: url, options: options)) == Set(xattrs))
#endif
        #expect(try Set(ExtendedAttribute.list(at: FilePath(url.path), options: options)) == Set(xattrs))
        #expect(try Set(ExtendedAttribute.list(atPath: url.path, options: options)) == Set(xattrs))
    }

    @Test
    func testListExtendedAttributes() throws {
        func assertListEqual(_ url: URL, _ list: [String : String], options: ExtendedAttribute.ReadOptions = []) throws {
            let attrs = Set(list.map { self.makeXattr(key: $0.key, value: $0.value) })

#if Foundation
            #expect(try Set(ExtendedAttribute.list(at: url, options: options)) == attrs)
#endif
            #expect(try Set(ExtendedAttribute.list(at: FilePath(url.path), options: options)) == attrs)
            #expect(try Set(ExtendedAttribute.list(atPath: url.path, options: options)) == attrs)

            let fdOptions: FileDescriptor.OpenOptions = options.contains(.noTraverseLink) ? .symlink : []
            let fd = try! FileDescriptor.open(url.path, .readOnly, options: fdOptions)
            defer { _ = try? fd.close() }

            #expect(try Set(ExtendedAttribute.list(at: fd, options: options)) == attrs)
            #expect(try Set(ExtendedAttribute.list(atFileDescriptor: fd.rawValue, options: options)) == attrs)
        }

        let nonexistentFile = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
#if Foundation
        #expect(#expect(throws: Error.self) { try ExtendedAttribute.list(at: nonexistentFile) }?.isFileNotFoundError == true)
        #expect(#expect(throws: Error.self) { try ExtendedAttribute.list(at: nonexistentFile) }?.isFileNotFoundError == true)
#endif
        #expect(
            #expect(throws: Error.self) {
                try ExtendedAttribute.list(at: FilePath(nonexistentFile.path))
            }?.isFileNotFoundError == true
        )
        #expect(
            #expect(throws: Error.self) {
                try ExtendedAttribute.list(atPath: nonexistentFile.path)
            }?.isFileNotFoundError == true
        )

        try assertListEqual(Scope.fileWithNoExtendedAttributes, [:])
        try assertListEqual(Scope.fileWithOneExtendedAttribute, ["foo" : "lish"])
        try assertListEqual(Scope.fileWithMultipleExtendedAttributes, ["bar" : "barian", "baz" : "zerk"])

        try assertListEqual(Scope.dirWithNoExtendedAttributes, [:])
        try assertListEqual(Scope.dirWithOneExtendedAttribute, ["foo" : "lish"])
        try assertListEqual(Scope.dirWithMultipleExtendedAttributes, ["bar" : "barian", "baz" : "zerk"])

        try assertListEqual(Scope.linkWithNoExtendedAttributes, ["bar" : "barian", "baz" : "zerk"], options: [])
        try assertListEqual(Scope.linkWithOneExtendedAttribute, [:], options: [])
        try assertListEqual(Scope.linkWithMultipleExtendedAttributes, [:], options: [])

        try assertListEqual(Scope.linkWithNoExtendedAttributes, [:], options: .noTraverseLink)
        try assertListEqual(Scope.linkWithOneExtendedAttribute, ["foo" : "lish"], options: .noTraverseLink)
        try assertListEqual(
            Scope.linkWithMultipleExtendedAttributes,
            ["bar" : "barian", "baz" : "zerk"],
            options: .noTraverseLink
        )
    }

    @Test
    func testReadExtendedAttributes() throws {
        func assertGetAttribute(url: URL, key: String, expectedAttribute: String, traverseLink: Bool = false) throws {
            let options: ExtendedAttribute.ReadOptions = traverseLink ? [] : [.noTraverseLink]

#if Foundation
            #expect(
                try String(
                    decoding: ExtendedAttribute(at: url, key: key, options: options).data,
                    as: UTF8.self
                ) == expectedAttribute
            )
#endif

            #expect(
                try String(
                    decoding: ExtendedAttribute(at: FilePath(url.path), key: key, options: options).data,
                    as: UTF8.self
                ) == expectedAttribute
            )

            #expect(
                try String(
                    decoding: ExtendedAttribute(atPath: url.path, key: key, options: options).data,
                    as: UTF8.self
                ) == expectedAttribute
            )

            let openOptions: FileDescriptor.OpenOptions = options.contains(.noTraverseLink) ? .symlink : []
            let fd = try FileDescriptor.open(FilePath(url.path), .readOnly, options: openOptions)
            defer { _ = try? fd.close() }

            let fdOptions = options.subtracting(.noTraverseLink)

            #expect(
                try String(
                    decoding: ExtendedAttribute(at: fd, key: key, options: fdOptions).data,
                    as: UTF8.self
                ) == expectedAttribute
            )

            #expect(
                try String(
                    decoding: ExtendedAttribute(atFileDescriptor: fd.rawValue, key: key, options: fdOptions).data,
                    as: UTF8.self
                ) == expectedAttribute
            )
        }

        func assertThrowsError<E: Error & Equatable>(url: URL, key: String, error: E, traverseLink: Bool = false) {
            let options: ExtendedAttribute.ReadOptions = traverseLink ? [] : [.noTraverseLink]

#if Foundation
            #expect(#expect(throws: E.self) { try ExtendedAttribute(at: url, key: key, options: options) }?._code == error._code)
#endif

            #expect(#expect(throws: E.self) {
                try ExtendedAttribute(at: FilePath(url.path), key: key, options: options)
            }?._code == error._code)

            #expect(#expect(throws: E.self) {
                try ExtendedAttribute(atPath: url.path, key: key, options: options)
            }?._code == error._code)
        }

        let nonexistentFile = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
#if Foundation
        assertThrowsError(url: nonexistentFile, key: "foo", error: CocoaError(.fileReadNoSuchFile))
#else
        assertThrowsError(url: nonexistentFile, key: "foo", error: Errno.noSuchFileOrDirectory)
#endif

        assertThrowsError(url: Scope.fileWithNoExtendedAttributes, key: "foo", error: Errno.attributeNotFound)

        try assertGetAttribute(url: Scope.fileWithOneExtendedAttribute, key: "foo", expectedAttribute: "lish")
        assertThrowsError(url: Scope.fileWithOneExtendedAttribute, key: "bar", error: Errno.attributeNotFound)

        try assertGetAttribute(url: Scope.fileWithMultipleExtendedAttributes, key: "bar", expectedAttribute: "barian")
        try assertGetAttribute(url: Scope.fileWithMultipleExtendedAttributes, key: "baz", expectedAttribute: "zerk")
        assertThrowsError(url: Scope.fileWithMultipleExtendedAttributes, key: "foo", error: Errno.attributeNotFound)

        assertThrowsError(url: Scope.dirWithNoExtendedAttributes, key: "foo", error: Errno.attributeNotFound)

        try assertGetAttribute(url: Scope.dirWithOneExtendedAttribute, key: "foo", expectedAttribute: "lish")
        assertThrowsError(url: Scope.dirWithOneExtendedAttribute, key: "bar", error: Errno.attributeNotFound)

        try assertGetAttribute(url: Scope.dirWithMultipleExtendedAttributes, key: "bar", expectedAttribute: "barian")
        try assertGetAttribute(url: Scope.dirWithMultipleExtendedAttributes, key: "baz", expectedAttribute: "zerk")
        assertThrowsError(url: Scope.dirWithMultipleExtendedAttributes, key: "foo", error: Errno.attributeNotFound)

        assertThrowsError(
            url: Scope.linkWithNoExtendedAttributes,
            key: "foo",
            error: Errno.attributeNotFound,
            traverseLink: false
        )

        try assertGetAttribute(
            url: Scope.linkWithOneExtendedAttribute,
            key: "foo",
            expectedAttribute: "lish",
            traverseLink: false
        )
        assertThrowsError(
            url: Scope.linkWithOneExtendedAttribute,
            key: "bar",
            error: Errno.attributeNotFound,
            traverseLink: false
        )

        try assertGetAttribute(
            url: Scope.linkWithMultipleExtendedAttributes,
            key: "bar",
            expectedAttribute: "barian",
            traverseLink: false
        )
        try assertGetAttribute(
            url: Scope.linkWithMultipleExtendedAttributes,
            key: "baz",
            expectedAttribute: "zerk",
            traverseLink: false
        )
        assertThrowsError(
            url: Scope.linkWithMultipleExtendedAttributes,
            key: "foo",
            error: Errno.attributeNotFound,
            traverseLink: false
        )

        try assertGetAttribute(
            url: Scope.linkWithNoExtendedAttributes,
            key: "bar",
            expectedAttribute: "barian",
            traverseLink: true
        )
        try assertGetAttribute(
            url: Scope.linkWithNoExtendedAttributes,
            key: "baz",
            expectedAttribute: "zerk",
            traverseLink: true
        )
        assertThrowsError(
            url: Scope.linkWithNoExtendedAttributes,
            key: "foo",
            error: Errno.attributeNotFound,
            traverseLink: true
        )

        assertThrowsError(
            url: Scope.linkWithOneExtendedAttribute,
            key: "foo",
            error: Errno.attributeNotFound,
            traverseLink: true
        )
        assertThrowsError(
            url: Scope.linkWithOneExtendedAttribute,
            key: "bar",
            error: Errno.attributeNotFound,
            traverseLink: true
        )

        assertThrowsError(
            url: Scope.linkWithMultipleExtendedAttributes,
            key: "foo",
            error: Errno.attributeNotFound,
            traverseLink: true
        )
        assertThrowsError(
            url: Scope.linkWithMultipleExtendedAttributes,
            key: "bar",
            error: Errno.attributeNotFound,
            traverseLink: true
        )
    }

    @Test
    func testWriteExtendedAttributes() throws {
        let testFile = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try Data().write(to: testFile)
        defer { _ = try? FileManager.default.removeItem(at: testFile) }

        try self.assertXattrs(testFile, [:])

#if Foundation
        try self.makeXattr(key: "one", value: "uno").write(to: testFile)
#else
        try self.makeXattr(key: "one", value: "uno").write(to: FilePath(testFile.path))
#endif
        try self.assertXattrs(testFile, ["one": "uno"])

        try self.makeXattr(key: "two", value: "dos").write(to: FilePath(testFile.path))
        try self.assertXattrs(testFile, ["one": "uno", "two": "dos"])

        try self.makeXattr(key: "three", value: "tres").write(toPath: testFile.path)
        try self.assertXattrs(testFile, ["one": "uno", "two": "dos", "three": "tres"])

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
        try self.assertXattrs(testFile, ["one": "uno", "two": "dos", "three": "tres", "four": "cuatro", "five": "cinco"])

        try ExtendedAttribute.write(
            [
                .init(key: "six", data: "seis".data(using: .utf8)!),
                .init(key: "seven", data: "siete".data(using: .utf8)!)
            ],
            to: FilePath(testFile.path)
        )
        try self.assertXattrs(
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
        try self.assertXattrs(
            testFile,
            [
                "one": "uno", "two": "dos", "three": "tres", "four": "cuatro", "five": "cinco",
                "six": "seis", "seven": "siete", "eight": "ocho", "nine": "nueve"
            ]
        )

        let fd = try FileDescriptor.open(FilePath(testFile.path), .writeOnly)
        defer { _ = try? fd.close() }

        try self.makeXattr(key: "ten", value: "diez").write(to: fd)
        try self.assertXattrs(
            testFile,
            [
                "one": "uno", "two": "dos", "three": "tres", "four": "cuatro", "five": "cinco",
                "six": "seis", "seven": "siete", "eight": "ocho", "nine": "nueve", "ten": "diez"
            ]
        )

        try self.makeXattr(key: "eleven", value: "once").write(toFileDescriptor: fd.rawValue)
        try self.assertXattrs(
            testFile,
            [
                "one": "uno", "two": "dos", "three": "tres", "four": "cuatro", "five": "cinco",
                "six": "seis", "seven": "siete", "eight": "ocho", "nine": "nueve", "ten": "diez", "eleven": "once"
            ]
        )
    }

    @Test
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
        try self.assertXattrs(link, ["a": "A"], options: .noTraverseLink)
        try self.assertXattrs(orig, ["b": "B"], options: .noTraverseLink)

        try self.makeXattr(key: "c", value: "C").write(to: FilePath(link.path), options: .noTraverseLink)
        try self.makeXattr(key: "d", value: "D").write(to: FilePath(link.path), options: [])
        try self.assertXattrs(link, ["a": "A", "c": "C"], options: .noTraverseLink)
        try self.assertXattrs(orig, ["b": "B", "d": "D"], options: .noTraverseLink)

        try self.makeXattr(key: "e", value: "E").write(toPath: link.path, options: .noTraverseLink)
        try self.makeXattr(key: "f", value: "F").write(toPath: link.path, options: [])
        try self.assertXattrs(link, ["a": "A", "c": "C", "e": "E"], options: .noTraverseLink)
        try self.assertXattrs(orig, ["b": "B", "d": "D", "f": "F"], options: .noTraverseLink)

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
        try self.assertXattrs(link, ["a": "A", "c": "C", "e": "E", "g": "G", "h": "H"], options: .noTraverseLink)
        try self.assertXattrs(orig, ["b": "B", "d": "D", "f": "F", "i": "I", "j": "J"], options: .noTraverseLink)

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
        try self.assertXattrs(
            link,
            ["a": "A", "c": "C", "e": "E", "g": "G", "h": "H", "k": "K", "l": "L"],
            options: .noTraverseLink
        )
        try self.assertXattrs(
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
        try self.assertXattrs(
            link,
            ["a": "A", "c": "C", "e": "E", "g": "G", "h": "H", "k": "K", "l": "L", "o": "O", "p": "P"],
            options: .noTraverseLink
        )
        try self.assertXattrs(
            orig,
            ["b": "B", "d": "D", "f": "F", "i": "I", "j": "J", "m": "M", "n": "N", "q": "Q", "r": "R"],
            options: .noTraverseLink
        )
    }

    @Test
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

        try self.assertXattrs(
            testFile,
            ["a": "A", "b": "B", "c": "C", "d": "D", "e": "E", "f": "F", "g": "G", "h": "H", "i": "I"]
        )

#if Foundation
        try ExtendedAttribute.remove(keys: ["a", "b"], at: testFile)
#else
        try ExtendedAttribute.remove(keys: ["a", "b"], atPath: testFile.path)
#endif
        try self.assertXattrs(testFile, ["c": "C", "d": "D", "e": "E", "f": "F", "g": "G", "h": "H", "i": "I"])

        try ExtendedAttribute.remove(keys: ["c", "d"], at: FilePath(testFile.path))
        try self.assertXattrs(testFile, ["e": "E", "f": "F", "g": "G", "h": "H", "i": "I"])

        try ExtendedAttribute.remove(keys: ["e", "f", "g"], atPath: testFile.path)
        try self.assertXattrs(testFile, ["h": "H", "i": "I"])

        let fd = try FileDescriptor.open(FilePath(testFile.path), .writeOnly)
        defer { _ = try? fd.close() }

        try ExtendedAttribute.remove(keys: ["h"], at: fd)
        try self.assertXattrs(testFile, ["i": "I"])

        try ExtendedAttribute.remove(keys: ["i"], atFileDescriptor: fd.rawValue)
        try self.assertXattrs(testFile, [:])
    }

    @Test
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

        try self.assertXattrs( orig, [
            "a": "A", "b": "B", "c": "C", "d": "D", "e": "E", "f": "F",
            "g": "G", "h": "H", "i": "I", "j": "J", "k": "K", "l": "L"
        ])
        try self.assertXattrs(
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
        try self.assertXattrs(
            orig,
            ["a": "A", "b": "B", "e": "E", "f": "F", "g": "G", "h": "H", "i": "I", "j": "J", "k": "K", "l": "L"]
        )
        try self.assertXattrs(
            link,
            ["c": "C", "d": "D", "e": "E", "f": "F", "g": "G", "h": "H", "i": "I", "j": "J", "k": "K", "l": "L"],
            options: .noTraverseLink
        )

        try ExtendedAttribute.remove(keys: ["e", "f"], at: FilePath(link.path), options: .noTraverseLink)
        try ExtendedAttribute.remove(keys: ["g", "h"], at: FilePath(link.path), options: [])
        try self.assertXattrs(orig, ["a": "A", "b": "B", "e": "E", "f": "F", "i": "I", "j": "J", "k": "K", "l": "L"])
        try self.assertXattrs(
            link,
            ["c": "C", "d": "D", "g": "G", "h": "H", "i": "I", "j": "J", "k": "K", "l": "L"],
            options: .noTraverseLink
        )
        
        try ExtendedAttribute.remove(keys: ["i", "j"], atPath: link.path, options: .noTraverseLink)
        try ExtendedAttribute.remove(keys: ["k", "l"], atPath: link.path, options: [])
        try self.assertXattrs(orig, ["a": "A", "b": "B", "e": "E", "f": "F", "i": "I", "j": "J"])
        try self.assertXattrs(link, ["c": "C", "d": "D", "g": "G", "h": "H", "k": "K", "l": "L"], options: .noTraverseLink)
    }

#if Foundation
    @Test
    func testFailsWithNonFileURLs() {
        let nonFileURL = URL(string: "https://www.charlessoft.com/index.html")!

        #expect(
            #expect(throws: CocoaError.self) {
                try ExtendedAttribute.list(at: nonFileURL)
            }?.code == .fileReadUnsupportedScheme
        )

        #expect(
            #expect(throws: CocoaError.self) {
                try ExtendedAttribute(at: nonFileURL, key: "foo")
            }?.code == .fileReadUnsupportedScheme
        )

        #expect(
            #expect(throws: CocoaError.self) {
                try ExtendedAttribute(key: "key", data: Data()).write(to: nonFileURL)
            }?.code == .fileWriteUnsupportedScheme
        )

        #expect(
            #expect(throws: CocoaError.self) {
                try ExtendedAttribute.write(["1", "2"].map { .init(key: $0, data: Data()) }, to: nonFileURL)
            }?.code == .fileWriteUnsupportedScheme
        )

        #expect(
            #expect(throws: CocoaError.self) {
                try ExtendedAttribute.remove(keys: ["k1", "k2"], at: nonFileURL)
            }?.code == .fileWriteUnsupportedScheme
        )
    }
#endif
}
