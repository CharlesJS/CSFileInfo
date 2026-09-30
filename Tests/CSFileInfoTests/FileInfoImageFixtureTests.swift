//
//  FileInfoImageFixtureTests.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 4/4/26.
//

@testable import CSFileInfo
import DiskImageHelper
import Foundation
import Testing

#if canImport(SystemPackage)
import SystemPackage
#else
import System
#endif

struct ImageInfo: DiskImageInfo {
    private static let fixturesURL = Bundle.module.url(forResource: "images", withExtension: nil, subdirectory: "fixtures")!

    struct File: Codable, Sendable {
        let path: String
        let fileInfo: FileInfo
    }

    let name: String
    var imageURL: URL { Self.fixturesURL.appending(path: "\(name).dmg") }
    let fileSystem: DiskImageHelper.FileSystem

    let supportsHardLinks: Bool
    let supportsLinkIDs: Bool
    let supportsTimeZones: Bool

    let files: [File]

    static let fixtures: [Self] = try! {
        let infoURL = Self.fixturesURL.appending(path: "images.plist")
        let data = try Data(contentsOf: infoURL)

        return try Self.decode(data: data, decoder: PropertyListDecoder())
    }()
}

let withFixtures = MountTrait(imageInfo: ImageInfo.fixtures)

@Suite(withFixtures)
struct ImageFixtureTests {
    @Test(arguments: withFixtures.images)
    func testImageFixtures(fixture: MountTrait<ImageInfo>.DiskImage) async throws {
        for version in [11, 12, 13] {
            try await emulateOSVersionAsync(version) {
                try await Self.testImageFixture(fixture)
            }
        }
    }

    private static func testImageFixture(_ fixture: MountTrait<ImageInfo>.DiskImage) async throws {
#if canImport(Darwin)
        var keys: FileInfo.Keys = [.allCommon, .allFile, .allDirectory]
        keys.remove([
            .fullPath, .noFirmLinkPath, .linkID, .parentID, .cloneID,
            .deviceID, .realDeviceID, .fileSystemID, .realFileSystemID
        ])
#else
        let keys = FileInfo.Keys.all
#endif

        let rootDir = fixture.rootDirectory
        let imageInfo = fixture.info

        for eachFile in imageInfo.files {
            let url = rootDir.appending(path: eachFile.path)

            let fileInfo = try FileInfo(at: FilePath(url.path(percentEncoded: false)), keys: keys)
            let expectedFileInfo = self.getExpectedInfo(file: eachFile, imageInfo: imageInfo)

            let encoder = JSONEncoder()
            let infoJSON = try encoder.encode(fileInfo)
            let expectedJSON = try encoder.encode(expectedFileInfo)

            var infoDict = try #require(JSONSerialization.jsonObject(with: infoJSON) as? [String : Any]).mapValues {
                try makeHashable($0)
            }

            var expectedDict = try #require(JSONSerialization.jsonObject(with: expectedJSON) as? [String : Any]).mapValues {
                try makeHashable($0)
            }

            self.adjustInfoDicts(url: url, fileSystem: imageInfo.fileSystem, actual: &infoDict, expected: &expectedDict)

            #expect(
                infoDict == expectedDict,
                "\(self.diffInfo(infoDict, expect: expectedDict, imageName: imageInfo.name, url: url))"
            )
        }

        if imageInfo.supportsHardLinks {
            let hardLinkURL = rootDir.appending(path: "DirectoryWithAttrs/hardlink")
            let origURL = rootDir.appending(path: "Directory/PlainFile")
#if canImport(Darwin)
            let hardLinkKeys: FileInfo.Keys = [.inode, .linkID, .persistentID]
#else
            let hardLinkKeys: FileInfo.Keys = [.inode]
#endif

            let hardLinkInfo = try FileInfo(at: FilePath(hardLinkURL.path(percentEncoded: false)), keys: hardLinkKeys)
            let origInfo = try FileInfo(at: FilePath(origURL.path(percentEncoded: false)), keys: hardLinkKeys)

            #expect(hardLinkInfo.inode == origInfo.inode)

#if canImport(Darwin)
            if imageInfo.supportsLinkIDs {
                #expect(hardLinkInfo.linkID != origInfo.linkID)
                #expect(hardLinkInfo.persistentID != origInfo.persistentID)
            }
#endif
        }
    }

    private static func adjustInfoDicts(
        url: URL,
        fileSystem: DiskImageHelper.FileSystem,
        actual: inout [String : AnyHashable],
        expected: inout [String : AnyHashable]
    ) {
#if !canImport(Darwin)
        // work around some known bugs/limitations with fs drivers we're using for certain file systems on linux

        switch fileSystem {
        case .apfs:
            expected.removeValue(forKey: "creationTime")
            expected.removeValue(forKey: "extendedFlags")
            expected.removeValue(forKey: "fileLinkCount")

            expected.removeValue(forKey: "fileDataForkPhysicalSize")
            expected.removeValue(forKey: "fileTotalPhysicalSize")
            break
        case .exfat:
            expected.removeValue(forKey: "creationTime")
            expected.removeValue(forKey: "finderInfo")

            for timeAttr in ["attributeModificationTime", "modificationTime"] {
                if let time = expected[timeAttr] as? [String : AnyHashable] {
                    expected[timeAttr] = ["tv_sec" : time["tv_sec"], "tv_nsec" : Int(0)]
                }
            }
        case .fat32:
            expected.removeValue(forKey: "finderInfo")
        case .udf:
            expected.removeValue(forKey: "creationTime")
            expected.removeValue(forKey: "finderInfo")

            if (expected["objectType"] as? [String : Any])?.keys.first == "regular",
               let mode = expected["permissionsMode"] as? Int {
                expected["permissionsMode"] = (mode & ~0o111) as NSNumber
            }
        default: break
        }
#endif

        for eachKey in actual.keys {
            if expected[eachKey] == nil {
                actual[eachKey] = nil
            }
        }
    }

    private static func getExpectedInfo(file: ImageInfo.File, imageInfo: ImageInfo) -> FileInfo {
#if !canImport(Darwin)
        let NSEC_PER_SEC = 1_000_000_000
#endif

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

                    time.tv_sec -= thenFromGMT + (thenFromGMT - nowFromGMT)

                    info[keyPath: eachKeyPath] = time
                }
            }
        }

        return info
    }

    private static func makeHashable(_ arg: Any) throws -> AnyHashable {
        if let dict = arg as? [String : Any] {
            return try dict.mapValues { try makeHashable($0) }
        }

        if let array = arg as? [Any] {
            return try array.map { try makeHashable($0) }
        }

        return try #require(arg as? AnyHashable)
    }

    private static func diffInfo(
        _ info: [String : AnyHashable],
        expect expectedInfo: [String : AnyHashable],
        imageName: String,
        url: URL
    ) -> String {
        func compare<T: Equatable>(_ v1: T, _ v2: Any) -> Bool { v2 as? T == v1 }

        var diff = ["\(imageName), \(url.path):"]

        diff += expectedInfo.keys.filter { !info.keys.contains($0) }.map { "Missing on left: \($0)" }

        diff += info.sorted(by: { $0.key < $1.key }).compactMap { key, value in
            guard let expectedValue = expectedInfo[key] else { return "Missing on right: \(key)" }

            if compare(value, expectedValue) {
                return nil
            }

            return "Mismatch for \(key): got \(String(describing: value)), expected \(String(describing: expectedValue))"
        }

        return diff.joined(separator: "\n")
    }
}
