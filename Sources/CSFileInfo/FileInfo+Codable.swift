//
//  FileInfo+Codable.swift
//
//  Created by Charles Srstka on 5/13/23.
//

import CSErrors

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

extension FileInfo: Codable {
    private enum CodingKeys: CodingKey {
        case filename
        case path
        case mountRelativePath
        case noFirmLinkPath
        case deviceID
        case realDeviceID
        case fileSystemID
        case realFileSystemID
        case objectType
        case objectTag
        case linkID
        case persistentID
        case inode
        case cloneID
        case parentID
        case script
        case creationTime
        case modificationTime
        case attributeModificationTime
        case accessTime
        case backupTime
        case addedTime
        case finderInfo
        case ownerID
        case ownerUUID
        case groupOwnerID
        case groupOwnerUUID
        case permissionsMode
        case acl
        case posixFlags
        case protectionFlags
        case extendedFlags
        case generationCount
        case recursiveGenerationCount
        case documentID
        case userAccess
        case privateSize
        case fileLinkCount
        case fileTotalLogicalSize
        case fileTotalPhysicalSize
        case fileOptimalBlockSize
        case fileAllocationClumpSize
        case fileDataForkLogicalSize
        case fileDataForkPhysicalSize
        case fileResourceForkLogicalSize
        case fileResourceForkPhysicalSize
        case fileDeviceType
        case directoryLinkCount
        case directoryEntryCount
        case directoryMountStatus
        case directoryAllocationSize
        case directoryOptimalBlockSize
        case directoryLogicalSize
        case volumeSignature
        case volumeSize
        case volumeFreeSpace
        case volumeAvailableSpace
        case volumeSpaceUsed
        case volumeMinAllocationSize
        case volumeAllocationClumpSize
        case volumeOptimalBlockSize
        case volumeObjectCount
        case volumeFileCount
        case volumeDirectoryCount
        case volumeMaxObjectCount
        case volumeMountPoint
        case volumeName
        case volumeMountFlags
        case volumeMountedDevice
        case volumeEncodingsUsed
        case volumeUUID
        case volumeFileSystemTypeName
        case volumeFileSystemSubtype
        case volumeQuotaSize
        case volumeReservedSize
        case volumeCapabilities
        case fileSystemValidCapabilities
        case volumeSupportedKeys
        case fileSystemValidKeys
    }

    private struct FSIDWrapper: Codable {
        let val0: Int32
        let val1: Int32

        init(fsid: fsid_t) {
            val0 = fsid.val.0
            val1 = fsid.val.1
        }

        var fsid: fsid_t {
            fsid_t(val: (self.val0, self.val1))
        }
    }

    private struct TimespecWrapper: Codable {
        let tv_sec: time_t
        let tv_nsec: CLong

        init(timespec t: timespec) {
            self.tv_sec = t.tv_sec
            self.tv_nsec = t.tv_nsec
        }

        var toTimespec: timespec {
            timespec(tv_sec: self.tv_sec, tv_nsec: self.tv_nsec)
        }
    }

    private struct UUIDWrapper: Codable {
        let uuidString: String

        init(uuid u: uuid_t) throws {
            var uuid = u

            let ptr = UnsafeMutablePointer<CChar>.allocate(capacity: 37)
            defer { ptr.deallocate() }

            uuid_unparse(&uuid, ptr)

            self.uuidString = String(cString: ptr)
        }

