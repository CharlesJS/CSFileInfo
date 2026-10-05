//
//  FileInfoTests.swift
//  
//
//  Created by Charles Srstka on 4/1/23.
//

import CSErrors
@testable import CSFileInfo
import CSFileInfo_CShims
import DiskImageHelper
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

private let osVersions = [10, 11, 12, 13, .max]

@Suite
struct FileInfoReadOnlyTests {
#if canImport(Darwin)
    @Test(arguments: osVersions)
    func testOSVersions(version: Int) throws {
        try emulateOSVersion(version) {
            try self.testVolumeAttributes()
            try self.testDependentKeys()
            try self.testOwnershipKeys()
            try self.testFlagSync()
            try self.testFinderInfo()
        }
    }

    @Test
    func testDependentKeys() throws {
        let tempURL = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        defer { _ = try? FileManager.default.removeItem(at: tempURL) }

        try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)

        var info = try FileInfo(atPath: tempURL.path, keys: [])
        #expect(info.objectType == nil)
        #expect(info.directoryMountStatus == nil)
        #expect(info.path == nil)
        #expect(info.pathString == nil)

        info = try FileInfo(atPath: tempURL.path, keys: .finderInfo)
        #expect(info.objectType == .directory)
        #expect(info.directoryMountStatus == [])
        #expect(info.path == nil)
        #expect(info.pathString == nil)

        info = try FileInfo(atPath: tempURL.path, keys: .fullPath)
        #expect(info.objectType == .directory)
        #expect(info.path.flatMap { URL(filePath: $0, directoryHint: .isDirectory) }?.standardizedFileURL == tempURL)
        #expect(info.pathString.map { URL(filePath: $0, directoryHint: .isDirectory) }?.standardizedFileURL == tempURL)

        info = try FileInfo(atPath: NSOpenStepRootDirectory(), keys: [])
        #expect(info.objectType == nil)
        #expect(info.directoryMountStatus == nil)

