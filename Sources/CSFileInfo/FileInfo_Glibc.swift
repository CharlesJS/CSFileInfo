//
//  FileInfo_Glibc.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 4/25/26.
//  Copyright © 2026 Charles Srstka. All rights reserved.


#if canImport(Glibc)
import CShims
import CSErrors
import DataParser
import Glibc
import SystemPackage

public struct FileInfo: Sendable {
    public var filename: String? { self.path?.lastComponent?.string }
    public let path: FilePath?
    public let mountRelativePath: FilePath?
    public var noFirmLinkPath: FilePath? { nil }
    public let deviceID: dev_t?
    public let realDeviceID: dev_t?
    public var realFileSystemID: fsid_t? { nil }
    public let fileSystemID: fsid_t?
    public let objectType: ObjectType?
    public let objectTag: ObjectTag?
    public let inode: ino_t?
    public var linkID: UInt64? { nil }
    public var persistentID: UInt64? { nil }
    public var cloneID: UInt64? { nil }
    public var parentID: UInt64? { nil }
    public var script: UInt32? { nil }
    public var creationTime: timespec?
    public var modificationTime: timespec?
    public internal(set) var attributeModificationTime: timespec?
    public var accessTime: timespec?
    public var finderInfo: FinderInfo? { nil }

    public var ownerID: uid_t?
    public var ownerUUID: ContiguousArray<UInt8>? { nil }
    public var groupOwnerID: gid_t?
    public var groupOwnerUUID: ContiguousArray<UInt8>? { nil }
    public var permissionsMode: mode_t?
    public var protectionFlags: UInt32? { nil }
    public var accessControlList: AccessControlList?

    public var posixFlags: POSIXFlags?
    public var extendedFlags: ExtendedFlags?
    public var generationCount: UInt32? { nil }
    public var recursiveGenerationCount: UInt64? { nil }
    public var documentID: UInt32? { nil }
    public var userAccess: UserAccess? { nil }
    public var privateSize: off_t? { nil }
    public let fileLinkCount: UInt32?
    public var fileTotalLogicalSize: off_t? { self.fileDataForkLogicalSize }
    public var fileTotalPhysicalSize: off_t? { self.fileDataForkPhysicalSize }
    public let fileOptimalBlockSize: off_t?
    public var fileAllocationClumpSize: off_t? { nil }
    public let fileDataForkLogicalSize: off_t?
    public let fileDataForkPhysicalSize: off_t?
    public var fileResourceForkLogicalSize: off_t? { nil }
    public var fileResourceForkPhysicalSize: off_t? { nil }
    public var fileDeviceType: UInt32? { nil }
    public let directoryLinkCount: UInt32?
    public let directoryEntryCount: UInt32?
    public let directoryMountStatus: MountStatus?
    public var directoryAllocationSize: off_t? { nil }
    public var directoryLogicalSize: off_t? { nil }
    public var directoryOptimalBlockSize: off_t? { self.fileOptimalBlockSize }
    public let volumeSize: off_t?
    public var volumeSignature: UInt32? { nil }
    public let volumeFreeSpace: off_t?
    public let volumeAvailableSpace: off_t?
    public let volumeSpaceUsed: off_t?
    public let volumeMinAllocationSize: off_t?
    public var volumeAllocationClumpSize: off_t? { nil }
    public var volumeOptimalBlockSize: off_t? { self.fileOptimalBlockSize }
    public let volumeObjectCount: UInt?
    public var volumeFileCount: UInt? { nil }
    public var volumeDirectoryCount: UInt? { nil }
    public let volumeMaxObjectCount: UInt?
    public var volumeMountPoint: FilePath?
    public var volumeName: String?
    public let volumeMountFlags: UInt64?
    public let volumeMountedDevice: String?
    public var volumeEncodingsUsed: CUnsignedLongLong? { nil }
    public let volumeUUID: ContiguousArray<UInt8>?
    public let volumeFileSystemTypeName: String?
    public let volumeFileSystemSubtype: UInt32?
    public let volumeQuotaSize: off_t?
    public let volumeReservedSize: off_t?

