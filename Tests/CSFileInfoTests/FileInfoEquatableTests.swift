//
//  FileInfoEquatableTests.swift
//
//
//  Created by Charles Srstka on 10/29/23.
//

@testable import CSFileInfo
import XCTest

final class FileInfoEquatableTests: XCTestCase {
    private let referenceInfo = FileInfo(
        filename: "foo",
        pathString: "bar",
        mountRelativePath: "baz",
        noFirmLinkPath: "qux",
        deviceID: 123,
        realDeviceID: 234,
        fileSystemID: .init(val: (345, 456)),
        realFileSystemID: .init(val: (567, 678)),
        objectType: .regular,
        objectTag: .afp,
        linkID: 789,
        persistentID: 890,
        inode: 1234,
        cloneID: 2345,
        parentID: 3456,
        script: 4567,
        creationTime: .init(tv_sec: 5678, tv_nsec: 6789),
        modificationTime: .init(tv_sec: 7890, tv_nsec: 8901),
        attributeModificationTime: .init(tv_sec: 12345, tv_nsec: 23456),
        accessTime: .init(tv_sec: 34567, tv_nsec: 45678),
        backupTime: .init(tv_sec: 56789, tv_nsec: 67890),
        addedTime: .init(tv_sec: 78901, tv_nsec: 89012), 
        finderInfo: .init(data: (0..<32), objectType: .regular, mountStatus: .init(rawValue: 112233)),
        ownerID: 501,
        ownerUUID: UUID(uuidString: "BB2774AC-89D4-4AC0-825D-6B7CE58688E3")!.uuid,
        groupOwnerID: 502,
        groupOwnerUUID: UUID(uuidString: "D2BD7323-DB5B-418C-8A49-5EFB00435847")!.uuid,
        permissionsMode: 0o755,
        accessControlList: try! .init(entries: [.init(rule: .allow, owner: .user(.current), permissions: .addFile)]),
        posixFlags: .init(rawValue: 14253),
        extendedFlags: .init(rawValue: 25364),
        generationCount: 123456,
        recursiveGenerationCount: 234567,
        documentID: 345678,
        userAccess: .init(rawValue: 456789),
        protectionFlags: 567890,
        privateSize: 678901,
        fileLinkCount: 789012,
        fileTotalLogicalSize: 890123,
        fileTotalPhysicalSize: 901234,
        fileOptimalBlockSize: 1234567,
        fileAllocationClumpSize: 2345678,
        fileDataForkLogicalSize: 3456789,
        fileDataForkPhysicalSize: 4567890,
        fileResourceForkLogicalSize: 5678901,
        fileResourceForkPhysicalSize: 6789012,
        fileDeviceType: 7890123,
        directoryLinkCount: 8901234,
        directoryEntryCount: 9012345,
        directoryMountStatus: .init(rawValue: 12345678),
        directoryAllocationSize: 23456789,
        directoryOptimalBlockSize: 34567890,
        directoryLogicalSize: 45678901,
        volumeSignature: 56789012,
        volumeSize: 67890123,
        volumeFreeSpace: 78901234,
        volumeAvailableSpace: 89012345,
        volumeSpaceUsed: 90123456,
        volumeMinAllocationSize: 123456789,
        volumeAllocationClumpSize: 2345678901,
        volumeOptimalBlockSize: 3456789012,
        volumeObjectCount: 132435,
        volumeFileCount: 243546,
        volumeDirectoryCount: 354657,
        volumeMaxObjectCount: 465768,
        volumeMountPointPathString: "foofoo",
        volumeName: "barbar",
        volumeMountFlags: 576879,
        volumeMountedDevice: "bazbaz",
        volumeEncodingsUsed: 9012345678,
        volumeUUID: UUID(uuidString: "6F864B71-9EC9-4A4C-9AEC-C5479953C13E")!.uuid,
        volumeFileSystemTypeName: "quxqux",
        volumeFileSystemSubtype: 1234567890,
        volumeQuotaSize: 2345678901,
        volumeReservedSize: 3456789012,
        volumeNativeCapabilities: .init(
            capabilities: .init(
                capabilities: (687980, 798013, 801324, 910213),
                valid: (1324354, 2435465, 3546576, 4657687)
            ),
            implementedOnly: true
        ),
        volumeAllowedCapabilities: .init(
            capabilities: .init(
                capabilities: (5768798, 6879809, 7980910, 8091021),
                valid: (9102132, 13243546, 24354657, 35465768)
            ),
            implementedOnly: true
        ),
        volumeNativelySupportedKeys: .all,
        volumeAllowedKeys: .all
    )

