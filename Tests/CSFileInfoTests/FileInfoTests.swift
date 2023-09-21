//
//  FileInfoTests.swift
//  
//
//  Created by Charles Srstka on 4/1/23.
//

import CSErrors
@testable import CSFileInfo
import Membership
import System
import XCTest

@available(macOS 13.0, *)
class FileInfoTests: XCTestCase {
    private static let bundle = Bundle(for: FileInfoTests.self)
    private static let fixtureBundle: Bundle = {
        let url = FileInfoTests.bundle.url(forResource: "CSFileInfo_CSFileInfoTests", withExtension: "bundle")!
        return Bundle(url: url)!
    }()

    private func testFixture(name: String, keys: FileInfo.Keys, closure: (FileInfo) throws -> Void) throws {
        let bundle = Self.fixtureBundle

        guard let dataURL = bundle.url(forResource: name, withExtension: "", subdirectory: "fixtures/files") else {
            throw Errno.invalidArgument
        }

        if let metadataURL = bundle.url(forResource: name, withExtension: "", subdirectory: "fixtures/metadata") {
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
            FileInfo(path: url.path, keys: keys),
            FileInfo(path: FilePath(url.path), keys: keys),
            FileInfo(fileDescriptor: fileDescriptor.rawValue, keys: keys),
            FileInfo(fileDescriptor: fileDescriptor, keys: keys)
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

    private func createImage(url: URL, size: UInt64) throws {
        let hdiutil = Process()

        hdiutil.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        hdiutil.arguments = ["create", "-size", "\(size)b", url.path]

        try hdiutil.run()
        hdiutil.waitUntilExit()

        if hdiutil.terminationStatus != 0 {
            throw NSError(domain: "hdiutil", code: Int(hdiutil.terminationStatus), userInfo: nil)
        }
    }

    private func mountImage(url: URL, readOnly: Bool) throws -> (mountPoint: URL, devEntry: String) {
        let hdiutil = Process()
        let pipe = Pipe()

        var args = ["attach", url.path, "-plist"]
        if readOnly {
            args.append("-readonly")
        }

        hdiutil.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        hdiutil.arguments = args
        hdiutil.standardOutput = pipe

        try hdiutil.run()
        let data = try XCTUnwrap(pipe.fileHandleForReading.readToEnd())
        let dict = try XCTUnwrap(PropertyListSerialization.propertyList(from: data, format: nil) as? [String : Any])

        for eachEntity in try XCTUnwrap(dict["system-entities"] as? [[String : Any]]) {
            if let mountPoint = eachEntity["mount-point"] as? String, let devEntry = eachEntity["dev-entry"] as? String {
                return (mountPoint: URL(filePath: mountPoint), devEntry: devEntry)
            }
        }

        throw CocoaError(.fileReadUnknown)
    }

    private func unmountImage(devEntry: String) throws {
        let hdiutil = Process()

        hdiutil.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        hdiutil.arguments = ["detach", devEntry]

        try hdiutil.run()
        hdiutil.waitUntilExit()
    }

    func testImageFixtures() async throws {
        let bundle = Self.fixtureBundle
        let infoURL = bundle.url(forResource: "images", withExtension: "plist", subdirectory: "fixtures/images")!

        for version in [11, 12, 13] {
            try await emulateOSVersionAsync(version) {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for imageInfo in NSArray(contentsOf: infoURL) as! [[String : Any]] {
                        self.testImageFixture(bundle: bundle, imageInfo: imageInfo, group: &group)
                    }
                    
                    try await group.waitForAll()
                }
            }
        }
    }

    private func testImageFixture(bundle: Bundle, imageInfo: [String : Any], group: inout ThrowingTaskGroup<Void, Error>) {
        let name = imageInfo["Name"] as! String
        let imageURL = bundle.url(forResource: name, withExtension: "dmg", subdirectory: "fixtures/images")!
        let files = imageInfo["Files"] as! [[String : Any]]

        group.addTask {
            let (mountPoint: mountPoint, devEntry: devEntry) = try self.mountImage(url: imageURL, readOnly: true)
            defer { _ = try? self.unmountImage(devEntry: devEntry) }
            
            var keys: FileInfo.Keys = [.allCommon, .allFile, .allDirectory]
            keys.remove([
                .fullPath, .noFirmLinkPath, .linkID, .parentID, .cloneID,
                .deviceID, .realDeviceID, .fileSystemID, .realFileSystemID
            ])
            
            for eachFile in files {
                let url = mountPoint.appending(path: eachFile["Path"] as! String)
                var fileKeys = keys
                
                if try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false,
                   !(imageInfo["SupportsAccessTimeForDirectories"] as? Bool ?? false) {
                    fileKeys.remove(.accessTime)
                }
                
                let rawInfo = eachFile["FileInfo"] as! String
                let info = try FileInfo(path: url.path, keys: fileKeys)
                let expectedInfo = try self.getFixtureExpectedInfo(rawInfo: rawInfo, imageInfo: imageInfo)

                try JSONEncoder().encode(info).write(
                    to: FileManager.default.temporaryDirectory.appending(path: url.lastPathComponent)
                )

                XCTAssert(info == expectedInfo, self.diffInfo(info, expect: expectedInfo, imageName: name, url: url))
            }
            
            if imageInfo["SupportsHardLinks"] as? Bool ?? false {
                let hardLinkURL = mountPoint.appending(path: "DirectoryWithAttrs/hardlink")
                let origURL = mountPoint.appending(path: "Directory/PlainFile")
                let hardLinkKeys: FileInfo.Keys = [.inode, .linkID, .persistentID]
                
                let hardLinkInfo = try FileInfo(path: hardLinkURL.path, keys: hardLinkKeys)
                let origInfo = try FileInfo(path: origURL.path, keys: hardLinkKeys)
                
                XCTAssertEqual(hardLinkInfo.inode, origInfo.inode)
                
                if imageInfo["SupportsLinkIDs"] as? Bool ?? false {
                    XCTAssertNotEqual(hardLinkInfo.linkID, origInfo.linkID)
                    XCTAssertNotEqual(hardLinkInfo.persistentID, origInfo.persistentID)
                }
            }
        }
    }

    func testDependentKeys() throws {
        let tempURL = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { _ = try? FileManager.default.removeItem(at: tempURL) }

        try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)

        var info = try FileInfo(path: tempURL.path, keys: [])
        XCTAssertNil(info.objectType)
        XCTAssertNil(info.directoryMountStatus)
        XCTAssertNil(info.path)
        XCTAssertNil(info.pathString)

        info = try FileInfo(path: tempURL.path, keys: .finderInfo)
        XCTAssertEqual(info.objectType, .directory)
        XCTAssertEqual(info.directoryMountStatus, [])
        XCTAssertNil(info.path)
        XCTAssertNil(info.pathString)

        info = try FileInfo(path: tempURL.path, keys: .fullPath)
        XCTAssertEqual(info.objectType, .directory)
        XCTAssertEqual(info.path.flatMap { URL(filePath: $0) }?.standardizedFileURL, tempURL.standardizedFileURL)
        XCTAssertEqual(info.pathString.map { URL(filePath: $0) }?.standardizedFileURL, tempURL.standardizedFileURL)

        info = try FileInfo(path: NSOpenStepRootDirectory(), keys: [])
        XCTAssertNil(info.objectType)
        XCTAssertNil(info.directoryMountStatus)

        info = try FileInfo(path: NSOpenStepRootDirectory(), keys: .finderInfo)
        XCTAssertEqual(info.objectType, .directory)
        XCTAssertEqual(info.directoryMountStatus, .isMountPoint)
    }