    internal init(
        path: FilePath? = nil,
        mountRelativePath: FilePath? = nil,
        deviceID: dev_t? = nil,
        realDeviceID: dev_t? = nil,
        fileSystemID: fsid_t? = nil,
        objectType: ObjectType? = nil,
        objectTag: ObjectTag? = nil,
        inode: ino_t? = nil,
        creationTime: timespec? = nil,
        modificationTime: timespec? = nil,
        attributeModificationTime: timespec? = nil,
        accessTime: timespec? = nil,
        ownerID: uid_t? = nil,
        groupOwnerID: gid_t? = nil,
        permissionsMode: mode_t? = nil,
        accessControlList: AccessControlList? = nil,
        posixFlags: POSIXFlags? = nil,
        extendedFlags: ExtendedFlags? = nil,
        fileLinkCount: UInt32? = nil,
        fileOptimalBlockSize: off_t? = nil,
        fileDataForkLogicalSize: off_t? = nil,
        fileDataForkPhysicalSize: off_t? = nil,
        directoryLinkCount: UInt32? = nil,
        directoryEntryCount: UInt32? = nil,
        directoryMountStatus: MountStatus? = nil,
        volumeSize: off_t? = nil,
        volumeFreeSpace: off_t? = nil,
        volumeAvailableSpace: off_t? = nil,
        volumeSpaceUsed: off_t? = nil,
        volumeMinAllocationSize: off_t? = nil,
        volumeObjectCount: UInt? = nil,
        volumeMaxObjectCount: UInt? = nil,
        volumeMountPoint: FilePath? = nil,
        volumeName: String? = nil,
        volumeMountFlags: UInt64? = nil,
        volumeMountedDevice: String? = nil,
        volumeUUID: ContiguousArray<UInt8>? = nil,
        volumeFileSystemTypeName: String? = nil,
        volumeFileSystemSubtype: UInt32? = nil,
        volumeQuotaSize: off_t? = nil,
        volumeReservedSize: off_t? = nil
    ) {
        self.path = path
        self.mountRelativePath = mountRelativePath
        self.deviceID = deviceID
        self.realDeviceID = realDeviceID
        self.fileSystemID = fileSystemID
        self.objectType = objectType
        self.objectTag = objectTag
        self.inode = inode
        self.creationTime = creationTime
        self.modificationTime = modificationTime
        self.attributeModificationTime = attributeModificationTime
        self.accessTime = accessTime
        self.ownerID = ownerID
        self.groupOwnerID = groupOwnerID
        self.permissionsMode = permissionsMode
        self.accessControlList = accessControlList
        self.posixFlags = posixFlags
        self.extendedFlags = extendedFlags
        self.fileLinkCount = fileLinkCount
        self.fileOptimalBlockSize = fileOptimalBlockSize
        self.fileDataForkLogicalSize = fileDataForkLogicalSize
        self.fileDataForkPhysicalSize = fileDataForkPhysicalSize
        self.directoryLinkCount = directoryLinkCount
        self.directoryEntryCount = directoryEntryCount
        self.directoryMountStatus = directoryMountStatus
        self.volumeSize = volumeSize
        self.volumeFreeSpace = volumeFreeSpace
        self.volumeAvailableSpace = volumeAvailableSpace
        self.volumeSpaceUsed = volumeSpaceUsed
        self.volumeMinAllocationSize = volumeMinAllocationSize
        self.volumeObjectCount = volumeObjectCount
        self.volumeMaxObjectCount = volumeMaxObjectCount
        self.volumeMountPoint = volumeMountPoint
        self.volumeName = volumeName
        self.volumeMountFlags = volumeMountFlags
        self.volumeMountedDevice = volumeMountedDevice
        self.volumeUUID = volumeUUID
        self.volumeFileSystemTypeName = volumeFileSystemTypeName
        self.volumeFileSystemSubtype = volumeFileSystemSubtype
        self.volumeQuotaSize = volumeQuotaSize
        self.volumeReservedSize = volumeReservedSize
    }
    
