//
//  FileInfoEquatableTests.swift
//
//
//  Created by Charles Srstka on 10/29/23.
//

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
#endif

@Suite
struct FileInfoEquatableTests {
    private var fileSystemID: fsid_t? {
#if canImport(Darwin)
        fsid_t(val: (345, 456))
#else
        fsid_t(__val: (345, 456))
#endif
    }

    private var realFileSystemID: fsid_t? {
#if canImport(Darwin)
        fsid_t(val: (567, 678))
#else
        fsid_t(__val: (567, 678))
#endif
    }

    private var objectTag: FileInfo.ObjectTag {
#if canImport(Darwin)
        .afp
#else
        .unknown(0)
#endif
    }

    private var accessControlList: AccessControlList? {
#if canImport(Darwin)
        try! .init(entries: [.init(rule: .allow, owner: .user(User(id: 0xfffffffe)), permissions: .addFile)])
#else
        try! .init(entries: [
            .init(scope: .owner, permissions: [.read, .write, .execute]),
            .init(scope: .groupOwner, permissions: [.read]),
            .init(scope: .other, permissions: [.read]),
            .init(scope: .user(User(id: 65534)), permissions: [.read, .write]),
            .init(scope: .mask, permissions: [.read, .write, .execute])
        ])
#endif
    }