    func testOwnershipKeys() throws {
        for version in [11, 12, 13] {
            try emulateOSVersion(version) {
                let tempURL = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
                defer { _ = try? FileManager.default.removeItem(at: tempURL) }
                
                try Data().write(to: tempURL)
                
                let groupCount = getgroups(0, nil)
                let gids = ContiguousArray<gid_t>(unsafeUninitializedCapacity: Int(groupCount)) { buf, count in
                    count = Int(getgroups(groupCount, buf.baseAddress))
                }
                
                let groupUUIDs = try gids.map { gid -> UUID in
                    let ptr = UnsafeMutablePointer<uuid_t>.allocate(capacity: 1)
                    defer { ptr.deallocate() }
                    
                    ptr[0] = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
                    try callPOSIXFunction(expect: .zero) { mbr_gid_to_uuid(gid, ptr) }
                    
                    return UUID(uuid: ptr.pointee)
                }
                
                var info = FileInfo()
                XCTAssertNil(info.ownerID)
                XCTAssertNil(info.groupOwnerID)
                
                info.groupOwnerID = gids[1]
                info.groupOwnerUUID = groupUUIDs[1].uuid
                try info.apply(to: FilePath(tempURL.path))
                XCTAssertEqual(try FileInfo(path: FilePath(tempURL.path), keys: .groupOwnerID).groupOwnerID, gids[1])
                XCTAssertEqual(
                    try FileInfo(path: tempURL.path, keys: .groupOwnerUUID).groupOwnerUUID.map { UUID(uuid: $0) },
                    groupUUIDs[1]
                )
                
                info = FileInfo()
                info.groupOwnerUUID = groupUUIDs[2].uuid
                try info.apply(to: FilePath(tempURL.path))
                XCTAssertEqual(try FileInfo(path: FilePath(tempURL.path), keys: .groupOwnerID).groupOwnerID, gids[1])
                XCTAssertEqual(
                    try FileInfo(path: tempURL.path, keys: .groupOwnerUUID).groupOwnerUUID.map { UUID(uuid: $0) },
                    groupUUIDs[2]
                )
                
                try FileManager.default.removeItem(at: tempURL)
                try Data().write(to: tempURL)
                let handle = try FileHandle(forUpdating: tempURL)
                defer { _ = try? handle.close() }
                
                info = FileInfo()
                info.groupOwnerID = gids[1]
                info.groupOwnerUUID = groupUUIDs[1].uuid
                try info.apply(to: FileDescriptor(rawValue: handle.fileDescriptor))
                XCTAssertEqual(try FileInfo(path: FilePath(tempURL.path), keys: .groupOwnerID).groupOwnerID, gids[1])
                XCTAssertEqual(
                    try FileInfo(path: tempURL.path, keys: .groupOwnerUUID).groupOwnerUUID.map { UUID(uuid: $0) },
                    groupUUIDs[1]
                )
                
                info = FileInfo()
                info.groupOwnerUUID = groupUUIDs[2].uuid
                try info.apply(to: FileDescriptor(rawValue: handle.fileDescriptor))
                XCTAssertEqual(try FileInfo(path: FilePath(tempURL.path), keys: .groupOwnerID).groupOwnerID, gids[1])
                XCTAssertEqual(
                    try FileInfo(path: tempURL.path, keys: .groupOwnerUUID).groupOwnerUUID.map { UUID(uuid: $0) },
                    groupUUIDs[2]
                )
            }
        }
    }

