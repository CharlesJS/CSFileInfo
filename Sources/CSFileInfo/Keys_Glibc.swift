//
//  Keys_Glibc.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 4/11/26.
//

#if canImport(Glibc)
import Glibc
import CShims

typealias attrgroup_t = UInt32

extension FileInfo {
    public struct Keys: OptionSet, Sendable {
        public static let all = Self(rawValue: RawValue(
            statx: [
                0: 0x03ff,
                STATX_TYPE: 0x0f,
                STATX_INO: 0x03,
                STATX_BTIME: 0x01,
                STATX_MTIME: 0x01,
                STATX_CTIME: 0x01,
                STATX_ATIME: 0x01,
                STATX_UID: 0x01,
                STATX_GID: 0x01,
                STATX_MODE: 0x01,
                STATX_NLINK: 0x03,
                STATX_SIZE: 0x07,
                STATX_BLOCKS: 0x07
            ],
            statfs: 0x03ff,
            other: 0x01ff
        ))

        public static let filename = Self.other(1 << 0)
        public static let fullPath = Self.other(1 << 1) // readlinkat(AT_FDCWD, "/proc/self/fd/N", buf, size) for an open fd. For a path, realpath(3).
        public static let mountRelativePath = Self.statx(STATX_TYPE, 1 << 0)
        public static let deviceID = Self.statx(0, 1 << 0)
        public static let realDeviceID = Self.statx(0, 1 << 1)
        public static let fileSystemID = Self.statx(0, 1 << 2)
        public static let objectType = Self.statx(STATX_TYPE, 1 << 1)
        public static let objectTag = Self.statfs(1 << 0) // f_type
        public static let inode = Self.statx(STATX_INO, 1 << 0)
        public static let creationTime = Self.statx(STATX_BTIME, 1)
        public static let modificationTime = Self.statx(STATX_MTIME, 1)
        public static let attributeModificationTime = Self.statx(STATX_CTIME, 1)
        public static let accessTime = Self.statx(STATX_ATIME, 1)
        public static let ownerID = Self.statx(STATX_UID, 1)
        public static let groupOwnerID = Self.statx(STATX_GID, 1)
        public static let permissionsMode = Self.statx(STATX_MODE, 1)
        public static let accessControlList = Self.other(1 << 2)
        public static let posixFlags = Self.statx(0, 1 << 4)
        public static let extendedFlags = Self.statx(0, 1 << 5)
        public static let fileLinkCount = Self.statx(STATX_NLINK, 1 << 0)
        public static let fileTotalLogicalSize = Self.statx(STATX_SIZE, 1 << 0)
        public static let fileTotalPhysicalSize = Self.statx(STATX_BLOCKS, 1 << 0)
        public static let fileOptimalBlockSize = Self.statx(0, 1 << 6)
        public static let fileDataForkLogicalSize = Self.statx(STATX_SIZE, 1 << 1)
        public static let fileDataForkPhysicalSize = Self.statx(STATX_BLOCKS, 1 << 1)
        public static let fileDeviceType = Self.statx(0, 1 << 7)
        public static let directoryLinkCount = Self.statx(STATX_NLINK, 1 << 1)
        public static let directoryEntryCount = Self.statx(STATX_TYPE, 1 << 3) // opendir(3) + readdir(3) loop counting entries excluding . and .., or use getdents64(2) directly. Note: stx_nlink - 2 gives the count of     subdirectories only, not total entries
        public static let directoryMountStatus = Self.statx(0, 1 << 8)
        public static let directoryOptimalBlockSize = Self.statx(0, 1 << 9)
        public static let volumeName = Self.other(1 << 3) //  ioctl(fd, FS_IOC_GETFSLABEL, buf) on Linux 5.12+ (ext4, xfs,  btrfs, f2fs); or blkid -s LABEL -o value /dev/sdX.
        public static let volumeSize = Self.statfs(1 << 1) // f_blocks * f_frsize
        public static let volumeFreeSpace = Self.statfs(1 << 2) // f_bfree * f_frsize
        public static let volumeAvailableSpace = Self.statfs(1 << 3) // f_bavail * f_frsize
        public static let volumeSpaceUsed = Self.statfs(1 << 4) // (f_blocks - f_bfree) * f_frsize
        public static let volumeMinAllocationSize = Self.statfs(1 << 5) // f_frsize
        public static let volumeOptimalBlockSize = Self.statx(0, 1 << 10) // stx_blksize
        public static let volumeObjectCount = Self.statfs(1 << 6) // f_files - f_ffree
        public static let volumeMaxObjectCount = Self.statfs(1 << 7) // f_files
        public static let volumeMountPoint = Self.statx(STATX_TYPE, 1 << 2)
        public static let volumeMountFlags = Self.statfs(1 << 8) // f_flags
        public static let volumeMountedDevice = Self.other(1 << 4) // Parse /proc/self/mountinfo (column 10, the mount source) or /proc/mounts
        public static let volumeUUID = Self.other(1 << 5) // ioctl(fd, FS_IOC_GETFSUUID, buf) on Linux 5.13+ (ext4, btrfs, xfs, f2fs); or blkid -s UUID -o value /dev/sdX; or read from /dev/disk/by-uuid/.
        public static let volumeFileSystemTypeName = Self.other(1 << 6) // Map statfs.f_type to a name using constants from <linux/magic.h>; or parse column 9 of /proc/self/mountinfo, which contains the filesystem type string directly.
        public static let volumeFileSystemSubtype = Self.other(1 << 7) // Parse column 9 of /proc/self/mountinfo. FUSE only
        public static let volumeQuotaSize = Self.other(1 << 8) //  quotactl(QCMD(Q_GETQUOTA, USRQUOTA), device, uid, &dqblk) for ext-family; quotactl(QCMD(Q_XGETQUOTA, ...), ...) for xfs.
        public static let volumeReservedSize = Self.statfs(1 << 9) // (f_bfree - f_bavail) * f_frsize