    func testEquality() throws {
        func testChange<T>(_ keyPath: WritableKeyPath<FileInfo, T?>, to value: T) {
            var info = self.referenceInfo
            XCTAssertEqual(info, self.referenceInfo)

            info[keyPath: keyPath] = nil as T?
            XCTAssertNotEqual(info, self.referenceInfo)

            info[keyPath: keyPath] = self.referenceInfo[keyPath: keyPath]
            XCTAssertEqual(info, self.referenceInfo)

            info[keyPath: keyPath] = value
            XCTAssertNotEqual(info, self.referenceInfo)
        }

        func testNumericProperty<T: Numeric>(_ keyPath: WritableKeyPath<FileInfo, T?>) {
            testChange(keyPath, to: 54321)
        }

        func testTimespecProperty(_ keyPath: WritableKeyPath<FileInfo, timespec?>) {
            testChange(keyPath, to: timespec(tv_sec: 54321, tv_nsec: 65432))
        }

        testNumericProperty(\.script)
        testTimespecProperty(\.creationTime)
        testTimespecProperty(\.modificationTime)
        testTimespecProperty(\.attributeModificationTime)
        testTimespecProperty(\.accessTime)
        testTimespecProperty(\.backupTime)
        testTimespecProperty(\.addedTime)

        testChange(\._finderInfo, to: .init(data: (1..<33), objectType: .regular, mountStatus: .init(rawValue: 112233)))
        testChange(\._finderInfo, to: .init(data: (0..<32), objectType: .directory, mountStatus: .init(rawValue: 112233)))

        testNumericProperty(\.ownerID)
        testChange(\.ownerUUID, to: UUID().uuid)
        testNumericProperty(\.groupOwnerID)
        testChange(\.groupOwnerUUID, to: UUID().uuid)
        testNumericProperty(\.permissionsMode)
        testChange(\.accessControlList, to: try .init(entries: [
            .init(rule: .deny, owner: .user(.current), permissions: [])
        ]))

        testChange(\._posixFlags, to: .init(rawValue: 54321))
        testNumericProperty(\.protectionFlags)
        testChange(\.extendedFlags, to: .init(rawValue: 54321))
    }

