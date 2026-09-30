//
//  FileInfoTypes_Glibc.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 4/18/26.
//

#if canImport(Glibc)
import Glibc
import CSFileInfo_CShims

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

    public enum FileSystemType: Codable, Hashable, Sendable {
        private enum Magic {
            static let fuse: UInt32 = 0x65735546
        }

        case affs
        case apfs
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
        case fuse
        case hpfs
        case hfs
        case hugetlbfs
        case isofs
        case jffs2
        case minix1(filenameLength: Int)
        case minix2(filenameLength: Int)
        case minix3
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
        case unknown(UInt32)

        private static let rawToType: [UInt32 : FileSystemType] = [
            UInt32(bitPattern: AFFS_SUPER_MAGIC): .affs,
            UInt32(bitPattern: AUTOFS_SUPER_MAGIC): .autofs,
            UInt32(bitPattern: BDEVFS_MAGIC): .bdevfs,
            BPF_FS_MAGIC: .bpf,
            BTRFS_SUPER_MAGIC: .btrfs,
            UInt32(bitPattern: CEPH_SUPER_MAGIC): .ceph,
            UInt32(bitPattern: CGROUP_SUPER_MAGIC): .cgroup,
            UInt32(bitPattern: CGROUP2_SUPER_MAGIC): .cgroup2,
            UInt32(bitPattern: CODA_SUPER_MAGIC): .coda,
            UInt32(bitPattern: CRAMFS_MAGIC): .cramfs,
            UInt32(bitPattern: DEBUGFS_MAGIC): .debugfs,
            UInt32(bitPattern: DEVPTS_SUPER_MAGIC): .devpts,
            EFIVARFS_MAGIC: .efivarfs,
            UInt32(bitPattern: EXFAT_SUPER_MAGIC): .exfat,
            UInt32(bitPattern: EXT4_SUPER_MAGIC): .ext4,
            F2FS_SUPER_MAGIC: .f2fs,
            Magic.fuse: .fuse,
            HPFS_SUPER_MAGIC: .hpfs,
            HUGETLBFS_MAGIC: .hugetlbfs,
            UInt32(bitPattern: ISOFS_SUPER_MAGIC): .isofs,
            UInt32(bitPattern: JFFS2_SUPER_MAGIC): .jffs2,
            UInt32(bitPattern: MINIX_SUPER_MAGIC): .minix1(filenameLength: 14),
            UInt32(bitPattern: MINIX_SUPER_MAGIC2): .minix1(filenameLength: 30),
            UInt32(bitPattern: MINIX2_SUPER_MAGIC): .minix2(filenameLength: 14),
            UInt32(bitPattern: MINIX2_SUPER_MAGIC2): .minix2(filenameLength: 30),
            UInt32(bitPattern: MINIX3_SUPER_MAGIC): .minix3,
            UInt32(bitPattern: MSDOS_SUPER_MAGIC): .msdosfs,
            UInt32(bitPattern: NCP_SUPER_MAGIC): .ncp,
            UInt32(bitPattern: NILFS_SUPER_MAGIC): .nilfs,
            UInt32(bitPattern: NSFS_MAGIC): .nsfs,
            UInt32(bitPattern: OCFS2_SUPER_MAGIC): .ocfs2,
            UInt32(bitPattern: OVERLAYFS_SUPER_MAGIC): .overlayfs,
            UInt32(bitPattern: PROC_SUPER_MAGIC): .procfs,
            UInt32(bitPattern: QNX4_SUPER_MAGIC): .qnx4,
            UInt32(bitPattern: QNX6_SUPER_MAGIC): .qnx6,
            RAMFS_MAGIC: .ramfs,
            UInt32(bitPattern: REISERFS_SUPER_MAGIC): .reiserfs,
            UInt32(bitPattern: SMB_SUPER_MAGIC): .smb,
            SMB2_SUPER_MAGIC: .smb2,
            UInt32(bitPattern: SQUASHFS_MAGIC): .squashfs,
            UInt32(bitPattern: TMPFS_MAGIC): .tmpfs,
            UInt32(bitPattern: TRACEFS_MAGIC): .tracefs,
            UInt32(bitPattern: UDF_SUPER_MAGIC): .udf,
            UInt32(bitPattern: V9FS_MAGIC): .v9fs,
            UInt32(bitPattern: XFS_SUPER_MAGIC): .xfs,
            XENFS_SUPER_MAGIC: .xenfs,
            UInt32(bitPattern: ZONEFS_MAGIC): .zonefs
        ]

        private static let typeToRaw = Dictionary(uniqueKeysWithValues: rawToType.map { ($1, $0) })

        init(_ rawValue: UInt32) {
            if let type = Self.rawToType[rawValue] {
                self = type
            } else {
                self = .unknown(rawValue)
            }
        }

        var rawValue: UInt32 {
            switch self {
            case .unknown(let raw): raw
            default: Self.typeToRaw[self]!
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