        var uuid: uuid_t {
            get throws {
                try self.uuidString.withCString { cStr in
                    try callPOSIXFunction(expect: .zero) {
                        $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<uuid_t>.size) {
                            uuid_parse(cStr, $0)
                        }
                    }
                }
            }
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.filename = try container.decodeIfPresent(String.self, forKey: .filename)
        self.pathString = try container.decodeIfPresent(String.self, forKey: .path)
        self.mountRelativePath = try container.decodeIfPresent(String.self, forKey: .mountRelativePath)
        self.noFirmLinkPath = try container.decodeIfPresent(String.self, forKey: .noFirmLinkPath)
        self.deviceID = try container.decodeIfPresent(Int32.self, forKey: .deviceID)
        self.realDeviceID = try container.decodeIfPresent(Int32.self, forKey: .realDeviceID)
        self.fileSystemID = try container.decodeIfPresent(FSIDWrapper.self, forKey: .fileSystemID)?.fsid
        self.realFileSystemID = try container.decodeIfPresent(FSIDWrapper.self, forKey: .realFileSystemID)?.fsid
        self.objectType = try container.decodeIfPresent(ObjectType.self, forKey: .objectType)
        self.objectTag = try container.decodeIfPresent(ObjectTag.self, forKey: .objectTag)
        self.linkID = try container.decodeIfPresent(UInt64.self, forKey: .linkID)
        self.persistentID = try container.decodeIfPresent(UInt64.self, forKey: .persistentID)
        self.inode = try container.decodeIfPresent(UInt64.self, forKey: .inode)
        self.cloneID = try container.decodeIfPresent(UInt64.self, forKey: .cloneID)
        self.parentID = try container.decodeIfPresent(UInt64.self, forKey: .parentID)
        self.script = try container.decodeIfPresent(UInt32.self, forKey: .script)
        self.creationTime = try container.decodeIfPresent(TimespecWrapper.self, forKey: .creationTime)?.toTimespec
        self.modificationTime = try container.decodeIfPresent(TimespecWrapper.self, forKey: .modificationTime)?.toTimespec
        self.attributeModificationTime = try container.decodeIfPresent(
            TimespecWrapper.self,
            forKey: .attributeModificationTime
        )?.toTimespec
        self.accessTime = try container.decodeIfPresent(TimespecWrapper.self, forKey: .accessTime)?.toTimespec
        self.backupTime = try container.decodeIfPresent(TimespecWrapper.self, forKey: .backupTime)?.toTimespec
        self.addedTime = try container.decodeIfPresent(TimespecWrapper.self, forKey: .addedTime)?.toTimespec
        self._finderInfo = try container.decodeIfPresent(FinderInfo.self, forKey: .finderInfo)
        self.ownerID = try container.decodeIfPresent(uid_t.self, forKey: .ownerID)
        self.ownerUUID = try container.decodeIfPresent(UUIDWrapper.self, forKey: .ownerUUID)?.uuid
        self.groupOwnerID = try container.decodeIfPresent(gid_t.self, forKey: .groupOwnerID)
        self.groupOwnerUUID = try container.decodeIfPresent(UUIDWrapper.self, forKey: .groupOwnerUUID)?.uuid
        self.permissionsMode = try container.decodeIfPresent(mode_t.self, forKey: .permissionsMode)
        self.accessControlList = try container.decodeIfPresent(AccessControlList.self, forKey: .acl)
        self._posixFlags = try container.decodeIfPresent(POSIXFlags.self, forKey: .posixFlags)
        self.protectionFlags = try container.decodeIfPresent(UInt32.self, forKey: .protectionFlags)
        self.extendedFlags = try container.decodeIfPresent(ExtendedFlags.self, forKey: .extendedFlags)
        self.generationCount = try container.decodeIfPresent(UInt32.self, forKey: .generationCount)
        self.recursiveGenerationCount = try container.decodeIfPresent(UInt64.self, forKey: .recursiveGenerationCount)
        self.documentID = try container.decodeIfPresent(UInt32.self, forKey: .documentID)
        self.userAccess = try container.decodeIfPresent(UserAccess.self, forKey: .userAccess)
        self.privateSize = try container.decodeIfPresent(off_t.self, forKey: .privateSize)
        self.fileLinkCount = try container.decodeIfPresent(UInt32.self, forKey: .fileLinkCount)
        self.fileTotalLogicalSize = try container.decodeIfPresent(off_t.self, forKey: .fileTotalLogicalSize)
        self.fileTotalPhysicalSize = try container.decodeIfPresent(off_t.self, forKey: .fileTotalPhysicalSize)
        self.fileOptimalBlockSize = try container.decodeIfPresent(UInt32.self, forKey: .fileOptimalBlockSize)
        self.fileAllocationClumpSize = try container.decodeIfPresent(UInt32.self, forKey: .fileAllocationClumpSize)
        self.fileDataForkLogicalSize = try container.decodeIfPresent(off_t.self, forKey: .fileDataForkLogicalSize)
        self.fileDataForkPhysicalSize = try container.decodeIfPresent(off_t.self, forKey: .fileDataForkPhysicalSize)
        self.fileResourceForkLogicalSize = try container.decodeIfPresent(off_t.self, forKey: .fileResourceForkLogicalSize)
        self.fileResourceForkPhysicalSize = try container.decodeIfPresent(off_t.self, forKey: .fileResourceForkPhysicalSize)
        self.fileDeviceType = try container.decodeIfPresent(UInt32.self, forKey: .fileDeviceType)
        self.directoryLinkCount = try container.decodeIfPresent(UInt32.self, forKey: .directoryLinkCount)
        self.directoryEntryCount = try container.decodeIfPresent(UInt32.self, forKey: .directoryEntryCount)
        self.directoryMountStatus = try container.decodeIfPresent(MountStatus.self, forKey: .directoryMountStatus)
        self.directoryAllocationSize = try container.decodeIfPresent(off_t.self, forKey: .directoryAllocationSize)
        self.directoryOptimalBlockSize = try container.decodeIfPresent(UInt32.self, forKey: .directoryOptimalBlockSize)
        self.directoryLogicalSize = try container.decodeIfPresent(off_t.self, forKey: .directoryLogicalSize)
        self.volumeSignature = try container.decodeIfPresent(UInt32.self, forKey: .volumeSignature)
        self.volumeSize = try container.decodeIfPresent(off_t.self, forKey: .volumeSize)
        self.volumeFreeSpace = try container.decodeIfPresent(off_t.self, forKey: .volumeFreeSpace)
        self.volumeAvailableSpace = try container.decodeIfPresent(off_t.self, forKey: .volumeAvailableSpace)
        self.volumeSpaceUsed = try container.decodeIfPresent(off_t.self, forKey: .volumeSpaceUsed)
        self.volumeMinAllocationSize = try container.decodeIfPresent(off_t.self, forKey: .volumeMinAllocationSize)
        self.volumeAllocationClumpSize = try container.decodeIfPresent(off_t.self, forKey: .volumeAllocationClumpSize)
        self.volumeOptimalBlockSize = try container.decodeIfPresent(UInt32.self, forKey: .volumeOptimalBlockSize)
        self.volumeObjectCount = try container.decodeIfPresent(UInt32.self, forKey: .volumeObjectCount)
        self.volumeFileCount = try container.decodeIfPresent(UInt32.self, forKey: .volumeFileCount)
        self.volumeDirectoryCount = try container.decodeIfPresent(UInt32.self, forKey: .volumeDirectoryCount)
        self.volumeMaxObjectCount = try container.decodeIfPresent(UInt32.self, forKey: .volumeMaxObjectCount)
        self.volumeMountPointPathString = try container.decodeIfPresent(String.self, forKey: .volumeMountPoint)
        self.volumeName = try container.decodeIfPresent(String.self, forKey: .volumeName)
        self.volumeMountFlags = try container.decodeIfPresent(UInt32.self, forKey: .volumeMountFlags)
        self.volumeMountedDevice = try container.decodeIfPresent(String.self, forKey: .volumeMountedDevice)
        self.volumeEncodingsUsed = try container.decodeIfPresent(CUnsignedLongLong.self, forKey: .volumeEncodingsUsed)
        self.volumeUUID = try container.decodeIfPresent(UUIDWrapper.self, forKey: .volumeUUID)?.uuid
        self.volumeFileSystemTypeName = try container.decodeIfPresent(String.self, forKey: .volumeFileSystemTypeName)
        self.volumeFileSystemSubtype = try container.decodeIfPresent(UInt32.self, forKey: .volumeFileSystemSubtype)
        self.volumeQuotaSize = try container.decodeIfPresent(off_t.self, forKey: .volumeQuotaSize)
        self.volumeReservedSize = try container.decodeIfPresent(off_t.self, forKey: .volumeReservedSize)
        self.volumeNativeCapabilities = try container.decodeIfPresent(VolumeCapabilities.self, forKey: .volumeCapabilities)
        self.volumeAllowedCapabilities = try container.decodeIfPresent(
            VolumeCapabilities.self,
            forKey: .fileSystemValidCapabilities
        )
        self.volumeNativelySupportedKeys = try container.decodeIfPresent(Keys.self, forKey: .volumeSupportedKeys)
        self.volumeAllowedKeys = try container.decodeIfPresent(Keys.self, forKey: .fileSystemValidKeys)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(self.filename, forKey: .filename)
        try container.encodeIfPresent(self.pathString, forKey: .path)
        try container.encodeIfPresent(self.mountRelativePath, forKey: .mountRelativePath)
        try container.encodeIfPresent(self.noFirmLinkPath, forKey: .noFirmLinkPath)
        try container.encodeIfPresent(self.deviceID, forKey: .deviceID)
        try container.encodeIfPresent(self.realDeviceID, forKey: .realDeviceID)
        try container.encodeIfPresent(self.fileSystemID.map { FSIDWrapper(fsid: $0) }, forKey: .fileSystemID)
        try container.encodeIfPresent(self.realFileSystemID.map { FSIDWrapper(fsid: $0) }, forKey: .realFileSystemID)
        try container.encodeIfPresent(self.objectType, forKey: .objectType)
        try container.encodeIfPresent(self.objectTag, forKey: .objectTag)
        try container.encodeIfPresent(self.linkID, forKey: .linkID)
        try container.encodeIfPresent(self.persistentID, forKey: .persistentID)
        try container.encodeIfPresent(self.inode, forKey: .inode)
        try container.encodeIfPresent(self.cloneID, forKey: .cloneID)
        try container.encodeIfPresent(self.parentID, forKey: .parentID)
        try container.encodeIfPresent(self.script, forKey: .script)
        try container.encodeIfPresent(self.creationTime.map { TimespecWrapper(timespec: $0) }, forKey: .creationTime)
        try container.encodeIfPresent(self.modificationTime.map { TimespecWrapper(timespec: $0) }, forKey: .modificationTime)
        try container.encodeIfPresent(
            self.attributeModificationTime.map { TimespecWrapper(timespec: $0) },
            forKey: .attributeModificationTime
        )
        try container.encodeIfPresent(self.accessTime.map { TimespecWrapper(timespec: $0) }, forKey: .accessTime)
        try container.encodeIfPresent(self.backupTime.map { TimespecWrapper(timespec: $0) }, forKey: .backupTime)
        try container.encodeIfPresent(self.addedTime.map { TimespecWrapper(timespec: $0) }, forKey: .addedTime)
        try container.encodeIfPresent(self.finderInfo, forKey: .finderInfo)
        try container.encodeIfPresent(self.ownerID, forKey: .ownerID)
        try container.encodeIfPresent(self.ownerUUID.map { try UUIDWrapper(uuid: $0) }, forKey: .ownerUUID)
        try container.encodeIfPresent(self.groupOwnerID, forKey: .groupOwnerID)
        try container.encodeIfPresent(self.groupOwnerUUID.map { try UUIDWrapper(uuid: $0) }, forKey: .groupOwnerUUID)
        try container.encodeIfPresent(self.permissionsMode, forKey: .permissionsMode)
        try container.encodeIfPresent(self.accessControlList, forKey: .acl)
        try container.encodeIfPresent(self._posixFlags, forKey: .posixFlags)
        try container.encodeIfPresent(self.protectionFlags, forKey: .protectionFlags)
        try container.encodeIfPresent(self.extendedFlags, forKey: .extendedFlags)
        try container.encodeIfPresent(self.generationCount, forKey: .generationCount)
        try container.encodeIfPresent(self.recursiveGenerationCount, forKey: .recursiveGenerationCount)
        try container.encodeIfPresent(self.documentID, forKey: .documentID)
        try container.encodeIfPresent(self.userAccess, forKey: .userAccess)
        try container.encodeIfPresent(self.privateSize, forKey: .privateSize)
        try container.encodeIfPresent(self.fileLinkCount, forKey: .fileLinkCount)
        try container.encodeIfPresent(self.fileTotalLogicalSize, forKey: .fileTotalLogicalSize)
        try container.encodeIfPresent(self.fileTotalPhysicalSize, forKey: .fileTotalPhysicalSize)
        try container.encodeIfPresent(self.fileOptimalBlockSize, forKey: .fileOptimalBlockSize)
        try container.encodeIfPresent(self.fileAllocationClumpSize, forKey: .fileAllocationClumpSize)
        try container.encodeIfPresent(self.fileDataForkLogicalSize, forKey: .fileDataForkLogicalSize)
        try container.encodeIfPresent(self.fileDataForkPhysicalSize, forKey: .fileDataForkPhysicalSize)
        try container.encodeIfPresent(self.fileResourceForkLogicalSize, forKey: .fileResourceForkLogicalSize)
        try container.encodeIfPresent(self.fileResourceForkPhysicalSize, forKey: .fileResourceForkPhysicalSize)
        try container.encodeIfPresent(self.fileDeviceType, forKey: .fileDeviceType)
        try container.encodeIfPresent(self.directoryLinkCount, forKey: .directoryLinkCount)
        try container.encodeIfPresent(self.directoryEntryCount, forKey: .directoryEntryCount)
        try container.encodeIfPresent(self.directoryMountStatus, forKey: .directoryMountStatus)
        try container.encodeIfPresent(self.directoryAllocationSize, forKey: .directoryAllocationSize)
        try container.encodeIfPresent(self.directoryOptimalBlockSize, forKey: .directoryOptimalBlockSize)
        try container.encodeIfPresent(self.directoryLogicalSize, forKey: .directoryLogicalSize)
        try container.encodeIfPresent(self.volumeSignature, forKey: .volumeSignature)
        try container.encodeIfPresent(self.volumeSize, forKey: .volumeSize)
        try container.encodeIfPresent(self.volumeFreeSpace, forKey: .volumeFreeSpace)
        try container.encodeIfPresent(self.volumeAvailableSpace, forKey: .volumeAvailableSpace)
        try container.encodeIfPresent(self.volumeSpaceUsed, forKey: .volumeSpaceUsed)
        try container.encodeIfPresent(self.volumeMinAllocationSize, forKey: .volumeMinAllocationSize)
        try container.encodeIfPresent(self.volumeAllocationClumpSize, forKey: .volumeAllocationClumpSize)
        try container.encodeIfPresent(self.volumeOptimalBlockSize, forKey: .volumeOptimalBlockSize)
        try container.encodeIfPresent(self.volumeObjectCount, forKey: .volumeObjectCount)
        try container.encodeIfPresent(self.volumeFileCount, forKey: .volumeFileCount)
        try container.encodeIfPresent(self.volumeDirectoryCount, forKey: .volumeDirectoryCount)
        try container.encodeIfPresent(self.volumeMaxObjectCount, forKey: .volumeMaxObjectCount)
        try container.encodeIfPresent(self.volumeMountPointPathString, forKey: .volumeMountPoint)
        try container.encodeIfPresent(self.volumeName, forKey: .volumeName)
        try container.encodeIfPresent(self.volumeMountFlags, forKey: .volumeMountFlags)
        try container.encodeIfPresent(self.volumeMountedDevice, forKey: .volumeMountedDevice)
        try container.encodeIfPresent(self.volumeEncodingsUsed, forKey: .volumeEncodingsUsed)
        try container.encodeIfPresent(self.volumeUUID.map { try UUIDWrapper(uuid: $0) }, forKey: .volumeUUID)
        try container.encodeIfPresent(self.volumeFileSystemTypeName, forKey: .volumeFileSystemTypeName)
        try container.encodeIfPresent(self.volumeFileSystemSubtype, forKey: .volumeFileSystemSubtype)
        try container.encodeIfPresent(self.volumeQuotaSize, forKey: .volumeQuotaSize)
        try container.encodeIfPresent(self.volumeReservedSize, forKey: .volumeReservedSize)
        try container.encodeIfPresent(self.volumeNativeCapabilities, forKey: .volumeCapabilities)
        try container.encodeIfPresent(self.volumeAllowedCapabilities, forKey: .fileSystemValidCapabilities)
        try container.encodeIfPresent(self.volumeNativelySupportedKeys, forKey: .volumeSupportedKeys)
        try container.encodeIfPresent(self.volumeAllowedKeys, forKey: .fileSystemValidKeys)
    }
}

extension FileInfo.Keys: Codable {
    private enum CodingKeys: CodingKey {
        case commonattr
        case fileattr
        case dirattr
        case volattr
        case forkattr
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let rawValue = try attribute_set_t(
            commonattr: container.decode(attrgroup_t.self, forKey: .commonattr),
            volattr: container.decode(attrgroup_t.self, forKey: .volattr),
            dirattr: container.decode(attrgroup_t.self, forKey: .dirattr),
            fileattr: container.decode(attrgroup_t.self, forKey: .fileattr),
            forkattr: container.decode(attrgroup_t.self, forKey: .forkattr)
        )

        self.init(rawValue: rawValue)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.rawValue.commonattr, forKey: .commonattr)
        try container.encode(self.rawValue.volattr, forKey: .volattr)
        try container.encode(self.rawValue.dirattr, forKey: .dirattr)
        try container.encode(self.rawValue.fileattr, forKey: .fileattr)
        try container.encode(self.rawValue.forkattr, forKey: .forkattr)
    }
}