        info = try FileInfo(atPath: NSOpenStepRootDirectory(), keys: .finderInfo)
        #expect(info.objectType == .directory)
        #expect(info.directoryMountStatus == .isMountPoint)
    }

    @Test
    func testOwnershipKeys() throws {
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
        #expect(info.ownerID == nil)
        #expect(info.groupOwnerID == nil)

        info.groupOwnerID = gids[1]
        info.groupOwnerUUID = groupUUIDs[1].uuid
        try info.apply(to: FilePath(tempURL.path))
        #expect(try FileInfo(at: FilePath(tempURL.path), keys: .groupOwnerID).groupOwnerID == gids[1])
        #expect(
            try FileInfo(atPath: tempURL.path, keys: .groupOwnerUUID).groupOwnerUUID.map { UUID(uuid: $0) } == groupUUIDs[1]
        )

        info = FileInfo()
        info.groupOwnerUUID = groupUUIDs[2].uuid
        try info.apply(to: FilePath(tempURL.path))
        #expect(try FileInfo(at: FilePath(tempURL.path), keys: .groupOwnerID).groupOwnerID == gids[1])
        #expect(
            try FileInfo(atPath: tempURL.path, keys: .groupOwnerUUID).groupOwnerUUID.map { UUID(uuid: $0) } == groupUUIDs[2]
        )

        try FileManager.default.removeItem(at: tempURL)
        try Data().write(to: tempURL)
        let handle = try FileHandle(forUpdating: tempURL)
        defer { _ = try? handle.close() }

        info = FileInfo()
        info.groupOwnerID = gids[1]
        info.groupOwnerUUID = groupUUIDs[1].uuid
        try info.apply(to: FileDescriptor(rawValue: handle.fileDescriptor))
        #expect(try FileInfo(at: FilePath(tempURL.path), keys: .groupOwnerID).groupOwnerID == gids[1])
        #expect(
            try FileInfo(atPath: tempURL.path, keys: .groupOwnerUUID).groupOwnerUUID.map { UUID(uuid: $0) } == groupUUIDs[1]
        )

        info = FileInfo()
        info.groupOwnerUUID = groupUUIDs[2].uuid
        try info.apply(to: FileDescriptor(rawValue: handle.fileDescriptor))
        #expect(try FileInfo(at: FilePath(tempURL.path), keys: .groupOwnerID).groupOwnerID == gids[1])
        #expect(
            try FileInfo(atPath: tempURL.path, keys: .groupOwnerUUID).groupOwnerUUID.map { UUID(uuid: $0) } == groupUUIDs[2]
        )
    }

    @Test
    func testFlagSync() throws {
        var info = FileInfo()
        info.finderInfo = .init(isDirectory: false, finderFlags: .hasBeenInited)
        #expect(info.finderInfo?.finderFlags == .hasBeenInited)

        info.posixFlags = .isHidden
        #expect(info.finderInfo?.finderFlags == [.hasBeenInited, .isInvisible])

        info.posixFlags = [.isHidden, .isOpaque]
        #expect(info.finderInfo?.finderFlags == [.hasBeenInited, .isInvisible])

        info.posixFlags?.remove(.isHidden)
        #expect(info.finderInfo?.finderFlags == .hasBeenInited)

        info.posixFlags?.insert(.isHidden)
        #expect(info.finderInfo?.finderFlags == [.hasBeenInited, .isInvisible])

        info = FileInfo()
        info.finderInfo = .init(isDirectory: false, finderFlags: [])
        info.posixFlags = .isAppendOnly

        info.finderInfo?.finderFlags = .isInvisible
        #expect(info.posixFlags == [.isHidden, .isAppendOnly])

        info.finderInfo?.finderFlags = [.isInvisible, .isAlias]
        #expect(info.posixFlags == [.isHidden, .isAppendOnly])

        info.finderInfo?.finderFlags.remove(.isInvisible)
        #expect(info.posixFlags == .isAppendOnly)

        info.finderInfo?.finderFlags.insert(.isInvisible)
        #expect(info.posixFlags == [.isHidden, .isAppendOnly])
    }

    @Test
    func testVolumeAttributes() throws {
        let rootPath = NSOpenStepRootDirectory()

        var infos = [
            try FileInfo(at: FilePath(rootPath), keys: .allVolume.subtracting(.volumeDirectoryCount)),
            try FileInfo(atPath: rootPath, keys: .allVolume.subtracting(.volumeDirectoryCount))
        ]

#if Foundation
        infos.append(
            try FileInfo(at: URL(filePath: rootPath), keys: .allVolume.subtracting(.volumeDirectoryCount))
        )
#endif

        for info in infos {
            #expect(info.volumeMountPoint == FilePath(rootPath))
        }
    }

    @Test
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

        var infos = try [
            FileInfo(atPath: tempURL.path, keys: .finderInfo),
            FileInfo(at: FilePath(tempURL.path), keys: .finderInfo)
        ]

#if Foundation
        infos.append(try FileInfo(at: tempURL, keys: .finderInfo))
#endif

        for eachInfo in infos {
            let finderInfo = try #require(eachInfo.finderInfo)

            #expect(Data(finderInfo.data) == rawFinderInfo)
            #expect(finderInfo.type == "APPL")
            #expect(finderInfo.creator == "ttxt")
            #expect(finderInfo.finderFlags.contains(.hasBundle) == true)
            #expect(finderInfo.finderFlags.contains(.hasNoINITs) == false)
            #expect(finderInfo.extendedFinderFlags == [])
        }
    }
#endif
}

