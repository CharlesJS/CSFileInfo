//
//  FileInfoImageFixtureTests.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 4/4/26.
//

#if canImport(Darwin)

@testable import CSFileInfo
import DiskImageHelper
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
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

            let encoder = JSONEncoder()
            let infoJSON = try encoder.encode(fileInfo)
            let expectedJSON = try encoder.encode(expectedFileInfo)

            var infoDict = try #require(JSONSerialization.jsonObject(with: infoJSON) as? [String : AnyHashable])
            let expectedDict = try #require(JSONSerialization.jsonObject(with: expectedJSON) as? [String : AnyHashable])

            for eachKey in infoDict.keys {
                if expectedDict[eachKey] == nil {
                    infoDict[eachKey] = nil
                }
            }

            #expect(
                infoDict == expectedDict,
                "\(self.diffInfo(infoDict, expect: expectedDict, imageName: imageInfo.name, url: url))"
            )
        }

        if imageInfo.supportsHardLinks {
            let hardLinkURL = mountPoint.appending(path: "DirectoryWithAttrs/hardlink")
            let origURL = mountPoint.appending(path: "Directory/PlainFile")
            let hardLinkKeys: FileInfo.Keys = [.inode, .linkID, .persistentID]

            let hardLinkInfo = try FileInfo(atPath: hardLinkURL.path, keys: hardLinkKeys)
            let origInfo = try FileInfo(atPath: origURL.path, keys: hardLinkKeys)

            #expect(hardLinkInfo.inode == origInfo.inode)

            if imageInfo.supportsLinkIDs {
                #expect(hardLinkInfo.linkID != origInfo.linkID)
                #expect(hardLinkInfo.persistentID != origInfo.persistentID)
            }
        }
    }

    private static func getExpectedInfo(file: ImageInfo.File, imageInfo: ImageInfo) -> FileInfo {
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

#endif
