//
//  FileInfoFixtureTests.swift
//
//
//  Created by Charles Srstka on 10/28/23.
//

@testable import CSFileInfo
import CSErrors
import System
import XCTest

final class FileInfoFixtureTests: XCTestCase {
    private struct ImageFixture: Sendable {
        struct Info: Codable, Sendable {
            struct File: Codable, Sendable {
                let path: String
                let fileInfo: FileInfo
            }

            let name: String

            let supportsHardLinks: Bool
            let supportsLinkIDs: Bool
            let supportsTimeZones: Bool

            let files: [File]
        }

        let mountPoint: URL
        let devEntry: String
        let info: Info
    }

    private var imageFixtures: [ImageFixture] = []

    override func setUp() async throws {
        try await super.setUp()

        let bundle = Bundle.module
        guard let infoURL = bundle.url(forResource: "images", withExtension: "plist", subdirectory: "fixtures/images") else {
            throw CocoaError(.fileNoSuchFile)
        }

        let dmgHelper = DiskImageHelper.shared

        for imageInfo in try PropertyListDecoder().decode([ImageFixture.Info].self, from: Data(contentsOf: infoURL)) {
            let name = imageInfo.name
            guard let imageURL = bundle.url(forResource: name, withExtension: "dmg", subdirectory: "fixtures/images") else {
                throw CocoaError(.fileNoSuchFile)
            }

            let (mountPoint: mountPoint, devEntry: devEntry) = try dmgHelper.mountImage(url: imageURL, readOnly: true)

            self.imageFixtures.append(ImageFixture(mountPoint: mountPoint, devEntry: devEntry, info: imageInfo))
        }
    }

    override func tearDown() async throws {
        try await super.tearDown()

        for eachFixture in self.imageFixtures {
            try DiskImageHelper.shared.unmountImage(devEntry: eachFixture.devEntry)
        }
    }

    func testFixtures() throws {
        try self.testFixture(name: "SillyBalls", keys: [.allCommon, .allFile]) { info in
            XCTAssertEqual(info.objectType, .regular)
            XCTAssertEqual(info.script, 0x7e)
            XCTAssertEqual(info.finderInfo?.type, "APPL")
            XCTAssertEqual(info.finderInfo?.creator, "abcd")
            XCTAssertEqual(info.ownerID, getuid())
            XCTAssertEqual(info.groupOwnerID, getgid())
            XCTAssertEqual(info.permissionsMode, 0o644)
            XCTAssertEqual(info.fileDataForkLogicalSize, 2508)
            XCTAssertGreaterThanOrEqual(info.fileDataForkPhysicalSize ?? 0, 2508)
            XCTAssertEqual(info.fileResourceForkLogicalSize, 436)
            XCTAssertGreaterThanOrEqual(info.fileResourceForkPhysicalSize ?? 0, 436)
            XCTAssertEqual(info.fileTotalLogicalSize, 2944)
            XCTAssertEqual(
                info.fileTotalPhysicalSize,
                (info.fileDataForkPhysicalSize ?? 0) + (info.fileResourceForkPhysicalSize ?? 0)
            )
        }

        try self.testFixture(name: "FileWithACL", keys: [.allCommon, .allFile]) { info in
            XCTAssertEqual(info.objectType, .regular)
            XCTAssertEqual(info.ownerID, getuid())
            XCTAssertEqual(info.groupOwnerID, getgid())
            XCTAssertEqual(info.permissionsMode, 0o644)
            XCTAssertEqual(info.fileDataForkLogicalSize, 14)
            XCTAssertEqual(info.fileResourceForkLogicalSize, 0)
            XCTAssertEqual(info.fileResourceForkPhysicalSize, 0)
            XCTAssertEqual(info.fileTotalLogicalSize, 14)
            XCTAssertEqual(info.fileTotalPhysicalSize, info.fileDataForkPhysicalSize)

            guard let acl = info.accessControlList else {
                XCTFail("No access control list for TestWithACL")
                return
            }

            XCTAssertEqual(acl.count, 2)
            XCTAssertEqual(acl[0].rule, .allow)
            XCTAssertEqual(acl[0].owner, .user(.init(id: 501)))
            XCTAssertEqual(acl[0].permissions, .readSecurity)
            XCTAssertEqual(acl[0].flags, .limitInheritance)
            XCTAssertEqual(acl[1].rule, .deny)
            XCTAssertEqual(acl[1].owner, .group(.init(id: 20)))
            XCTAssertEqual(acl[1].permissions, .writeAttributes)
            XCTAssertEqual(acl[1].flags, .inheritToDirectories)
        }

        try self.testFixture(name: "Directory", keys: [.allCommon, .allDirectory]) { info in
            XCTAssertEqual(info.objectType, .directory)
            XCTAssertEqual(info.ownerID, getuid())
            XCTAssertEqual(info.groupOwnerID, getgid())
            XCTAssertEqual(info.permissionsMode, 0o755)
            XCTAssertNil(info.finderInfo)
        }

        try self.testFixture(name: "DirectoryWithAttrs", keys: [.allCommon, .allDirectory]) { info in
            XCTAssertEqual(info.objectType, .directory)
            XCTAssertEqual(info.ownerID, getuid())
            XCTAssertEqual(info.groupOwnerID, getgid())
            XCTAssertEqual(info.permissionsMode, 0o755)
            XCTAssertEqual(info.finderInfo?.type, "fold")
            XCTAssertEqual(info.finderInfo?.creator, "MACS")
            XCTAssertEqual(info.finderInfo?.windowBounds, .init(top: 0x0102, left: 0x0304, bottom: 0x0506, right: 0x0708))
            XCTAssertTrue(info.finderInfo?.finderFlags.contains(.hasBundle) ?? false)
            XCTAssertFalse(info.finderInfo?.finderFlags.contains(.isNameLocked) ?? true)
            XCTAssertEqual(info.finderInfo?.finderFlags.labelColor, .blue)
            XCTAssertEqual(info.finderInfo?.iconLocation, .init(v: 0x0a0b, h: 0x0c0d))
            XCTAssertEqual(info.finderInfo?.scrollPosition, .init(v: 0x0f0e, h: 0x0d0c))
            XCTAssertEqual(info.finderInfo?.extendedFinderFlags, [.hasCustomBadge, .hasRoutingInfo])
            XCTAssertEqual(info.finderInfo?.putAwayFolderID, 0x04030201)
        }
    }