    private var volumeUUID: UUID {
        UUID(uuidString: "6F864B71-9EC9-4A4C-9AEC-C5479953C13E")!
    }

#if canImport(Darwin)
    private var ownerUUID: UUID {
        var uuid = uuid_t(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        precondition(mbr_uid_to_uuid(501, &uuid) == 0)

        return UUID(uuid: uuid)
    }

    private var groupOwnerUUID: UUID {
        var uuid = uuid_t(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        precondition(mbr_gid_to_uuid(502, &uuid) == 0)

        return UUID(uuid: uuid)
    }

    private var volumeNativeCapabilities: FileInfo.VolumeCapabilities? {
        .init(
            capabilities: .init(
                capabilities: (687980, 798013, 801324, 910213),
                valid: (1324354, 2435465, 3546576, 4657687)
            ),
            implementedOnly: true
        )
    }

    private var volumeAllowedCapabilities: FileInfo.VolumeCapabilities? {
        .init(
            capabilities: .init(
                capabilities: (5768798, 6879809, 7980910, 8091021),
                valid: (9102132, 13243546, 24354657, 35465768)
            ),
            implementedOnly: true
        )
    }
#endif

    private var referenceInfo: FileInfo {
#if canImport(Darwin)
        FileInfo(
            filename: "foo",
            pathString: "bar",
            mountRelativePathString: "baz",
            noFirmLinkPathString: "qux",
            deviceID: 123,
            realDeviceID: 234,
            fileSystemID: fileSystemID,
            realFileSystemID: realFileSystemID,
            objectType: .regular,
            objectTag: objectTag,
            linkID: 789,
            persistentID: 890,
            inode: 1234,
            cloneID: 2345,
            parentID: 3456,
            creationTime: .init(tv_sec: 5678, tv_nsec: 6789),
            modificationTime: .init(tv_sec: 7890, tv_nsec: 8901),
            attributeModificationTime: .init(tv_sec: 12345, tv_nsec: 23456),
            accessTime: .init(tv_sec: 34567, tv_nsec: 45678),
            backupTime: .init(tv_sec: 56789, tv_nsec: 67890),
            addedTime: .init(tv_sec: 78901, tv_nsec: 89012),
            ownerID: 501,
            groupOwnerID: 502,
            permissionsMode: 0o755,
            accessControlList: accessControlList,
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
            script: 4567,
            finderInfo: .init(data: (0..<32), objectType: .regular, mountStatus: .init(rawValue: 112233)),
            ownerUUID: ownerUUID.uuid,
            groupOwnerUUID: groupOwnerUUID.uuid,
            volumeUUID: volumeUUID.uuid,
            volumeFileSystemTypeName: "quxqux",
            volumeFileSystemSubtype: 1234567890,
            volumeQuotaSize: 2345678901,
            volumeReservedSize: 3456789012,
            volumeNativeCapabilities: volumeNativeCapabilities,
            volumeAllowedCapabilities: volumeAllowedCapabilities,
            volumeNativelySupportedKeys: .all,
            volumeAllowedKeys: .all
        )
#else
        FileInfo(
            path: FilePath("bar"),
            mountRelativePath: FilePath("baz"),
            deviceID: 123,
            realDeviceID: 234,
            fileSystemID: fileSystemID,
            objectType: .regular,
            objectTag: objectTag,
            inode: 1234,
            creationTime: .init(tv_sec: 5678, tv_nsec: 6789),
            modificationTime: .init(tv_sec: 7890, tv_nsec: 8901),
            attributeModificationTime: .init(tv_sec: 12345, tv_nsec: 23456),
            accessTime: .init(tv_sec: 34567, tv_nsec: 45678),
            ownerID: 501,
            groupOwnerID: 502,
            permissionsMode: 0o755,
            accessControlList: accessControlList,
            posixFlags: .init(rawValue: 14253),
            extendedFlags: .init(rawValue: 25364),
            fileLinkCount: 789012,
            fileOptimalBlockSize: 1234567,
            fileDataForkLogicalSize: 3456789,
            fileDataForkPhysicalSize: 4567890,
            directoryLinkCount: 8901234,
            directoryEntryCount: 9012345,
            directoryMountStatus: .init(rawValue: 12345678),
            volumeSize: 67890123,
            volumeFreeSpace: 78901234,
            volumeAvailableSpace: 89012345,
            volumeSpaceUsed: 90123456,
            volumeMinAllocationSize: 123456789,
            volumeObjectCount: 132435,
            volumeMaxObjectCount: 465768,
            volumeMountPoint: FilePath("foofoo"),
            volumeName: "barbar",
            volumeMountFlags: 576879,
            volumeMountedDevice: "bazbaz",
            volumeUUID: volumeUUID.uuid,
            volumeFileSystemTypeName: "quxqux",
            volumeFileSystemSubtype: 1234567890,
            volumeQuotaSize: 2345678901,
            volumeReservedSize: 3456789012
        )
#endif
    }

    @Test
    func testEquality() throws {
        func testChange<T>(_ keyPath: WritableKeyPath<FileInfo, T?>, to value: T) {
            var info = self.referenceInfo
            #expect(info == self.referenceInfo)

            info[keyPath: keyPath] = nil as T?
            #expect(info != self.referenceInfo)

            info[keyPath: keyPath] = self.referenceInfo[keyPath: keyPath]
            #expect(info == self.referenceInfo)

            info[keyPath: keyPath] = value
            #expect(info != self.referenceInfo)
        }

        func testNumericProperty<T: Numeric>(_ keyPath: WritableKeyPath<FileInfo, T?>) {
            testChange(keyPath, to: 54321)
        }

        func testTimespecProperty(_ keyPath: WritableKeyPath<FileInfo, timespec?>) {
            testChange(keyPath, to: timespec(tv_sec: 54321, tv_nsec: 65432))
        }

        testNumericProperty(\.ownerID)
#if canImport(Darwin)
        testChange(\.script, to: 12345)
        testTimespecProperty(\.creationTime)
        testTimespecProperty(\.modificationTime)
        testTimespecProperty(\.attributeModificationTime)
        testTimespecProperty(\.accessTime)
        testTimespecProperty(\.backupTime)
        testTimespecProperty(\.addedTime)

        testChange(\._finderInfo, to: .init(data: (1..<33), objectType: .regular, mountStatus: .init(rawValue: 112233)))
        testChange(\._finderInfo, to: .init(data: (0..<32), objectType: .directory, mountStatus: .init(rawValue: 112233)))
#else
        testTimespecProperty(\.creationTime)
        testTimespecProperty(\.modificationTime)
        testTimespecProperty(\.attributeModificationTime)
        testTimespecProperty(\.accessTime)
#endif

        testNumericProperty(\.groupOwnerID)
#if canImport(Darwin)
        testChange(\.ownerUUID, to: UUID().uuid)
#endif
        testNumericProperty(\.permissionsMode)
#if canImport(Darwin)
        testChange(\.accessControlList, to: try .init(entries: [
            .init(rule: .allow, owner: .user(.current), permissions: [])
        ]))
#else
        testChange(\.accessControlList, to: try .init(entries: [
            .init(scope: .user(.current), permissions: [])
        ]))
#endif

#if canImport(Darwin)
        testChange(\._posixFlags, to: .init(rawValue: 54321))
#endif
#if canImport(Darwin)
        testNumericProperty(\.protectionFlags)
#endif
        testChange(\.extendedFlags, to: .init(rawValue: 54321))
    }

    @Test
    func testEncodingAndDecoding() throws {
#if canImport(Darwin)
        let referenceJSON = """
        {
          "accessTime" : {
            "tv_nsec" : 45678,
            "tv_sec" : 34567
          },
          "acl" : {
            "aclData" : "ASzBbQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAD\\/\\/+7u3d3MzLu7qqr\\/\\/\\/\\/+AAAAAQAAAAQ="
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
          "filename" : "foo",
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
            "uuidString" : "\(self.groupOwnerUUID.uuidString)"
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
            "uuidString" : "\(ownerUUID.uuidString)"
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
          "volumeMountFlags" : 576879,
          "volumeMountPoint" : "foofoo",
          "volumeMountedDevice" : "bazbaz",
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
#else
        let referenceJSON = """
        {
          "accessTime" : {
            "tv_nsec" : 45678,
            "tv_sec" : 34567
          },
          "acl" : {
            "textRepresentation" : "user::rwx\\nuser:nobody:rw-\\ngroup::r--\\nmask::rwx\\nother::r--\\n"
          },
          "attributeModificationTime" : {
            "tv_nsec" : 23456,
            "tv_sec" : 12345
          },
          "creationTime" : {
            "tv_nsec" : 6789,
            "tv_sec" : 5678
          },
          "deviceID" : 123,
          "directoryEntryCount" : 9012345,
          "directoryLinkCount" : 8901234,
          "directoryMountStatus" : 12345678,
          "directoryOptimalBlockSize" : 1234567,
          "extendedFlags" : 25364,
          "fileDataForkLogicalSize" : 3456789,
          "fileDataForkPhysicalSize" : 4567890,
          "fileLinkCount" : 789012,
          "fileOptimalBlockSize" : 1234567,
          "fileSystemID" : {
            "val0" : 345,
            "val1" : 456
          },
          "fileTotalLogicalSize" : 3456789,
          "fileTotalPhysicalSize" : 4567890,
          "filename" : "bar",
          "groupOwnerID" : 502,
          "inode" : 1234,
          "modificationTime" : {
            "tv_nsec" : 8901,
            "tv_sec" : 7890
          },
          "objectTag" : {
            "unknown" : {
              "_0" : 0
            }
          },
          "objectType" : {
            "regular" : {

            }
          },
          "ownerID" : 501,
          "permissionsMode" : 493,
          "posixFlags" : 14253,
          "realDeviceID" : 234,
          "volumeAvailableSpace" : 89012345,
          "volumeFileSystemSubtype" : 1234567890,
          "volumeFileSystemTypeName" : "quxqux",
          "volumeFreeSpace" : 78901234,
          "volumeMaxObjectCount" : 465768,
          "volumeMinAllocationSize" : 123456789,
          "volumeMountFlags" : 576879,
          "volumeMountedDevice" : "bazbaz",
          "volumeName" : "barbar",
          "volumeObjectCount" : 132435,
          "volumeOptimalBlockSize" : 1234567,
          "volumeQuotaSize" : 2345678901,
          "volumeReservedSize" : 3456789012,
          "volumeSize" : 67890123,
          "volumeSpaceUsed" : 90123456,
          "volumeUUID" : {
            "uuidString" : "6F864B71-9EC9-4A4C-9AEC-C5479953C13E"
          }
        }
        """
#endif

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let actualJSON = try String(data: encoder.encode(self.referenceInfo), encoding: .utf8)
        #expect(actualJSON == referenceJSON)
//        print("!!! getting decode")
//        #expect(
//            try JSONDecoder().decode(FileInfo.self, from: #require(referenceJSON.data(using: .utf8))) == self.referenceInfo
//        )
//        print("!!! got here")
    }
}