    func testFlagSync() throws {
        var info = FileInfo()
        info.finderInfo = .init(isDirectory: false, finderFlags: .hasBeenInited)
        XCTAssertEqual(info.finderInfo?.finderFlags, .hasBeenInited)

        info.posixFlags = .isHidden
        XCTAssertEqual(info.finderInfo?.finderFlags, [.hasBeenInited, .isInvisible])

        info.posixFlags = [.isHidden, .isOpaque]
        XCTAssertEqual(info.finderInfo?.finderFlags, [.hasBeenInited, .isInvisible])

        info.posixFlags?.remove(.isHidden)
        XCTAssertEqual(info.finderInfo?.finderFlags, .hasBeenInited)

        info.posixFlags?.insert(.isHidden)
        XCTAssertEqual(info.finderInfo?.finderFlags, [.hasBeenInited, .isInvisible])

        info = FileInfo()
        info.finderInfo = .init(isDirectory: false, finderFlags: [])
        info.posixFlags = .isAppendOnly

        info.finderInfo?.finderFlags = .isInvisible
        XCTAssertEqual(info.posixFlags, [.isHidden, .isAppendOnly])

        info.finderInfo?.finderFlags = [.isInvisible, .isAlias]
        XCTAssertEqual(info.posixFlags, [.isHidden, .isAppendOnly])

        info.finderInfo?.finderFlags.remove(.isInvisible)
        XCTAssertEqual(info.posixFlags, .isAppendOnly)

        info.finderInfo?.finderFlags.insert(.isInvisible)
        XCTAssertEqual(info.posixFlags, [.isHidden, .isAppendOnly])
    }

    func testVolumeAttributes() throws {
        let info = try FileInfo(path: NSOpenStepRootDirectory(), keys: .allVolume.subtracting(.volumeDirectoryCount))

        XCTAssertEqual(info.volumeMountPoint, FilePath(NSOpenStepRootDirectory()))
    }