@Suite(.serialized)
struct FileInfoReadWriteTests {
#if canImport(Darwin)
    @Test(.serialized, arguments: osVersions)
    func testOSVersions(version: Int) throws {
        try emulateOSVersion(version) {
            try self.testWriteSecurityInfo()
            try self.testWriteVolumeName()

            try self.testWriteFinderInfo()
        }
    }
#endif

#if canImport(Darwin)
    @Test
    func testWriteFinderInfo() throws {
        var appliers: [(FileInfo, URL) throws -> Void] = [
            { try $0.apply(to: FilePath($1.path)) },
            { try $0.apply(toPath: $1.path) }
        ]

#if Foundation
        appliers.append({ try $0.apply(to: $1) })
#endif

        var fileFinderInfo = FileInfo.FinderInfo(objectType: .regular)
        fileFinderInfo.type = "abcd"
        fileFinderInfo.creator = "WXYZ"
        fileFinderInfo.finderFlags = [.isExtensionHidden, .hasCustomIcon]
        fileFinderInfo.finderFlags.labelColor = .red
        fileFinderInfo.extendedFinderFlags = .hasCustomBadge
        fileFinderInfo.putAwayFolderID = 0x12345678
        fileFinderInfo.iconLocation = .init(v: 12345, h: 23456)

        for applier in appliers {
            let tempFile = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            try Data().write(to: tempFile)
            defer { _ = try? FileManager.default.removeItem(at: tempFile) }

            var fileInfo = try FileInfo(atPath: tempFile.path, keys: .finderInfo)
            #expect(fileInfo.finderInfo == nil)

            fileInfo.finderInfo = fileFinderInfo
            try applier(fileInfo, tempFile)

            #expect(
                try Data(#require(FileInfo(atPath: tempFile.path, keys: .finderInfo).finderInfo).data) == Data([
                    0x61, 0x62, 0x63, 0x64, 0x57, 0x58, 0x59, 0x5a, 0x04, 0x1c, 0x30, 0x39, 0x5b, 0xa0, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x12, 0x34, 0x56, 0x78
                ])
            )
        }

        var folderFinderInfo = FileInfo.FinderInfo(objectType: .directory)
        folderFinderInfo.finderFlags = [.hasBundle, .isInvisible]
        folderFinderInfo.finderFlags.labelColor = .orange
        folderFinderInfo.extendedFinderFlags = .hasRoutingInfo
        folderFinderInfo.putAwayFolderID = 0xabcdef01
        folderFinderInfo.iconLocation = .init(v: -12345, h: -23456)
        folderFinderInfo.scrollPosition = .init(v: 13243, h: 24354)
        folderFinderInfo.windowBounds = .init(top: 11223, left: 12334, bottom: 13445, right: 14556)

        for applier in appliers {
            let tempFolder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            defer { _ = try? FileManager.default.removeItem(at: tempFolder) }

            try FileManager.default.createDirectory(at: tempFolder, withIntermediateDirectories: true)
            var folderInfo = try FileInfo(atPath: tempFolder.path, keys: .finderInfo)
            #expect(folderInfo.finderInfo == nil)

            folderInfo.finderInfo = folderFinderInfo
            try applier(folderInfo, tempFolder)

            #expect(
                try Data(#require(FileInfo(atPath: tempFolder.path, keys: .finderInfo).finderInfo).data) == Data([
                    0x2b, 0xd7, 0x30, 0x2e, 0x34, 0x85, 0x38, 0xdc, 0x60, 0x0e, 0xcf, 0xc7, 0xa4, 0x60, 0x00, 0x00,
                    0x33, 0xbb, 0x5f, 0x22, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0xab, 0xcd, 0xef, 0x01
                ])
            )
        }
    }
