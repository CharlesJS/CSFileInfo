//
//  ExtendedAttributeTests.swift
//
//
//  Created by Charles Srstka on 11/5/23.
//

import CSErrors
@testable import CSFileInfo
import CSFileInfo_CShims
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

#if canImport(Darwin) || canImport(FreeBSD)
private let attributeNotFoundError = Errno.attributeNotFound
#else
private let attributeNotFoundError = Errno.noData
#endif

#if canImport(Darwin)
private let symlinkOpenFlag: CInt = O_SYMLINK
#else
private let symlinkOpenFlag: CInt = O_PATH | O_NOFOLLOW
#endif

#if canImport(Darwin)
private func setxattr(_ path: String, _ name: String, _ value: String, _ size: Int, _ position: Int, _ options: Int) -> Int {
    assert(position == 0)

    var result: Int32 = 0
    path.withCString { pathPtr in
        name.withCString { namePtr in
            value.withCString { valuePtr in
                result = Darwin.setxattr(pathPtr, namePtr, valuePtr, size_t(size), UInt32(position), Int32(options))
            }
        }
    }
    return Int(result)
}

private func fsetxattr(_ fd: Int32, _ name: String, _ value: String, _ size: Int, _ position: Int, _ options: Int) -> Int {
    assert(position == 0)

    var result: Int32 = 0
    name.withCString { namePtr in
        value.withCString { valuePtr in
            result = Darwin.fsetxattr(fd, namePtr, valuePtr, size_t(size), UInt32(position), Int32(options))
        }
    }
    return Int(result)
}
#else
private func setxattr(_ path: String, _ name: String, _ value: String, _ size: Int, _ position: Int, _ options: Int) -> Int {
    assert(position == 0)

    var result: Int32 = 0
    path.withCString { pathPtr in
        name.withCString { namePtr in
            value.withCString { valuePtr in
                result = CSFileInfo_CShims.setxattr(pathPtr, namePtr, valuePtr, size_t(size), Int32(options))
            }
        }
    }
    return Int(result)
}

private func fsetxattr(_ fd: Int32, _ name: String, _ value: String, _ size: Int, _ position: Int, _ options: Int) -> Int {
    assert(position == 0)

    var result: Int32 = 0
    name.withCString { namePtr in
        value.withCString { valuePtr in
            result = CSFileInfo_CShims.fsetxattr(fd, namePtr, valuePtr, size_t(size), Int32(options))
        }
    }
    return Int(result)
}
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
        try callPOSIXFunction(expect: .zero) { setxattr(file1Xattr.path, "user.foo", "lish", 4, 0, 0) }

        let fileMultiXattrs = tempDir.appending(path: UUID().uuidString)
        try Data().write(to: fileMultiXattrs)
        try callPOSIXFunction(expect: .zero) {
            setxattr(fileMultiXattrs.path, "user.bar", "barian", 6, 0, 0)
        }
        try callPOSIXFunction(expect: .zero) {
            setxattr(fileMultiXattrs.path, "user.baz", "zerk", 4, 0, 0)
        }

        let dirNoXattr = tempDir.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dirNoXattr, withIntermediateDirectories: true)

        let dirOneXattr = tempDir.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dirOneXattr, withIntermediateDirectories: true)
        try callPOSIXFunction(expect: .zero) { setxattr(dirOneXattr.path, "user.foo", "lish", 4, 0, 0) }

        let dirMultiXattrs = tempDir.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dirMultiXattrs, withIntermediateDirectories: true)
        try callPOSIXFunction(expect: .zero) {
            setxattr(dirMultiXattrs.path, "user.bar", "barian", 6, 0, 0)
        }
        try callPOSIXFunction(expect: .zero) {
            setxattr(dirMultiXattrs.path, "user.baz", "zerk", 4, 0, 0)
        }

#if canImport(Darwin) // Linux does not allow setting user.xattrs on symlinks
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

        let linkWithOneXattrFd = CSFileInfo_CShims.open(linkOneXattr.path, O_RDWR | symlinkOpenFlag)
        defer { close(linkWithOneXattrFd) }
        try callPOSIXFunction(expect: .zero) {
            fsetxattr(linkWithOneXattrFd, "user.foo", "lish", 4, 0, 0)
        }

        let linkMultiXattr = tempDir.appending(path: UUID().uuidString)
        try FileManager.default.createSymbolicLink(
            at: linkMultiXattr,
            withDestinationURL: dirNoXattr
        )

        let linkWithMultipleXattrsFd = CSFileInfo_CShims.open(linkMultiXattr.path, O_RDWR | symlinkOpenFlag)
        defer { close(linkWithMultipleXattrsFd) }
        try callPOSIXFunction(expect: .zero) {
            fsetxattr(linkWithMultipleXattrsFd, "user.bar", "barian", 6, 0, 0)
        }
        try callPOSIXFunction(expect: .zero) {
            fsetxattr(linkWithMultipleXattrsFd, "user.baz", "zerk", 4, 0, 0)
        }