    func testFinderInfo() throws {
        let tempURL = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { _ = try? FileManager.default.removeItem(at: tempURL) }

        try Data().write(to: tempURL)

        let rawFinderInfo = Data([
            0x41, 0x50, 0x50, 0x4c, 0x74, 0x74, 0x78, 0x74, 0x21, 0x40, 0x01, 0x80, 0x00, 0x01, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        ])

        try rawFinderInfo.withUnsafeBytes { buffer in
            _ = try callPOSIXFunction(expect: .zero, path: tempURL.path, isWrite: true) {
                setxattr(tempURL.path, "com.apple.FinderInfo", buffer.baseAddress, buffer.count, 0, 0)
            }
        }

        for eachInfo in try [
            FileInfo(path: tempURL.path, keys: .finderInfo),
            FileInfo(path: FilePath(tempURL.path), keys: .finderInfo)
        ] {
            let finderInfo = try XCTUnwrap(eachInfo.finderInfo)

            XCTAssertEqual(Data(finderInfo.data), rawFinderInfo)
            XCTAssertEqual(finderInfo.type, "APPL")
            XCTAssertEqual(finderInfo.creator, "ttxt")
            XCTAssertTrue(finderInfo.finderFlags.contains(.hasBundle))
            XCTAssertFalse(finderInfo.finderFlags.contains(.hasNoINITs))
            XCTAssertEqual(finderInfo.extendedFinderFlags, [])
        }
    }

    func testWriteFinderInfo() throws {
        let tempFolder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let tempFile = tempFolder.appending(path: UUID().uuidString)
        defer { _ = try? FileManager.default.removeItem(at: tempFolder) }

        try FileManager.default.createDirectory(at: tempFolder, withIntermediateDirectories: true)
        try Data().write(to: tempFile)

        var fileInfo = try FileInfo(path: tempFile.path, keys: .finderInfo)
        var folderInfo = try FileInfo(path: tempFolder.path, keys: .finderInfo)
        XCTAssertNil(fileInfo.finderInfo)
        XCTAssertNil(folderInfo.finderInfo)

        var fileFinderInfo = FileInfo.FinderInfo(objectType: .regular)
        fileFinderInfo.type = "abcd"
        fileFinderInfo.creator = "WXYZ"
        fileFinderInfo.finderFlags = [.isExtensionHidden, .hasCustomIcon]
        fileFinderInfo.finderFlags.labelColor = .red
        fileFinderInfo.extendedFinderFlags = .hasCustomBadge
        fileFinderInfo.putAwayFolderID = 0x12345678
        fileFinderInfo.iconLocation = .init(v: 12345, h: 23456)

        fileInfo.finderInfo = fileFinderInfo
        try fileInfo.apply(toPath: tempFile.path)
        XCTAssertEqual(
            try Data(XCTUnwrap(FileInfo(path: tempFile.path, keys: .finderInfo).finderInfo).data),
            Data([
                0x61, 0x62, 0x63, 0x64, 0x57, 0x58, 0x59, 0x5a, 0x04, 0x1c, 0x30, 0x39, 0x5b, 0xa0, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x12, 0x34, 0x56, 0x78
            ])
        )

        var folderFinderInfo = FileInfo.FinderInfo(objectType: .directory)
        folderFinderInfo.finderFlags = [.hasBundle, .isInvisible]
        folderFinderInfo.finderFlags.labelColor = .orange
        folderFinderInfo.extendedFinderFlags = .hasRoutingInfo
        folderFinderInfo.putAwayFolderID = 0xabcdef01
        folderFinderInfo.iconLocation = .init(v: -12345, h: -23456)
        folderFinderInfo.scrollPosition = .init(v: 13243, h: 24354)
        folderFinderInfo.windowBounds = .init(top: 11223, left: 12334, bottom: 13445, right: 14556)

        folderInfo.finderInfo = folderFinderInfo
        try folderInfo.apply(toPath: tempFolder.path)

        XCTAssertEqual(
            try Data(XCTUnwrap(FileInfo(path: tempFolder.path, keys: .finderInfo).finderInfo).data),
            Data([
                0x2b, 0xd7, 0x30, 0x2e, 0x34, 0x85, 0x38, 0xdc, 0x60, 0x0e, 0xcf, 0xc7, 0xa4, 0x60, 0x00, 0x00,
                0x33, 0xbb, 0x5f, 0x22, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0xab, 0xcd, 0xef, 0x01
            ])
        )
    }