#endif

    @Test
    func testWriteSecurityInfo() throws {
#if canImport(Darwin)
        var appliers: [(FileInfo, URL) throws -> Void] = [
            { try $0.apply(to: FilePath($1.path)) },
            { try $0.apply(toPath: $1.path) }
        ]

#if Foundation
        appliers.append({ try $0.apply(to: $1) })
#endif
        
        for applier in appliers {
            let tempFile = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            defer { _ = try? FileManager.default.removeItem(at: tempFile) }

            try Data().write(to: tempFile)

            var info = try FileInfo(atPath: tempFile.path, keys: [])
            info.permissionsMode = 0o770

            var entry = AccessControlList.Entry()
            entry.owner = .user(.init(id: getuid()))
            entry.rule = .allow
            entry.permissions = .appendData

            info.accessControlList = AccessControlList([entry])

            try applier(info, tempFile)

            let newInfo = try FileInfo(atPath: tempFile.path, keys: [.accessControlList, .permissionsMode])
            #expect(newInfo.permissionsMode == info.permissionsMode)
            #expect(newInfo.accessControlList == info.accessControlList)
        }
#endif
    }

    @Test
    func testWriteVolumeName() throws {
#if canImport(Darwin)
        let dmgHelper = DiskImageHelper.shared

        let imageURL = try dmgHelper.createDiskImage(
            at: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString).appendingPathExtension("dmg"),
            size: 10 * 1024,
            fileSystem: .apfs
        )

        defer { _ = try? FileManager.default.removeItem(at: imageURL) }

        var appliers: [(FileInfo, URL) throws -> Void] = [
            { try $0.apply(to: FilePath($1.path)) },
            { try $0.apply(toPath: $1.path) }
        ]

#if Foundation
        appliers.append({ try $0.apply(to: $1) })
#endif

        for applier in appliers {
            let (mountPoint, _, devEntry) = try dmgHelper.mountImage(url: imageURL, readOnly: false)
            defer { try? dmgHelper.unmountImage(mountPoint: mountPoint, devEntry: devEntry) }

            var info = try FileInfo(atPath: mountPoint.path, keys: .volumeName)

            let newName = UUID().uuidString
            info.volumeName = newName

            let volUUID = try #require(mountPoint.resourceValues(forKeys: [.volumeUUIDStringKey]).volumeUUIDString)

            try applier(info, mountPoint)

            for _ in 0..<30 where (try? mountPoint.checkResourceIsReachable()) == true {
                sleep(1)
            }

            #expect(
                #expect(throws: CocoaError.self) {
                    try mountPoint.checkResourceIsReachable()
                }?.code == .fileReadNoSuchFile
            )

            // Remount to force info to refresh
            try ejectWithDiagnostics(device: devEntry.path(percentEncoded: false))
//            try dmgHelper.unmountImage(mountPoint: mountPoint, devEntry: devEntry)
            let (newMountPoint, _, newDevEntry) = try dmgHelper.mountImage(url: imageURL, readOnly: false)
            defer { try? dmgHelper.unmountImage(mountPoint: newMountPoint, devEntry: newDevEntry) }

            #expect(newMountPoint != mountPoint)

            let newResourceValues = try newMountPoint.resourceValues(forKeys: [.volumeNameKey, .volumeUUIDStringKey])
            #expect(newResourceValues.volumeUUIDString == volUUID)
            #expect(newResourceValues.volumeName == newName)
        }
#endif
    }
}

// MARK: delete all below this: for testing only

struct CommandResult {
    let status: Int32
    let output: String
}

@discardableResult
func run(_ path: String, _ args: [String]) throws -> CommandResult {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: path)
    p.arguments = args
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = pipe
    try p.run()
    // Read before waiting, or a full pipe buffer can deadlock the child
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return CommandResult(status: p.terminationStatus,
                         output: String(decoding: data, as: UTF8.self))
}

func plist(_ args: [String]) -> [String: Any]? {
    guard let r = try? run("/usr/sbin/diskutil", args), r.status == 0,
          let obj = try? PropertyListSerialization.propertyList(
            from: Data(r.output.utf8), format: nil) else { return nil }
    return obj as? [String: Any]
}

// MARK: - Background recorders

final class Recorder {
    private let process = Process()
    private let handle: FileHandle

    init(_ path: String, _ args: [String], log: URL) throws {
        FileManager.default.createFile(atPath: log.path, contents: nil)
        handle = try FileHandle(forWritingTo: log)
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        process.standardOutput = handle
        process.standardError = handle
        try process.run()
    }

    func stop() {
        if process.isRunning { process.interrupt() }   // SIGINT, so tools flush and exit cleanly
        process.waitUntilExit()
        try? handle.close()
    }
}