    public init(at filePath: FilePath, keys: Keys) throws {
        let (statxBuf, statfsBuf) = try filePath.withPlatformString { path in
            let statxMask: UInt32 = keys.rawValue.statx.reduce(0) { $0 | UInt32($1.value) }

            let statxBuf: statx? = if statxMask != 0 {
                try callPOSIXFunction(expect: .zero) { statx(AT_FDCWD, path, 0, statxMask, $0) }
            } else {
                nil
            }

            let statfsBuf: statfs? = if keys.rawValue.statfs != 0 {
                try callPOSIXFunction(expect: .zero) { statfs(path, $0) }
            } else {
                nil
            }

            return (statxBuf, statfsBuf)
        }

        let fullPath = if filePath.isAbsolute {
            filePath
        } else {
            try withUnsafeTemporaryAllocation(byteCount: Int(PATH_MAX) + 1, alignment: 1) { buf in
                _ = try callPOSIXFunction(path: filePath) { getcwd(buf.baseAddress, buf.count) }

                buf[buf.count - 1] = 0

                return FilePath(platformString: buf.bindMemory(to: CChar.self).baseAddress!).appending(filePath.components)
            }
        }

        let acl: AccessControlList? = if keys.contains(.accessControlList) {
            try AccessControlList(at: fullPath)
        } else {
            nil
        }

        try self.init(path: fullPath, statx: statxBuf, statfs: statfsBuf, accessControlList: acl, keys: keys)
    }

    public init(at fileDescriptor: FileDescriptor, keys: Keys) throws {
        let statxMask: UInt32 = keys.rawValue.statx.reduce(0) { $0 | UInt32($1.value) }

        let statxBuf: statx? = if statxMask != 0 {
            try callPOSIXFunction(expect: .zero) { statx(fileDescriptor.rawValue, "", AT_EMPTY_PATH, statxMask, $0) }
        } else {
            nil
        }

        let statfsBuf: statfs? = if keys.rawValue.statfs != 0 {
            try callPOSIXFunction(expect: .nonNegative) { fstatfs(fileDescriptor.rawValue, $0) }
        } else {
            nil
        }

        let path: FilePath? = if !keys.intersection([.filename, .fullPath, .mountRelativePath]).isEmpty {
            try withUnsafeTemporaryAllocation(byteCount: Int(PATH_MAX) + 1, alignment: 1) { buf in
                try callPOSIXFunction(expect: .nonNegative) {
                    readlink("/proc/self/fd/\(fileDescriptor.rawValue)", buf.baseAddress!, buf.count)
                }

                buf[buf.count - 1] = 0

                return FilePath(platformString: buf.bindMemory(to: CChar.self).baseAddress!)
            }
        } else {
            nil
        }

        let acl: AccessControlList? = if keys.contains(.accessControlList) {
            try AccessControlList(at: fileDescriptor)
        } else {
            nil
        }

        try self.init(path: path, statx: statxBuf, statfs: statfsBuf, accessControlList: acl, keys: keys)
    }

