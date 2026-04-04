//
//  FileInfoImageFixtureTests.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 4/4/26.
//

@testable import CSFileInfo
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

struct ImageFixture: CustomTestStringConvertible, Sendable {
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

    struct MountTrait: SuiteTrait, TestScoping {
        func provideScope(for test: Test, testCase: Test.Case?, performing f: @Sendable () async throws -> Void) async throws {
            let dmgHelper = DiskImageHelper.shared

            var mountPoints: [URL : URL] = [:]

            let devEntries = try ImageFixture.all.map { fixture in
                let (mountPoint: mountPoint, devEntry: devEntry) = try dmgHelper.mountImage(url: fixture.url, readOnly: true)

                mountPoints[fixture.url] = mountPoint

                return devEntry
            }

            defer {
                for eachDevEntry in devEntries {
                    try! DiskImageHelper.shared.unmountImage(devEntry: eachDevEntry)
                }
            }

            try await ImageFixture.$mountPoints.withValue(mountPoints) {
                try await f()
            }
        }
    }

    let url: URL
    let info: Info

    var testDescription: String { self.url.lastPathComponent }

    @TaskLocal static var mountPoints: [URL : URL] = [:]

    static let all: [ImageFixture] = {
        let bundle = Bundle.module
        let infoURL = bundle.url(forResource: "images", withExtension: "plist", subdirectory: "fixtures/images")!

        return try! PropertyListDecoder().decode([ImageFixture.Info].self, from: Data(contentsOf: infoURL)).map { info in
            let name = info.name
            let imageURL = bundle.url(forResource: name, withExtension: "dmg", subdirectory: "fixtures/images")!

            return ImageFixture(url: imageURL, info: info)
        }
    }()
}

@Suite(ImageFixture.MountTrait())
struct ImageFixtureTests {
    @Test(arguments: ImageFixture.all)
    func testImageFixtures(fixture: ImageFixture) async throws {
        for version in [11, 12, 13] {
            try await emulateOSVersionAsync(version) {
                try await Self.testImageFixture(fixture)
            }
        }
    }

    private static func testImageFixture(_ fixture: ImageFixture) async throws {
        var keys: FileInfo.Keys = [.allCommon, .allFile, .allDirectory]
        keys.remove([
            .fullPath, .noFirmLinkPath, .linkID, .parentID, .cloneID,
            .deviceID, .realDeviceID, .fileSystemID, .realFileSystemID
        ])

        guard let mountPoint = ImageFixture.mountPoints[fixture.url] else { throw CocoaError(.fileReadNoSuchFile) }
        let imageInfo = fixture.info

        for eachFile in imageInfo.files {
            let url = mountPoint.appending(path: eachFile.path)

            let fileInfo = try FileInfo(atPath: url.path, keys: keys)
            let expectedFileInfo = self.getExpectedInfo(file: eachFile, imageInfo: imageInfo)

            let infoJSON = try JSONEncoder().encode(fileInfo)
            let expectedJSON = try JSONEncoder().encode(expectedFileInfo)

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