    func testWriteSecurityInfo() throws {
        for version in [11, 12, 13] {
            try emulateOSVersion(version) {
                let tempFile = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
                defer { _ = try? FileManager.default.removeItem(at: tempFile) }
                
                try Data().write(to: tempFile)
                
                var info = try FileInfo(path: tempFile.path, keys: [])
                info.permissionsMode = 0o770
                
                var entry = AccessControlList.Entry()
                entry.owner = .user(.init(id: getuid()))
                entry.rule = .allow
                entry.permissions = .appendData
                
                info.accessControlList = AccessControlList([entry])
                
                try info.apply(toPath: tempFile.path)
                
                let newInfo = try FileInfo(path: tempFile.path, keys: [.accessControlList, .permissionsMode])
                XCTAssertEqual(newInfo.permissionsMode, info.permissionsMode)
                XCTAssertEqual(newInfo.accessControlList, info.accessControlList)
            }
        }
    }

    func testWriteVolumeName() throws {
        let imageURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString
        ).appendingPathExtension("dmg")

        defer { _ = try? FileManager.default.removeItem(at: imageURL) }

        try self.createImage(url: imageURL, size: 10 * 1024)

        let (mountPoint: mountPoint, devEntry: devEntry) = try self.mountImage(url: imageURL, readOnly: false)
        defer { _ = try? self.unmountImage(devEntry: devEntry) }

        var info = try FileInfo(path: mountPoint.path, keys: .volumeName)

        let newName = UUID().uuidString
        info.volumeName = newName

        let volUUID = try XCTUnwrap(mountPoint.resourceValues(forKeys: [.volumeUUIDStringKey]).volumeUUIDString)

        try info.apply(toPath: mountPoint.path)
        let newMountPoint = mountPoint.deletingLastPathComponent().appending(path: newName)

        for _ in 0..<30 where (try? mountPoint.checkResourceIsReachable()) ?? false {
            sleep(1)
        }

        XCTAssertThrowsError(try mountPoint.checkResourceIsReachable()) {
            XCTAssertEqual(($0 as? CocoaError)?.code, .fileReadNoSuchFile)
        }

        let newResourceValues = try newMountPoint.resourceValues(forKeys: [.volumeNameKey, .volumeUUIDStringKey])
        XCTAssertEqual(newResourceValues.volumeUUIDString, volUUID)
        XCTAssertEqual(newResourceValues.volumeName, newName)
    }

    private func getFixtureExpectedInfo(rawInfo: String, imageInfo: [String : Any]) throws -> FileInfo {
        var info = try JSONDecoder().decode(FileInfo.self, from: rawInfo.data(using: .utf8)!)

        if !((imageInfo["SupportsTimeZones"] as? Bool) ?? false) {
            let keyPaths: [WritableKeyPath<FileInfo, timespec?>] = [
                \.accessTime,
                \.attributeModificationTime,
                \.creationTime,
                \.modificationTime
            ]

            for eachKeyPath in keyPaths {
                if var time = info[keyPath: eachKeyPath] {
                    let timeInterval = TimeInterval(time.tv_sec) + TimeInterval(time.tv_nsec) / TimeInterval(NSEC_PER_SEC)
                    time.tv_sec += TimeZone.current.secondsFromGMT(for: Date(timeIntervalSince1970: timeInterval))

                    info[keyPath: eachKeyPath] = time
                }
            }
        }

        return info
    }

    private func diffInfo(_ info: FileInfo, expect expectedInfo: FileInfo, imageName: String, url: URL) -> String {
        do {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = .sortedKeys

            let plist = try PropertyListEncoder().encode(info)
            let expectedPlist = try PropertyListEncoder().encode(expectedInfo)

            guard let dict = try PropertyListSerialization.propertyList(from: plist, format: nil) as? [String : AnyHashable],
                  let expectedDict = try PropertyListSerialization.propertyList(
                    from: expectedPlist,
                    format: nil
                  ) as? [String : AnyHashable] else {
                throw CocoaError(.fileReadCorruptFile)
            }

            func compare<T: Equatable>(_ v1: T, _ v2: Any) -> Bool { v2 as? T == v1 }

            return "\(imageName), \(url.path): " + dict.sorted(by: { $0.key < $1.key }).compactMap { key, value in
                guard let expectedValue = expectedDict[key] else { return "Missing on right: \(key)" }

                if compare(value, expectedValue) {
                    return nil
                }

                return "Mismatch for \(key): got \(String(describing: value)), expected \(String(describing: expectedValue))"
            }.joined(separator: "\n")
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
}