    internal init(
        path: FilePath?,
        statx: statx? = nil,
        statfs: statfs? = nil,
        accessControlList: AccessControlList? = nil,
        keys: Keys? = nil
    ) throws {
        self.path = path?.lexicallyNormalized()
        self.accessControlList = accessControlList

        if let statx, (statx.stx_mask & UInt32(STATX_TYPE)) != 0 {
            self.objectType = ObjectType(mode_t(statx.stx_mode))
            self.permissionsMode = mode_t(statx.stx_mode)
        } else {
            self.objectType = nil
            self.permissionsMode = nil
        }
        
        self.ownerID = if let statx, (statx.stx_mask & UInt32(STATX_UID)) != 0 {
            statx.stx_uid
        } else {
            nil
        }
        
        self.groupOwnerID = if let statx, (statx.stx_mask & UInt32(STATX_GID)) != 0 {
            statx.stx_gid
        } else {
            nil
        }
        
        if let statx, (statx.stx_mask & UInt32(STATX_NLINK)) != 0 {
            self.fileLinkCount = statx.stx_nlink
            self.directoryLinkCount = statx.stx_nlink
        } else {
            self.fileLinkCount = nil
            self.directoryLinkCount = nil
        }
        
        self.inode = if let statx, (statx.stx_mask & UInt32(STATX_INO)) != 0 {
            ino_t(statx.stx_ino)
        } else {
            nil
        }
        
        self.fileDataForkLogicalSize = if let statx, (statx.stx_mask & UInt32(STATX_SIZE)) != 0 {
            off_t(statx.stx_size)
        } else {
            nil
        }
        
        self.fileDataForkPhysicalSize = if let statx, (statx.stx_mask & UInt32(STATX_BLOCKS)) != 0 {
            off_t(statx.stx_blocks * 512)
        } else {
            nil
        }
        
        self.accessTime = if let statx, (statx.stx_mask & UInt32(STATX_ATIME)) != 0 {
            timespec(tv_sec: time_t(statx.stx_atime.tv_sec), tv_nsec: time_t(statx.stx_atime.tv_nsec))
        } else {
            nil
        }
        
        self.modificationTime = if let statx, (statx.stx_mask & UInt32(STATX_MTIME)) != 0 {
            timespec(tv_sec: time_t(statx.stx_mtime.tv_sec), tv_nsec: time_t(statx.stx_mtime.tv_nsec))
        } else {
            nil
        }
        
        self.attributeModificationTime = if let statx, (statx.stx_mask & UInt32(STATX_CTIME)) != 0 {
            timespec(tv_sec: time_t(statx.stx_ctime.tv_sec), tv_nsec: time_t(statx.stx_ctime.tv_nsec))
        } else {
            nil
        }
        
        self.creationTime = if let statx, (statx.stx_mask & UInt32(STATX_BTIME)) != 0 {
            timespec(tv_sec: time_t(statx.stx_btime.tv_sec), tv_nsec: time_t(statx.stx_btime.tv_nsec))
        } else {
            nil
        }
        
        self.fileOptimalBlockSize = if let statx, (statx.stx_mask & UInt32(STATX_DIOALIGN)) != 0 {
            off_t(statx.stx_blksize)
        } else if let statfs, statfs.f_bsize != 0 {
            off_t(statfs.f_bsize)
        } else {
            nil
        }

        if let statx, (statx.stx_mask & UInt32(STATX_ATTR_AUTOMOUNT)) != 0 || (statx.stx_mask & UInt32(STATX_ATTR_MOUNT_ROOT)) != 0 {
            var mountStatus = MountStatus()
            if (statx.stx_attributes & UInt64(STATX_ATTR_AUTOMOUNT)) != 0 {
                mountStatus.insert(.isAutomountTrigger)
            }
            if (statx.stx_attributes & UInt64(STATX_ATTR_MOUNT_ROOT)) != 0 {
                mountStatus.insert(.isMountPoint)
            }
            self.directoryMountStatus = mountStatus
        } else {
            self.directoryMountStatus = nil
        }
        
        if let statx, (statx.stx_mask & UInt32(STATX_MODE)) != 0 {
            var posixFlags = POSIXFlags()
            if (statx.stx_attributes & UInt64(STATX_ATTR_NODUMP)) != 0 {
                posixFlags.insert(.doNotDump)
            }
            if (statx.stx_attributes & UInt64(STATX_ATTR_IMMUTABLE)) != 0 {
                posixFlags.insert(.isImmutable)
            }
            if (statx.stx_attributes & UInt64(STATX_ATTR_APPEND)) != 0 {
                posixFlags.insert(.isAppendOnly)
            }
            if (statx.stx_attributes & UInt64(STATX_ATTR_COMPRESSED)) != 0 {
                posixFlags.insert(.isCompressed)
            }
            if (statx.stx_attributes & UInt64(STATX_ATTR_ENCRYPTED)) != 0 {
                posixFlags.insert(.isEncrypted)
            }
            self.posixFlags = posixFlags
        } else {
            self.posixFlags = nil
        }
        
        if let statx, (statx.stx_mask & UInt32(STATX_DIOALIGN)) != 0 {
            var extendedFlags = ExtendedFlags(rawValue: 0)
            if (statx.stx_attributes & UInt64(STATX_ATTR_DAX)) != 0 {
                extendedFlags.insert(ExtendedFlags(rawValue: UInt64(STATX_ATTR_DAX)))
            }
            if (statx.stx_attributes & UInt64(STATX_ATTR_VERITY)) != 0 {
                extendedFlags.insert(ExtendedFlags(rawValue: UInt64(STATX_ATTR_VERITY)))
            }
            self.extendedFlags = extendedFlags
        } else {
            self.extendedFlags = nil
        }
        
        self.deviceID = if let statx, statx.stx_dev_major != 0 {
            dev_t(statx.stx_dev_major)
        } else {
            nil
        }

        self.realDeviceID = if let statx, statx.stx_rdev_major != 0 {
            dev_t(statx.stx_rdev_major)
        } else {
            nil
        }

        self.volumeSize = if let statfs, statfs.f_blocks != 0 {
            off_t(statfs.f_blocks) * off_t(statfs.f_frsize)
        } else {
            nil
        }

        self.volumeFreeSpace = if let statfs, statfs.f_bfree != 0 {
            off_t(statfs.f_bfree) * off_t(statfs.f_frsize)
        } else {
            nil
        }

        self.volumeAvailableSpace = if let statfs, statfs.f_bavail != 0 {
            off_t(statfs.f_bavail) * off_t(statfs.f_frsize)
        } else {
            nil
        }

        self.volumeSpaceUsed = if let statfs, statfs.f_blocks != 0 && statfs.f_bfree != 0 {
            off_t(statfs.f_blocks - statfs.f_bfree) * off_t(statfs.f_frsize)
        } else {
            nil
        }

        self.volumeMinAllocationSize = if let statfs, statfs.f_frsize != 0 {
            off_t(statfs.f_frsize)
        } else {
            nil
        }

        self.volumeObjectCount = if let statfs, statfs.f_files != 0 {
            statfs.f_files - statfs.f_ffree
        } else {
            nil
        }

        self.volumeMaxObjectCount = if let statfs, statfs.f_files != 0 {
            statfs.f_files
        } else {
            nil
        }

        self.volumeMountFlags = if let statfs, statfs.f_flags != 0 {
            UInt64(bitPattern: Int64(statfs.f_flags))
        } else {
            nil
        }

        self.volumeReservedSize = if let statfs, statfs.f_bfree != 0 && statfs.f_bavail != 0 {
            off_t(statfs.f_bfree - statfs.f_bavail) * off_t(statfs.f_frsize)
        } else {
            nil
        }
        
        self.objectTag = if let statfs, statfs.f_type != 0 {
            ObjectTag(statfs.f_type)
        } else {
            nil
        }
        
        self.fileSystemID = if let statfs, statfs.f_fsid.__val.0 != 0 || statfs.f_fsid.__val.1 != 0 {
            statfs.f_fsid
        } else {
            nil
        }

        self.directoryEntryCount = if let path, self.objectType?.isDirectory == true {
            try Self.countDirectoryEntries(path: path)
        } else {
            nil
        }

        self.mountRelativePath = if let path, keys?.contains(.mountRelativePath) == true {
            try Self.calculateRelativePath(path: path)
        } else {
            nil
        }

        self.volumeFileSystemTypeName = nil
        self.volumeMountPoint = nil
        self.volumeName = nil
        self.volumeMountedDevice = nil
        self.volumeUUID = nil
        self.volumeFileSystemSubtype = nil
        self.volumeQuotaSize = nil
    }

