//
//  FileInfoFixtureTests.swift
//
//
//  Created by Charles Srstka on 10/28/23.
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

struct FileFixture: CustomTestStringConvertible, Sendable {
    let name: String
    let isDirectory: Bool

    var keys: FileInfo.Keys { [.allCommon, self.isDirectory ? .allDirectory : .allFile] }
    var testDescription: String { self.name }

    func testFileInfo(closure: (FileInfo) throws -> Void) throws {
        try self.withURL { url in
            let fileDescriptor = try FileDescriptor.open(FilePath(url.path), .readOnly)
            defer { _ = try? fileDescriptor.close() }

            for eachInfo in try [
                FileInfo(atPath: url.path, keys: self.keys),
                FileInfo(at: FilePath(url.path), keys: self.keys),
                FileInfo(atFileDescriptor: fileDescriptor.rawValue, keys: self.keys),
                FileInfo(at: fileDescriptor, keys: self.keys)
            ] {
                if self.keys.contains(.filename) {
                    #expect(eachInfo.filename == url.lastPathComponent)
                }

                if self.keys.contains(.fullPath) {
                    let hint: URL.DirectoryHint = self.isDirectory ? .isDirectory : .notDirectory

                    #expect(eachInfo.path.flatMap { URL(filePath: $0, directoryHint: hint)?.standardizedFileURL } == url)
                    #expect(eachInfo.pathString.map { URL(filePath: $0, directoryHint: hint).standardizedFileURL } == url)
                }

                try closure(eachInfo)
            }
        }
    }

    private func withURL(closure: (URL) throws -> Void) throws {
        guard let dataURL = Bundle.module.url(forResource: name, withExtension: "", subdirectory: "fixtures/files") else {
            throw Errno.invalidArgument
        }

        if let metadataURL = Bundle.module.url(forResource: name, withExtension: "", subdirectory: "fixtures/metadata") {
            let hint: URL.DirectoryHint = isDirectory ? .isDirectory : .notDirectory
            let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: hint)

            try FileManager.default.copyItem(at: dataURL, to: url)
            defer { try? FileManager.default.removeItem(at: url) }

            try callPOSIXFunction(expect: .zero, path: dataURL.path, isWrite: true) {
                metadataURL.withUnsafeFileSystemRepresentation { srcPath in
                    url.withUnsafeFileSystemRepresentation { dstPath in
                        copyfile(srcPath, dstPath, nil, UInt32(bitPattern: COPYFILE_METADATA | COPYFILE_UNPACK))
                    }
                }
            }

            try closure(url)
        } else {
            try closure(dataURL)
        }
    }

    static let all = [
        FileFixture(name: "SillyBalls", isDirectory: false),
        FileFixture(name: "FileWithACL", isDirectory: false),
        FileFixture(name: "Directory", isDirectory: true),
        FileFixture(name: "DirectoryWithAttrs", isDirectory: true)
    ]
}

@Test(arguments: FileFixture.all)
func testFixture(fixture: FileFixture) throws {
    try fixture.testFileInfo { info in
        switch fixture.name {
        case "SillyBalls":
            let dataPhysicalSize = try #require(info.fileDataForkPhysicalSize)
            let rsrcPhysicalSize = try #require(info.fileResourceForkPhysicalSize)

            #expect(info.objectType == .regular)
            #expect(info.script == 0x7e)
            #expect(info.finderInfo?.type == "APPL")
            #expect(info.finderInfo?.creator == "abcd")
            #expect(info.ownerID == getuid())
            #expect(info.groupOwnerID == getgid())
            #expect(info.permissionsMode == 0o644)
            #expect(info.fileDataForkLogicalSize == 2508)
            #expect(dataPhysicalSize >= 2508)
            #expect(info.fileResourceForkLogicalSize == 436)
            #expect(rsrcPhysicalSize >= 436)
            #expect(info.fileTotalLogicalSize == 2944)
            #expect(info.fileTotalPhysicalSize == dataPhysicalSize + rsrcPhysicalSize)
        case "FileWithACL":
            #expect(info.objectType == .regular)
            #expect(info.ownerID == getuid())
            #expect(info.groupOwnerID == getgid())
            #expect(info.permissionsMode == 0o644)
            #expect(info.fileDataForkLogicalSize == 14)
            #expect(info.fileResourceForkLogicalSize == 0)
            #expect(info.fileResourceForkPhysicalSize == 0)
            #expect(info.fileTotalLogicalSize == 14)
            #expect(info.fileTotalPhysicalSize == info.fileDataForkPhysicalSize)

            let acl = try #require(info.accessControlList)

            #expect(acl.count == 2)
            #expect(acl[0].rule == .allow)
            #expect(acl[0].owner == .user(.init(id: 501)))
            #expect(acl[0].permissions == .readSecurity)
            #expect(acl[0].flags == .limitInheritance)
            #expect(acl[1].rule == .deny)
            #expect(acl[1].owner == .group(.init(id: 20)))
            #expect(acl[1].permissions == .writeAttributes)
            #expect(acl[1].flags == .inheritToDirectories)
        case "Directory":
            #expect(info.objectType == .directory)
            #expect(info.ownerID == getuid())
            #expect(info.groupOwnerID == getgid())
            #expect(info.permissionsMode == 0o755)
            #expect(info.finderInfo == nil)
        case "DirectoryWithAttrs":
            #expect(info.objectType == .directory)
            #expect(info.ownerID == getuid())
            #expect(info.groupOwnerID == getgid())
            #expect(info.permissionsMode == 0o755)
            #expect(info.finderInfo?.type == "fold")
            #expect(info.finderInfo?.creator == "MACS")
            #expect(info.finderInfo?.windowBounds == .init(top: 0x0102, left: 0x0304, bottom: 0x0506, right: 0x0708))
            #expect(info.finderInfo?.finderFlags.contains(.hasBundle) == true)
            #expect(info.finderInfo?.finderFlags.contains(.isNameLocked) == false)
            #expect(info.finderInfo?.finderFlags.labelColor == .blue)
            #expect(info.finderInfo?.iconLocation == .init(v: 0x0a0b, h: 0x0c0d))
            #expect(info.finderInfo?.scrollPosition == .init(v: 0x0f0e, h: 0x0d0c))
            #expect(info.finderInfo?.extendedFinderFlags == [.hasCustomBadge, .hasRoutingInfo])
            #expect(info.finderInfo?.putAwayFolderID == 0x04030201)
        default:
            fatalError("invalid fixture name")
        }
    }
}