// MARK: - Eject with diagnostics

enum EjectError: Error { case failed(diagnostics: URL) }

func ejectWithDiagnostics(device: String, attempts: Int = 6) throws {
    let base = ProcessInfo.processInfo.environment["RUNNER_TEMP"] ?? NSTemporaryDirectory()
    let diag = URL(fileURLWithPath: base).appendingPathComponent("eject-diag")
    try FileManager.default.createDirectory(at: diag, withIntermediateDirectories: true)

    var recorders: [Recorder] = []
    recorders.append(try Recorder("/usr/sbin/diskutil", ["activity"],
                                  log: diag.appendingPathComponent("da-activity.log")))
    recorders.append(try Recorder("/usr/bin/log",
                                  ["stream", "--level", "debug", "--predicate",
                                   "process == \"diskarbitrationd\" OR subsystem == \"com.apple.DiskArbitration\""],
                                  log: diag.appendingPathComponent("da-log.log")))
    // GitHub-hosted macOS runners allow passwordless sudo; -n fails fast instead of prompting
    recorders.append(try Recorder("/usr/bin/sudo",
                                  ["-n", "/usr/bin/fs_usage", "-w", "-f", "filesys", "-e"],
                                  log: diag.appendingPathComponent("fs_usage.log")))
    defer { recorders.forEach { $0.stop() } }
    Thread.sleep(forTimeInterval: 1)   // let the recorders attach

    var lastOutput = ""
    for attempt in 1...attempts {
        let r = try run("/usr/sbin/diskutil", ["eject", device])
        if r.status == 0 { return }
        lastOutput = r.output
        print("eject attempt \(attempt) failed: \(r.output)")
        Thread.sleep(forTimeInterval: Double(attempt * 2))
    }

    // Every retry failed: snapshot the state before forcing anything
    try snapshot(device: device, ejectOutput: lastOutput,
                 to: diag.appendingPathComponent("failure-snapshot.txt"))

    let forced = try run("/usr/sbin/diskutil", ["unmountDisk", "force", device])
    if forced.status == 0, try run("/usr/sbin/diskutil", ["eject", device]).status == 0 {
        // It came off, but only by force: still worth failing so the diagnostics get looked at
    }
    throw EjectError.failed(diagnostics: diag)
}

func snapshot(device: String, ejectOutput: String, to file: URL) throws {
    var out = "=== last eject output ===\n\(ejectOutput)\n"

    func section(_ title: String, _ path: String, _ args: [String]) {
        let r = try? run(path, args)
        out += "=== \(title) ===\n\(r?.output ?? "(failed to run)")\n"
    }

    // Every disk on this device: the whole disk plus its volumes
    let all = (plist(["list", "-plist", device])?["AllDisks"] as? [String]) ?? []
    var mountPoints: [String] = []
    for disk in all {
        section("diskutil info \(disk)", "/usr/sbin/diskutil", ["info", "/dev/\(disk)"])
        if let mp = plist(["info", "-plist", "/dev/\(disk)"])?["MountPoint"] as? String,
           !mp.isEmpty {
            mountPoints.append(mp)
        }
    }

    // Use the mount points as they are now, since a rename may have moved them
    for mp in mountPoints {
        section("open files on \(mp)", "/usr/bin/sudo", ["-n", "/usr/sbin/lsof", "+f", "--", mp])
        section("spotlight status \(mp)", "/usr/bin/mdutil", ["-s", mp])
    }

    section("mount table", "/sbin/mount", [])
    section("attached images", "/usr/sbin/diskutil", ["image", "info"])
    section("indexer/scanner processes", "/bin/sh",
            ["-c", "ps aux | grep -Ei 'mds|mdworker|xprotect|fseventsd' | grep -v grep"])
    section("non-forced unmount attempt", "/usr/sbin/diskutil", ["unmountDisk", device])

    try out.write(to: file, atomically: true, encoding: .utf8)
}