    private static func countDirectoryEntries(path: FilePath) throws -> UInt32 {
        var count: UInt32 = 0

        try path.withPlatformString { pathStr in
            let dir = try callPOSIXFunction { opendir(pathStr) }
            defer { closedir(dir) }

            while let entry = readdir(dir) {
                let name = withUnsafeBytes(of: entry.pointee.d_name) {
                    $0.withMemoryRebound(to: CInterop.PlatformChar.self) {
                        // d_name is guaranteed to at least contain a NULL character, so it can never have a null baseAddress
                        String(platformString: $0.baseAddress!)
                    }
                }
                if name == "." || name == ".." {
                    continue
                }
                count += 1
            }
        }

        return count
    }

    private static func calculateRelativePath(path: FilePath) throws -> FilePath {
        return ""
    }

    private static func getMountPoint(statxBuf: statx) throws -> FilePath {
        let file = try callPOSIXFunction { setmntent("/etc/mtab", "r") }
        defer { endmntent(file) }

        let dev = makedev(statxBuf.stx_dev_major, statxBuf.stx_dev_minor)

        return try withUnsafeTemporaryAllocation(byteCount: 4096, alignment: 1) { buf in
            var mntbuf = mntent()

            while let ent = getmntent_r(file, &mntbuf, buf.baseAddress, Int32(buf.count)) {
                let entStat = try callPOSIXFunction(expect: .zero) { lstat(ent.pointee.mnt_dir, $0) }

                if entStat.st_dev == dev {
                    return FilePath(platformString: ent.pointee.mnt_dir)
                }
            }

            throw Error.unknownError
        }
    }

    public func apply(to path: FilePath) throws {
        throw FileInfo.Error.featureNotImplemented
    }

    public func apply(to fileDescriptor: FileDescriptor) throws {
        throw FileInfo.Error.featureNotImplemented
    }
}

#endif
