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
#endif

extension FileInfo: Equatable {
    public static func ==(lhs: FileInfo, rhs: FileInfo) -> Bool {
        func compareTimes(_ l: timespec?, _ r: timespec?) -> Bool {
            l?.tv_sec == r?.tv_sec && l?.tv_nsec == r?.tv_nsec
        }

        func compareUUIDs(_ l: uuid_t?, _ r: uuid_t?) -> Bool {
            guard var l, var r else { return (l != nil) == (r != nil) }
            return uuid_compare(&l, &r) == 0
        }

        return rhs.filename == rhs.filename &&
        lhs.pathString == rhs.pathString &&
        lhs.mountRelativePath == rhs.mountRelativePath &&
        lhs.noFirmLinkPath == rhs.noFirmLinkPath &&
        lhs.deviceID == rhs.deviceID &&
        lhs.realDeviceID == rhs.realDeviceID &&
        lhs.fileSystemID == rhs.fileSystemID &&
        lhs.realFileSystemID == rhs.realFileSystemID &&
        lhs.objectType == rhs.objectType &&
        lhs.objectTag == rhs.objectTag &&
        lhs.inode == rhs.inode &&
        lhs.parentID == rhs.parentID &&
        lhs.linkID == rhs.linkID &&
        lhs.persistentID == rhs.persistentID &&
        lhs.cloneID == rhs.cloneID &&
        lhs.script == rhs.script &&
        compareTimes(lhs.creationTime, rhs.creationTime) &&
        compareTimes(lhs.modificationTime, rhs.modificationTime) &&
        compareTimes(lhs.attributeModificationTime, rhs.attributeModificationTime) &&
        compareTimes(lhs.accessTime, rhs.accessTime) &&
        compareTimes(lhs.backupTime, rhs.backupTime) &&
        compareTimes(lhs.addedTime, rhs.addedTime) &&
        lhs.finderInfo == rhs.finderInfo &&
        lhs.ownerID == rhs.ownerID &&
        compareUUIDs(lhs.ownerUUID, rhs.ownerUUID) &&
        lhs.groupOwnerID == rhs.groupOwnerID &&
        compareUUIDs(lhs.groupOwnerUUID, rhs.groupOwnerUUID) &&
        lhs.permissionsMode == rhs.permissionsMode &&
        lhs.accessControlList == rhs.accessControlList &&
        lhs.posixFlags == rhs.posixFlags &&
        lhs.protectionFlags == rhs.protectionFlags &&
        lhs.extendedFlags == rhs.extendedFlags &&
        lhs.generationCount == rhs.generationCount &&
        lhs.recursiveGenerationCount == rhs.recursiveGenerationCount &&
        lhs.documentID == rhs.documentID &&
        lhs.userAccess == rhs.userAccess &&
        lhs.privateSize == rhs.privateSize &&
        lhs.fileLinkCount == rhs.fileLinkCount &&
        lhs.fileTotalLogicalSize == rhs.fileTotalLogicalSize &&
        lhs.fileTotalPhysicalSize == rhs.fileTotalPhysicalSize &&
        lhs.fileOptimalBlockSize == rhs.fileOptimalBlockSize &&
        lhs.fileAllocationClumpSize == rhs.fileAllocationClumpSize &&
        lhs.fileDataForkLogicalSize == rhs.fileDataForkLogicalSize &&
        lhs.fileDataForkPhysicalSize == rhs.fileDataForkPhysicalSize &&
        lhs.fileResourceForkLogicalSize == rhs.fileResourceForkLogicalSize &&
        lhs.fileResourceForkPhysicalSize == rhs.fileResourceForkPhysicalSize &&
        lhs.fileDeviceType == rhs.fileDeviceType &&
        lhs.directoryLinkCount == rhs.directoryLinkCount &&
        lhs.directoryEntryCount == rhs.directoryEntryCount &&
        lhs.directoryMountStatus == rhs.directoryMountStatus &&
        lhs.directoryAllocationSize == rhs.directoryAllocationSize &&
        lhs.directoryOptimalBlockSize == rhs.directoryOptimalBlockSize &&
        lhs.directoryLogicalSize == rhs.directoryLogicalSize &&
        lhs.volumeSignature == rhs.volumeSignature &&
        lhs.volumeSize == rhs.volumeSize &&
        lhs.volumeFreeSpace == rhs.volumeFreeSpace &&
        lhs.volumeAvailableSpace == rhs.volumeAvailableSpace &&
        lhs.volumeSpaceUsed == rhs.volumeSpaceUsed &&
        lhs.volumeMinAllocationSize == rhs.volumeMinAllocationSize &&
        lhs.volumeAllocationClumpSize == rhs.volumeAllocationClumpSize &&
        lhs.volumeOptimalBlockSize == rhs.volumeOptimalBlockSize &&
        lhs.volumeObjectCount == rhs.volumeObjectCount &&
        lhs.volumeFileCount == rhs.volumeFileCount &&
        lhs.volumeDirectoryCount == rhs.volumeDirectoryCount &&
        lhs.volumeMaxObjectCount == rhs.volumeMaxObjectCount &&
        lhs.volumeMountPointPathString == rhs.volumeMountPointPathString &&
        lhs.volumeName == rhs.volumeName &&
        lhs.volumeMountFlags == rhs.volumeMountFlags &&
        lhs.volumeMountedDevice == rhs.volumeMountedDevice &&
        lhs.volumeEncodingsUsed == rhs.volumeEncodingsUsed &&
        compareUUIDs(lhs.volumeUUID, rhs.volumeUUID) &&
        lhs.volumeFileSystemTypeName == rhs.volumeFileSystemTypeName &&
        lhs.volumeFileSystemSubtype == rhs.volumeFileSystemSubtype &&
        lhs.volumeQuotaSize == rhs.volumeQuotaSize &&
        lhs.volumeReservedSize == rhs.volumeReservedSize &&
        lhs.volumeNativeCapabilities == rhs.volumeNativeCapabilities &&
        lhs.volumeAllowedCapabilities == rhs.volumeAllowedCapabilities &&
        lhs.volumeNativelySupportedKeys == rhs.volumeNativelySupportedKeys &&
        lhs.volumeAllowedKeys == rhs.volumeAllowedKeys
    }
}