#endif

        // Pyramid of Doooooooooooom (is there any way to set task local vars in bulk?)
        try await Self.$tempDir.withValue(tempDir) {
            try await Self.$fileWithNoExtendedAttributes.withValue(fileNoXattr) {
                try await Self.$fileWithOneExtendedAttribute.withValue(file1Xattr) {
                    try await Self.$fileWithMultipleExtendedAttributes.withValue(fileMultiXattrs) {
                        try await Self.$dirWithNoExtendedAttributes.withValue(dirNoXattr) {
                            try await Self.$dirWithOneExtendedAttribute.withValue(dirOneXattr) {
                                try await Self.$dirWithMultipleExtendedAttributes.withValue(dirMultiXattrs) {
#if canImport(Darwin)
                                    try await Self.$linkWithNoExtendedAttributes.withValue(linkNoXattr) {
                                        try await Self.$linkWithOneExtendedAttribute.withValue(linkOneXattr) {
                                            try await Self.$linkWithMultipleExtendedAttributes.withValue(linkMultiXattr) {
                                                try await f()
                                            }
                                        }
                                    }
#else
                                    try await f()
#endif
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
#if canImport(Darwin) // Linux does not allow setting user.xattrs on symlinks
    @Test(arguments: [10, 11, 12, 13, .max])
    func testOSVersion(version: Int) throws {
        try emulateOSVersion(version) {
            try self.testListExtendedAttributes()
            try self.testReadExtendedAttributes()
            try self.testWriteExtendedAttributes()
            try self.testRemoveExtendedAttributes()
            try self.testWriteExtendedAttributesToSymlink()
            try self.testRemoveExtendedAttributesFromLink()
        }
    }
#endif

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

            let fd: FileDescriptor
#if canImport(Darwin)
            let fdOptions: FileDescriptor.OpenOptions = options.contains(.noTraverseLink) ? .symlink : []
            fd = try! FileDescriptor.open(url.path, .readOnly, options: fdOptions)
#else
            fd = try! FileDescriptor.open(url.path, .readOnly)
#endif
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
        try assertListEqual(Scope.fileWithOneExtendedAttribute, ["user.foo" : "lish"])
        try assertListEqual(Scope.fileWithMultipleExtendedAttributes, ["user.bar" : "barian", "user.baz" : "zerk"])

        try assertListEqual(Scope.dirWithNoExtendedAttributes, [:])
        try assertListEqual(Scope.dirWithOneExtendedAttribute, ["user.foo" : "lish"])
        try assertListEqual(Scope.dirWithMultipleExtendedAttributes, ["user.bar" : "barian", "user.baz" : "zerk"])

#if canImport(Darwin) // Linux does not support user.xattrs on symlinks
        try assertListEqual(Scope.linkWithNoExtendedAttributes, ["user.bar" : "barian", "user.baz" : "zerk"], options: [])
        try assertListEqual(Scope.linkWithOneExtendedAttribute, [:], options: [])
        try assertListEqual(Scope.linkWithMultipleExtendedAttributes, [:], options: [])

        try assertListEqual(Scope.linkWithNoExtendedAttributes, [:], options: .noTraverseLink)
        try assertListEqual(Scope.linkWithOneExtendedAttribute, ["user.foo" : "lish"], options: .noTraverseLink)
        try assertListEqual(
            Scope.linkWithMultipleExtendedAttributes,
            ["user.bar" : "barian", "user.baz" : "zerk"],
            options: .noTraverseLink
        )
#endif
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

            #if canImport(Darwin)
            let openOptions: FileDescriptor.OpenOptions = options.contains(.noTraverseLink) ? .symlink : []
            let fd = try FileDescriptor.open(FilePath(url.path), .readOnly, options: openOptions)
#else
            let fd = try FileDescriptor.open(FilePath(url.path), .readOnly)
#endif
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
        assertThrowsError(url: nonexistentFile, key: "user.foo", error: CocoaError(.fileReadNoSuchFile))
#else
        assertThrowsError(url: nonexistentFile, key: "user.foo", error: Errno.noSuchFileOrDirectory)
#endif

        assertThrowsError(url: Scope.fileWithNoExtendedAttributes, key: "user.foo", error: attributeNotFoundError)

        try assertGetAttribute(url: Scope.fileWithOneExtendedAttribute, key: "user.foo", expectedAttribute: "lish")
        assertThrowsError(url: Scope.fileWithOneExtendedAttribute, key: "user.bar", error: attributeNotFoundError)

        try assertGetAttribute(url: Scope.fileWithMultipleExtendedAttributes, key: "user.bar", expectedAttribute: "barian")
        try assertGetAttribute(url: Scope.fileWithMultipleExtendedAttributes, key: "user.baz", expectedAttribute: "zerk")
        assertThrowsError(url: Scope.fileWithMultipleExtendedAttributes, key: "user.foo", error: attributeNotFoundError)

        assertThrowsError(url: Scope.dirWithNoExtendedAttributes, key: "user.foo", error: attributeNotFoundError)

        try assertGetAttribute(url: Scope.dirWithOneExtendedAttribute, key: "user.foo", expectedAttribute: "lish")
        assertThrowsError(url: Scope.dirWithOneExtendedAttribute, key: "user.bar", error: attributeNotFoundError)

        try assertGetAttribute(url: Scope.dirWithMultipleExtendedAttributes, key: "user.bar", expectedAttribute: "barian")
        try assertGetAttribute(url: Scope.dirWithMultipleExtendedAttributes, key: "user.baz", expectedAttribute: "zerk")
        assertThrowsError(url: Scope.dirWithMultipleExtendedAttributes, key: "user.foo", error: attributeNotFoundError)

#if canImport(Darwin) // Linux does not allow user.xattrs on symlinks
        assertThrowsError(
            url: Scope.linkWithNoExtendedAttributes,
            key: "user.foo",
            error: attributeNotFoundError,
            traverseLink: false
        )

        try assertGetAttribute(
            url: Scope.linkWithOneExtendedAttribute,
            key: "user.foo",
            expectedAttribute: "lish",
            traverseLink: false
        )
        assertThrowsError(
            url: Scope.linkWithOneExtendedAttribute,
            key: "user.bar",
            error: attributeNotFoundError,
            traverseLink: false
        )

        try assertGetAttribute(
            url: Scope.linkWithMultipleExtendedAttributes,
            key: "user.bar",
            expectedAttribute: "barian",
            traverseLink: false
        )
        try assertGetAttribute(
            url: Scope.linkWithMultipleExtendedAttributes,
            key: "user.baz",
            expectedAttribute: "zerk",
            traverseLink: false
        )
        assertThrowsError(
            url: Scope.linkWithMultipleExtendedAttributes,
            key: "user.foo",
            error: attributeNotFoundError,
            traverseLink: false
        )

        try assertGetAttribute(
            url: Scope.linkWithNoExtendedAttributes,
            key: "user.bar",
            expectedAttribute: "barian",
            traverseLink: true
        )
        try assertGetAttribute(
            url: Scope.linkWithNoExtendedAttributes,
            key: "user.baz",
            expectedAttribute: "zerk",
            traverseLink: true
        )
        assertThrowsError(
            url: Scope.linkWithNoExtendedAttributes,
            key: "user.foo",
            error: attributeNotFoundError,
            traverseLink: true
        )

        assertThrowsError(
            url: Scope.linkWithOneExtendedAttribute,
            key: "user.foo",
            error: attributeNotFoundError,
            traverseLink: true
        )
        assertThrowsError(
            url: Scope.linkWithOneExtendedAttribute,
            key: "user.bar",
            error: attributeNotFoundError,
            traverseLink: true
        )

        assertThrowsError(
            url: Scope.linkWithMultipleExtendedAttributes,
            key: "user.foo",
            error: attributeNotFoundError,
            traverseLink: true
        )
        assertThrowsError(
            url: Scope.linkWithMultipleExtendedAttributes,
            key: "user.bar",
            error: attributeNotFoundError,
            traverseLink: true
        )
#endif
    }

    @Test
    func testWriteExtendedAttributes() throws {
        let testFile = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try Data().write(to: testFile)
        defer { _ = try? FileManager.default.removeItem(at: testFile) }

        try self.assertXattrs(testFile, [:])

#if Foundation
        try self.makeXattr(key: "user.one", value: "uno").write(to: testFile)
#else
        try self.makeXattr(key: "user.one", value: "uno").write(to: FilePath(testFile.path))
#endif
        try self.assertXattrs(testFile, ["user.one": "uno"])

        try self.makeXattr(key: "user.two", value: "dos").write(to: FilePath(testFile.path))
        try self.assertXattrs(testFile, ["user.one": "uno", "user.two": "dos"])

        try self.makeXattr(key: "user.three", value: "tres").write(toPath: testFile.path)
        try self.assertXattrs(testFile, ["user.one": "uno", "user.two": "dos", "user.three": "tres"])

#if Foundation
        try ExtendedAttribute.write(
            [
                .init(key: "user.four", data: "cuatro".data(using: .utf8)!),
                .init(key: "user.five", data: "cinco".data(using: .utf8)!)
            ],
            to: testFile
        )
#else
        try ExtendedAttribute.write(
            [
                .init(key: "user.four", data: "cuatro".data(using: .utf8)!),
                .init(key: "user.five", data: "cinco".data(using: .utf8)!)
            ],
            to: FilePath(testFile.path)
        )
#endif
        try self.assertXattrs(testFile, [
            "user.one": "uno", "user.two": "dos", "user.three": "tres", "user.four": "cuatro", "user.five": "cinco"
        ])

        try ExtendedAttribute.write(
            [
                .init(key: "user.six", data: "seis".data(using: .utf8)!),
                .init(key: "user.seven", data: "siete".data(using: .utf8)!)
            ],
            to: FilePath(testFile.path)
        )
        try self.assertXattrs(testFile, [
            "user.one": "uno", "user.two": "dos", "user.three": "tres", "user.four": "cuatro",
            "user.five": "cinco", "user.six": "seis", "user.seven": "siete"]
        )
        
        try ExtendedAttribute.write(
            [
                .init(key: "user.eight", data: "ocho".data(using: .utf8)!),
                .init(key: "user.nine", data: "nueve".data(using: .utf8)!)
            ],
            toPath: testFile.path
        )
        try self.assertXattrs(
            testFile,
            [
                "user.one": "uno", "user.two": "dos", "user.three": "tres", "user.four": "cuatro", "user.five": "cinco",
                "user.six": "seis", "user.seven": "siete", "user.eight": "ocho", "user.nine": "nueve"
            ]
        )

        let fd = try FileDescriptor.open(FilePath(testFile.path), .writeOnly)
        defer { _ = try? fd.close() }

        try self.makeXattr(key: "user.ten", value: "diez").write(to: fd)
        try self.assertXattrs(
            testFile,
            [
                "user.one": "uno", "user.two": "dos", "user.three": "tres", "user.four": "cuatro", "user.five": "cinco",
                "user.six": "seis", "user.seven": "siete", "user.eight": "ocho", "user.nine": "nueve", "user.ten": "diez"
            ]
        )

        try self.makeXattr(key: "user.eleven", value: "once").write(toFileDescriptor: fd.rawValue)
        try self.assertXattrs(
            testFile,
            [
                "user.one": "uno", "user.two": "dos", "user.three": "tres", "user.four": "cuatro", "user.five": "cinco",
                "user.six": "seis", "user.seven": "siete", "user.eight": "ocho", "user.nine": "nueve", "user.ten": "diez",
                "user.eleven": "once"
            ]
        )
    }

#if canImport(Darwin) // Linux does not allow setting user.xattrs on symlinks
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
#endif

    @Test
    func testRemoveExtendedAttributes() throws {
        let testFile = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try Data().write(to: testFile)
        defer { _ = try? FileManager.default.removeItem(at: testFile) }

        for eachChar in "abcdefghi" {
            let key = "user.\(String(eachChar))"
#if Foundation
            try self.makeXattr(key: key, value: String(eachChar).uppercased()).write(to: testFile)
#else
            try self.makeXattr(key: key, value: String(eachChar).uppercased()).write(toPath: testFile.path)
#endif
        }

        try self.assertXattrs(
            testFile,
            [
                "user.a": "A", "user.b": "B", "user.c": "C", "user.d": "D", "user.e": "E", 
                "user.f": "F", "user.g": "G", "user.h": "H", "user.i": "I"
            ]
        )

#if Foundation
        try ExtendedAttribute.remove(keys: ["user.a", "user.b"], at: testFile)
#else
        try ExtendedAttribute.remove(keys: ["user.a", "user.b"], atPath: testFile.path)
#endif
        try self.assertXattrs(testFile, [
            "user.c": "C", "user.d": "D", "user.e": "E", "user.f": "F", "user.g": "G", "user.h": "H", "user.i": "I"
        ])

        try ExtendedAttribute.remove(keys: ["user.c", "user.d"], at: FilePath(testFile.path))
        try self.assertXattrs(testFile, ["user.e": "E", "user.f": "F", "user.g": "G", "user.h": "H", "user.i": "I"])

        try ExtendedAttribute.remove(keys: ["user.e", "user.f", "user.g"], atPath: testFile.path)
        try self.assertXattrs(testFile, ["user.h": "H", "user.i": "I"])

        let fd = try FileDescriptor.open(FilePath(testFile.path), .writeOnly)
        defer { _ = try? fd.close() }

        try ExtendedAttribute.remove(keys: ["user.h"], at: fd)
        try self.assertXattrs(testFile, ["user.i": "I"])

        try ExtendedAttribute.remove(keys: ["user.i"], atFileDescriptor: fd.rawValue)
        try self.assertXattrs(testFile, [:])
    }

#if canImport(Darwin) // Linux does not allow setting user.xattrs on symlinks
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
#endif

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
                try ExtendedAttribute(at: nonFileURL, key: "user.foo")
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