        internal static func statx(_ attr: some BinaryInteger, _ custom: Int) -> Self {
            Self(rawValue: RawValue(statx: [UInt32(attr) : custom], statfs: 0, other: 0))
        }

        internal static func statfs(_ custom: Int) -> Self {
            Self(rawValue: RawValue(statx: [:], statfs: custom, other: 0))
        }

        internal static func other(_ custom: Int) -> Self {
            Self(rawValue: RawValue(statx: [:], statfs: 0, other: custom))
        }

        public struct RawValue: Hashable, Sendable {
            let statx: [UInt32 : Int]
            let statfs: Int
            let other: Int
        }

        public let rawValue: RawValue
        public init(rawValue: RawValue) { self.rawValue = rawValue }
        public init() { self.rawValue = .init(statx: [:], statfs: 0, other: 0) }

        public mutating func formUnion(_ other: Self) {
            self = Self(rawValue: RawValue(
                statx: self.rawValue.statx.merging(other.rawValue.statx, uniquingKeysWith: { _, b in b }),
                statfs: self.rawValue.statfs | other.rawValue.statfs,
                other: self.rawValue.other | other.rawValue.other)
            )
        }

        public mutating func formIntersection(_ other: Self) {
            self = Self(rawValue: RawValue(
                statx: self.rawValue.statx.filter { key, _ in other.rawValue.statx.keys.contains(key) },
                statfs: self.rawValue.statfs & other.rawValue.statfs,
                other: self.rawValue.other & other.rawValue.other)
            )
        }

        public mutating func formSymmetricDifference(_ other: Self) {
            self = Self(rawValue: RawValue(
                statx: self.rawValue.statx.filter { !other.rawValue.statx.keys.contains($0.key) }.merging(
                    other.rawValue.statx.filter { !self.rawValue.statx.keys.contains($0.key) },
                    uniquingKeysWith: { _, b in b }
                ),
                statfs: self.rawValue.statfs ^ other.rawValue.statfs,
                other: self.rawValue.other ^ other.rawValue.other)
            )
        }

        public static func ==(lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue.statx == rhs.rawValue.statx &&
                lhs.rawValue.statfs == rhs.rawValue.statfs &&
                lhs.rawValue.other == rhs.rawValue.other
        }
    }
}

#endif