    func testImageFixtures() async throws {
        for version in [11, 12, 13] {
            try await emulateOSVersionAsync(version) {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for eachFixture in self.imageFixtures {
                        group.addTask {
                            try await Self.testImageFixture(eachFixture)
                        }
                    }

                    try await group.waitForAll()
                }
            }
        }
    }

    private func testFixture(name: String, keys: FileInfo.Keys, closure: (FileInfo) throws -> Void) throws {
        guard let dataURL = Bundle.module.url(forResource: name, withExtension: "", subdirectory: "fixtures/files") else {
            throw Errno.invalidArgument
        }

        if let metadataURL = Bundle.module.url(forResource: name, withExtension: "", subdirectory: "fixtures/metadata") {
            let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            defer { _ = try? FileManager.default.removeItem(at: url) }

            try FileManager.default.copyItem(at: dataURL, to: url)

            try callPOSIXFunction(expect: .zero, path: dataURL.path, isWrite: true) {
                metadataURL.withUnsafeFileSystemRepresentation { srcPath in
                    url.withUnsafeFileSystemRepresentation { dstPath in
                        copyfile(srcPath, dstPath, nil, UInt32(bitPattern: COPYFILE_METADATA | COPYFILE_UNPACK))
                    }
                }
            }

            try self.testFixture(at: url, keys: keys, closure: closure)
        } else {
            try self.testFixture(at: dataURL, keys: keys, closure: closure)
        }
    }

    private func testFixture(at url: URL, keys: FileInfo.Keys, closure: (FileInfo) throws -> Void) throws {
        let fileDescriptor = try FileDescriptor.open(FilePath(url.path), .readOnly)
        defer { _ = try? fileDescriptor.close() }

        for eachInfo in try [
            FileInfo(atPath: url.path, keys: keys),
            FileInfo(at: FilePath(url.path), keys: keys),
            FileInfo(atFileDescriptor: fileDescriptor.rawValue, keys: keys),
            FileInfo(at: fileDescriptor, keys: keys)
        ] {
            if keys.contains(.filename) {
                XCTAssertEqual(eachInfo.filename, url.lastPathComponent)
            }

            if keys.contains(.fullPath) {
                XCTAssertEqual(eachInfo.path.flatMap { URL(filePath: $0)?.standardizedFileURL }, url.standardizedFileURL)
                XCTAssertEqual(eachInfo.pathString.map { URL(filePath: $0).standardizedFileURL }, url.standardizedFileURL)
            }

            try closure(eachInfo)
        }
    }

    private static func testImageFixture(_ fixture: ImageFixture) async throws {
        var keys: FileInfo.Keys = [.allCommon, .allFile, .allDirectory]
        keys.remove([
            .fullPath, .noFirmLinkPath, .linkID, .parentID, .cloneID,
            .deviceID, .realDeviceID, .fileSystemID, .realFileSystemID
        ])

        let mountPoint = fixture.mountPoint
        let imageInfo = fixture.info

        for eachFile in imageInfo.files {
            let url = mountPoint.appending(path: eachFile.path)

            let fileInfo = try FileInfo(atPath: url.path, keys: keys)
            let expectedFileInfo = self.getExpectedInfo(file: eachFile, imageInfo: imageInfo)

            let infoJSON = try JSONEncoder().encode(fileInfo)
            let expectedJSON = try JSONEncoder().encode(expectedFileInfo)

            var infoDict = try XCTUnwrap(JSONSerialization.jsonObject(with: infoJSON) as? [String : AnyHashable])
            let expectedDict = try XCTUnwrap(JSONSerialization.jsonObject(with: expectedJSON) as? [String : AnyHashable])

            for eachKey in infoDict.keys {
                if expectedDict[eachKey] == nil {
                    infoDict[eachKey] = nil
                }
            }

            XCTAssert(
                infoDict == expectedDict,
                self.diffInfo(infoDict, expect: expectedDict, imageName: imageInfo.name, url: url)
            )
        }

        if imageInfo.supportsHardLinks {
            let hardLinkURL = mountPoint.appending(path: "DirectoryWithAttrs/hardlink")
            let origURL = mountPoint.appending(path: "Directory/PlainFile")
            let hardLinkKeys: FileInfo.Keys = [.inode, .linkID, .persistentID]

            let hardLinkInfo = try FileInfo(atPath: hardLinkURL.path, keys: hardLinkKeys)
            let origInfo = try FileInfo(atPath: origURL.path, keys: hardLinkKeys)

            XCTAssertEqual(hardLinkInfo.inode, origInfo.inode)

            if imageInfo.supportsLinkIDs {
                XCTAssertNotEqual(hardLinkInfo.linkID, origInfo.linkID)
                XCTAssertNotEqual(hardLinkInfo.persistentID, origInfo.persistentID)
            }
        }
    }

    private static func getExpectedInfo(file: ImageFixture.Info.File, imageInfo: ImageFixture.Info) -> FileInfo {
        var info = file.fileInfo

        if !imageInfo.supportsTimeZones {
            let keyPaths: [WritableKeyPath<FileInfo, timespec?>] = [
                \.accessTime,
                \.attributeModificationTime,
                \.creationTime,
                \.modificationTime
            ]

            for eachKeyPath in keyPaths {
                if var time = info[keyPath: eachKeyPath] {
                    let timeInterval = TimeInterval(time.tv_sec) + TimeInterval(time.tv_nsec) / TimeInterval(NSEC_PER_SEC)
                    let thenFromGMT = TimeZone.current.secondsFromGMT(for: Date(timeIntervalSince1970: timeInterval))
                    let nowFromGMT = TimeZone.current.secondsFromGMT(for: Date())

                    time.tv_sec += thenFromGMT + (thenFromGMT - nowFromGMT)

                    info[keyPath: eachKeyPath] = time
                }
            }
        }

        return info
    }

    private static func diffInfo(
        _ info: [String : AnyHashable],
        expect expectedInfo: [String : AnyHashable],
        imageName: String,
        url: URL
    ) -> String {
        func compare<T: Equatable>(_ v1: T, _ v2: Any) -> Bool { v2 as? T == v1 }

        return "\(imageName), \(url.path): " + info.sorted(by: { $0.key < $1.key }).compactMap { key, value in
            guard let expectedValue = expectedInfo[key] else { return "Missing on right: \(key)" }

            if compare(value, expectedValue) {
                return nil
            }

            return "Mismatch for \(key): got \(String(describing: value)), expected \(String(describing: expectedValue))"
        }.joined(separator: "\n")
    }
}
