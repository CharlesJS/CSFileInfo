//
//  FileInfoTypes_Glibc.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 4/18/26.
//

#if canImport(Glibc)
import Glibc
import CShims

extension FileInfo {
    public enum ObjectType: Codable, Equatable, Sendable {
        case noType
        case regular
        case directory
        case symbolicLink
        case blockSpecial
        case characterSpecial
        case socket
        case fifo
        case unknown(mode_t)

        init(_ mode: mode_t) {
            self = switch Int32(bitPattern: mode) & S_IFMT {
            case 0: .noType
            case S_IFREG: .regular
            case S_IFDIR: .directory
            case S_IFLNK: .symbolicLink
            case S_IFCHR: .characterSpecial
            case S_IFBLK: .blockSpecial
            case S_IFSOCK: .socket
            case S_IFIFO: .fifo
            default: .unknown(mode & mode_t(bitPattern: S_IFMT))
            }
        }

        public var isDirectory: Bool {
            if case .directory = self {
                return true
            }
            return false
        }
    }

    public enum ObjectTag: Codable, Equatable, Sendable {
        case affs
        case autofs
        case bdevfs
        case binfmt
        case bpf
        case btrfs
        case ceph
        case cgroup
        case cgroup2
        case coda
        case cramfs
        case debugfs
        case devpts
        case efivarfs
        case exfat
        case ext2
        case ext4
        case f2fs
        case hpfs
        case hugetlbfs
        case isofs
        case jffs2
        case minix
        case msdosfs
        case ncp
        case nilfs
        case nsfs
        case ntfs
        case ocfs2
        case overlayfs
        case procfs
        case qnx4
        case qnx6
        case ramfs
        case reiserfs
        case smb
        case smb2
        case squashfs
        case tmpfs
        case tracefs
        case udf
        case v9fs
        case xfs
        case xenfs
        case zonefs
        case unknown(Int)

        init(_ type: Int) {
            self = switch type {
            case Int(AFFS_SUPER_MAGIC): .affs
            case Int(AUTOFS_SUPER_MAGIC): .autofs
            case Int(BDEVFS_MAGIC): .bdevfs
            case Int(BPF_FS_MAGIC): .bpf
            case Int(BTRFS_SUPER_MAGIC): .btrfs
            case Int(CEPH_SUPER_MAGIC): .ceph
            case Int(CGROUP_SUPER_MAGIC): .cgroup
            case Int(CGROUP2_SUPER_MAGIC): .cgroup2
            case Int(CODA_SUPER_MAGIC): .coda
            case Int(CRAMFS_MAGIC): .cramfs
            case Int(DEBUGFS_MAGIC): .debugfs
            case Int(DEVPTS_SUPER_MAGIC): .devpts
            case Int(EFIVARFS_MAGIC): .efivarfs
            case Int(EXFAT_SUPER_MAGIC): .exfat
            case Int(EXT2_SUPER_MAGIC): .ext2
            case Int(EXT4_SUPER_MAGIC): .ext4
            case Int(F2FS_SUPER_MAGIC): .f2fs
            case Int(HPFS_SUPER_MAGIC): .hpfs
            case Int(HUGETLBFS_MAGIC): .hugetlbfs
            case Int(ISOFS_SUPER_MAGIC): .isofs
            case Int(JFFS2_SUPER_MAGIC): .jffs2
            case Int(MINIX_SUPER_MAGIC): .minix
            case Int(MINIX_SUPER_MAGIC2): .minix
            case Int(MINIX2_SUPER_MAGIC): .minix
            case Int(MINIX2_SUPER_MAGIC2): .minix
            case Int(MINIX3_SUPER_MAGIC): .minix
            case Int(MSDOS_SUPER_MAGIC): .msdosfs
            case Int(NCP_SUPER_MAGIC): .ncp
            case Int(NILFS_SUPER_MAGIC): .nilfs
            case Int(NSFS_MAGIC): .nsfs
            case Int(OCFS2_SUPER_MAGIC): .ocfs2
            case Int(OVERLAYFS_SUPER_MAGIC): .overlayfs
            case Int(PROC_SUPER_MAGIC): .procfs
            case Int(QNX4_SUPER_MAGIC): .qnx4
            case Int(QNX6_SUPER_MAGIC): .qnx6
            case Int(RAMFS_MAGIC): .ramfs
            case Int(REISERFS_SUPER_MAGIC): .reiserfs
            case Int(SMB_SUPER_MAGIC): .smb
            case Int(SMB2_SUPER_MAGIC): .smb2
            case Int(SQUASHFS_MAGIC): .squashfs
            case Int(TMPFS_MAGIC): .tmpfs
            case Int(TRACEFS_MAGIC): .tracefs
            case Int(UDF_SUPER_MAGIC): .udf
            case Int(V9FS_MAGIC): .v9fs
            case Int(XFS_SUPER_MAGIC): .xfs
            case Int(XENFS_SUPER_MAGIC): .xenfs
            case Int(ZONEFS_MAGIC): .zonefs
            default: .unknown(type)
            }
        }
    }

    public struct MountStatus: OptionSet, Codable, Sendable {
        public static let isMountPoint = MountStatus(rawValue: UInt32(STATX_ATTR_MOUNT_ROOT))
        public static let isAutomountTrigger = MountStatus(rawValue: UInt32(STATX_ATTR_AUTOMOUNT))

        public let rawValue: UInt32
        public init(rawValue: UInt32) { self.rawValue = rawValue }
    }

    public struct POSIXFlags: OptionSet, Codable, Sendable {
        public static let doNotDump = POSIXFlags(rawValue: UInt32(STATX_ATTR_NODUMP))
        public static let isImmutable = POSIXFlags(rawValue: UInt32(STATX_ATTR_IMMUTABLE))
        public static let isAppendOnly = POSIXFlags(rawValue: UInt32(STATX_ATTR_APPEND))
        public static let isCompressed = POSIXFlags(rawValue: UInt32(STATX_ATTR_COMPRESSED))
        public static let isEncrypted = POSIXFlags(rawValue: UInt32(STATX_ATTR_ENCRYPTED))

        public let rawValue: UInt32
        public init(rawValue: UInt32) { self.rawValue = rawValue }
    }

    public struct ExtendedFlags: OptionSet, Codable, Sendable {
        public let rawValue: UInt64
        public init(rawValue: UInt64) { self.rawValue = rawValue }
    }

    public struct UserAccess: OptionSet, Codable, Sendable {
        public static let canRead = UserAccess(rawValue: UInt32(R_OK))
        public static let canWrite = UserAccess(rawValue: UInt32(W_OK))
        public static let canExecute = UserAccess(rawValue: UInt32(X_OK))

        public let rawValue: UInt32
        public init(rawValue: UInt32) { self.rawValue = rawValue }
    }

    public struct VolumeCapabilities: Equatable, Codable, Sendable {
        public let rawValue: UInt32
        public init(rawValue: UInt32) { self.rawValue = rawValue }
    }
}

#endif
