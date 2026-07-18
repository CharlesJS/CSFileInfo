//
//  FileInfo+Equatable.swift
//  
//
//  Created by Charles Srstka on 5/24/23.
//

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
import CSFileInfo_CShims
#endif

#if canImport(SystemPackage)
import SystemPackage
#else
import System
#endif

extension FileInfo: Equatable {
    public static func ==(lhs: FileInfo, rhs: FileInfo) -> Bool {
        self.matchers.allSatisfy { $0(lhs, rhs) }
    }

    public func difference(from otherInfo: Self) -> [PartialKeyPath<Self> : (Any, Any)] {
        zip(Self.matchers, Self.keyPaths).reduce(into: [:]) {
            let (matcher, keyPath) = $1

            if !matcher(self, otherInfo) {
                $0[keyPath] = (self[keyPath: keyPath], otherInfo[keyPath: keyPath])
            }
        }
    }

    private static let matchers: [@Sendable (Self, Self) -> Bool] = Self.keyPaths.map {
        switch $0 {
#if canImport(Darwin)
        case let path as KeyPath<Self, FinderInfo?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }
        case let path as KeyPath<Self, text_encoding_t?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }
        case let path as KeyPath<Self, VolumeCapabilities?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }
#else
        case let path as KeyPath<Self, FilePath?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }
#endif
        case let path as KeyPath<Self, String?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }
        case let path as KeyPath<Self, UInt?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }
        case let path as KeyPath<Self, UInt32?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }
        case let path as KeyPath<Self, UInt64?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }
        case let path as KeyPath<Self, CUnsignedLongLong?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }
        case let path as KeyPath<Self, dev_t?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }
        case let path as KeyPath<Self, ino_t?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }
        case let path as KeyPath<Self, off_t?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }
        case let path as KeyPath<Self, uid_t?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }
        case let path as KeyPath<Self, gid_t?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }
        case let path as KeyPath<Self, mode_t?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }
        case let path as KeyPath<Self, AccessControlList?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }
        case let path as KeyPath<Self, ObjectTag?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }
        case let path as KeyPath<Self, ObjectType?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }
        case let path as KeyPath<Self, POSIXFlags?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }
        case let path as KeyPath<Self, ExtendedFlags?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }
        case let path as KeyPath<Self, MountStatus?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }
        case let path as KeyPath<Self, UserAccess?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }
        case let path as KeyPath<Self, Keys?> & Sendable: { $0[keyPath: path] == $1[keyPath: path] }

        case let path as KeyPath<Self, fsid_t?> & Sendable: { fsidsEqual($0[keyPath: path], $1[keyPath: path]) }
        case let path as KeyPath<Self, timespec?> & Sendable: { timesEqual($0[keyPath: path], $1[keyPath: path]) }
        case let path as KeyPath<Self, uuid_t?> & Sendable: { uuidsEqual($0[keyPath: path], $1[keyPath: path]) }
        default: fatalError("Programming Error: unhandled key path type \($0)")
        }
    }

    private static var keyPaths: [PartialKeyPath<Self>] {
#if canImport(Darwin)
        [
            \.filename,
            \.pathString,
            \.mountRelativePathString,
            \.noFirmLinkPathString,
            \.deviceID,
            \.realDeviceID,
            \.fileSystemID,
            \.realFileSystemID,
            \.objectType,
            \.objectTag,
            \.inode,
            \.parentID,
            \.linkID,
            \.persistentID,
            \.cloneID,
            \.script,
            \.creationTime,
            \.modificationTime,
            \.attributeModificationTime,
            \.accessTime,
            \.backupTime,
            \.addedTime,
            \.finderInfo,
            \.ownerID,
            \.ownerUUID,
            \.groupOwnerID,
            \.groupOwnerUUID,
            \.permissionsMode,
            \.accessControlList,
            \.posixFlags,
            \.protectionFlags,
            \.extendedFlags,
            \.generationCount,
            \.recursiveGenerationCount,
            \.documentID,
            \.userAccess,
            \.privateSize,
            \.fileLinkCount,
            \.fileTotalLogicalSize,
            \.fileTotalPhysicalSize,
            \.fileOptimalBlockSize,
            \.fileAllocationClumpSize,
            \.fileDataForkLogicalSize,
            \.fileDataForkPhysicalSize,
            \.fileResourceForkLogicalSize,
            \.fileResourceForkPhysicalSize,
            \.fileDeviceType,
            \.directoryLinkCount,
            \.directoryEntryCount,
            \.directoryMountStatus,
            \.directoryAllocationSize,
            \.directoryOptimalBlockSize,
            \.directoryLogicalSize,
            \.volumeSignature,
            \.volumeSize,
            \.volumeFreeSpace,
            \.volumeAvailableSpace,
            \.volumeSpaceUsed,
            \.volumeMinAllocationSize,
            \.volumeAllocationClumpSize,
            \.volumeOptimalBlockSize,
            \.volumeObjectCount,
            \.volumeFileCount,
            \.volumeDirectoryCount,
            \.volumeMaxObjectCount,
            \.volumeMountPointPathString,
            \.volumeName,
            \.volumeMountFlags,
            \.volumeMountedDevice,
            \.volumeEncodingsUsed,
            \.volumeUUID,
            \.volumeFileSystemTypeName,
            \.volumeFileSystemSubtype,
            \.volumeQuotaSize,
            \.volumeReservedSize,
            \.volumeNativeCapabilities,
            \.volumeAllowedCapabilities,
            \.volumeNativelySupportedKeys,
            \.volumeAllowedKeys
        ]
#else
        [
            \.path,
            \.mountRelativePath,
            \.deviceID,
            \.realDeviceID,
            \.fileSystemID,
            \.objectType,
            \.objectTag,
            \.inode,
            \.creationTime,
            \.modificationTime,
            \.attributeModificationTime,
            \.accessTime,
            \.ownerID,
            \.groupOwnerID,
            \.permissionsMode,
            \.accessControlList,
            \.posixFlags,
            \.extendedFlags,
            \.fileLinkCount,
            \.fileOptimalBlockSize,
            \.fileAllocationClumpSize,
            \.fileDataForkLogicalSize,
            \.fileDataForkPhysicalSize,
            \.fileDeviceType,
            \.directoryLinkCount,
            \.directoryEntryCount,
            \.directoryMountStatus,
            \.volumeSize,
            \.volumeFreeSpace,
            \.volumeAvailableSpace,
            \.volumeSpaceUsed,
            \.volumeMinAllocationSize,
            \.volumeAllocationClumpSize,
            \.volumeObjectCount,
            \.volumeMaxObjectCount,
            \.volumeMountPoint,
            \.volumeName,
            \.volumeMountFlags,
            \.volumeMountedDevice,
            \.volumeUUID,
            \.volumeFileSystemTypeName,
            \.volumeFileSystemSubtype,
            \.volumeQuotaSize,
            \.volumeReservedSize
        ]
#endif
    }
}