    func testEncodingAndDecoding() throws {
        let referenceJSON = """
        {
          "accessTime" : {
            "tv_nsec" : 45678,
            "tv_sec" : 34567
          },
          "acl" : {
            "aclData" : "ASzBbQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAB5vruKJ8RL9KE\\/9UzRNDmGAAAAAQAAAAQ=",
            "isDirectory" : false
          },
          "addedTime" : {
            "tv_nsec" : 89012,
            "tv_sec" : 78901
          },
          "attributeModificationTime" : {
            "tv_nsec" : 23456,
            "tv_sec" : 12345
          },
          "backupTime" : {
            "tv_nsec" : 67890,
            "tv_sec" : 56789
          },
          "cloneID" : 2345,
          "creationTime" : {
            "tv_nsec" : 6789,
            "tv_sec" : 5678
          },
          "deviceID" : 123,
          "directoryAllocationSize" : 23456789,
          "directoryEntryCount" : 9012345,
          "directoryLinkCount" : 8901234,
          "directoryLogicalSize" : 45678901,
          "directoryMountStatus" : 12345678,
          "directoryOptimalBlockSize" : 34567890,
          "documentID" : 345678,
          "extendedFlags" : 25364,
          "fileAllocationClumpSize" : 2345678,
          "fileDataForkLogicalSize" : 3456789,
          "fileDataForkPhysicalSize" : 4567890,
          "fileDeviceType" : 7890123,
          "fileLinkCount" : 789012,
          "filename" : "foo",
          "fileOptimalBlockSize" : 1234567,
          "fileResourceForkLogicalSize" : 5678901,
          "fileResourceForkPhysicalSize" : 6789012,
          "fileSystemID" : {
            "val0" : 345,
            "val1" : 456
          },
          "fileSystemValidCapabilities" : {
            "format" : 524820,
            "interfaces" : 4722688
          },
          "fileSystemValidKeys" : {
            "commonattr" : 3758096223,
            "dirattr" : 63,
            "fileattr" : 13871,
            "forkattr" : 2044,
            "volattr" : 4038590462
          },
          "fileTotalLogicalSize" : 890123,
          "fileTotalPhysicalSize" : 901234,
          "finderInfo" : {
            "extendedFinderFlags" : 6169,
            "finderFlags" : 2057,
            "iconLocation" : {
              "h" : 3085,
              "v" : 2571
            },
            "putAwayFolderID" : 471670303,
            "reservedExtendedFinderInfo" : 6683,
            "reservedFinderInfo" : 3599,
            "typeSpecificData" : {
              "file" : {
                "creatorCode" : 67438087,
                "isSymbolicLink" : false,
                "reserved" : 1157726452361532951,
                "typeCode" : 66051
              }
            }
          },
          "generationCount" : 123456,
          "groupOwnerID" : 502,
          "groupOwnerUUID" : {
            "uuidString" : "D2BD7323-DB5B-418C-8A49-5EFB00435847"
          },
          "inode" : 1234,
          "linkID" : 789,
          "modificationTime" : {
            "tv_nsec" : 8901,
            "tv_sec" : 7890
          },
          "mountRelativePath" : "baz",
          "noFirmLinkPath" : "qux",
          "objectTag" : {
            "afp" : {

            }
          },
          "objectType" : {
            "regular" : {

            }
          },
          "ownerID" : 501,
          "ownerUUID" : {
            "uuidString" : "BB2774AC-89D4-4AC0-825D-6B7CE58688E3"
          },
          "parentID" : 3456,
          "path" : "bar",
          "permissionsMode" : 493,
          "persistentID" : 890,
          "posixFlags" : 14253,
          "privateSize" : 678901,
          "protectionFlags" : 567890,
          "realDeviceID" : 234,
          "realFileSystemID" : {
            "val0" : 567,
            "val1" : 678
          },
          "recursiveGenerationCount" : 234567,
          "script" : 4567,
          "userAccess" : 456789,
          "volumeAllocationClumpSize" : 2345678901,
          "volumeAvailableSpace" : 89012345,
          "volumeCapabilities" : {
            "format" : 13632,
            "interfaces" : 272649
          },
          "volumeDirectoryCount" : 354657,
          "volumeEncodingsUsed" : 9012345678,
          "volumeFileCount" : 243546,
          "volumeFileSystemSubtype" : 1234567890,
          "volumeFileSystemTypeName" : "quxqux",
          "volumeFreeSpace" : 78901234,
          "volumeMaxObjectCount" : 465768,
          "volumeMinAllocationSize" : 123456789,
          "volumeMountedDevice" : "bazbaz",
          "volumeMountFlags" : 576879,
          "volumeMountPoint" : "foofoo",
          "volumeName" : "barbar",
          "volumeObjectCount" : 132435,
          "volumeOptimalBlockSize" : 3456789012,
          "volumeQuotaSize" : 2345678901,
          "volumeReservedSize" : 3456789012,
          "volumeSignature" : 56789012,
          "volumeSize" : 67890123,
          "volumeSpaceUsed" : 90123456,
          "volumeSupportedKeys" : {
            "commonattr" : 3758096223,
            "dirattr" : 63,
            "fileattr" : 13871,
            "forkattr" : 2044,
            "volattr" : 4038590462
          },
          "volumeUUID" : {
            "uuidString" : "6F864B71-9EC9-4A4C-9AEC-C5479953C13E"
          }
        }
        """

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        XCTAssertEqual(try String(data: encoder.encode(self.referenceInfo), encoding: .utf8), referenceJSON)
        XCTAssertEqual(
            try JSONDecoder().decode(FileInfo.self, from: XCTUnwrap(referenceJSON.data(using: .utf8))),
            self.referenceInfo
        )
    }
}
