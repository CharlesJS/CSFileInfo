//
//  Types.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 11/5/17.
//

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

extension FileInfo {
    public enum ObjectType: Codable, Equatable {
        case noType
        case regular
        case directory
        case symbolicLink
        case blockSpecial
        case characterSpecial
        case socket
        case fifo
        case unknown(fsobj_type_t)

        internal init(_ type: fsobj_type_t) {
            switch vtype(rawValue: type) {
            case VNON:
                self = .noType
            case VREG:
                self = .regular
            case VDIR:
                self = .directory
            case VLNK:
                self = .symbolicLink
            case VBLK:
                self = .blockSpecial
            case VCHR:
                self = .characterSpecial
            case VSOCK:
                self = .socket
            case VFIFO:
                self = .fifo
            default:
                self = .unknown(type)
            }
        }
    }

    public enum ObjectTag: Codable, Equatable {
        case none
        case ufs
        case nfs
        case mfs
        case msdosfs
        case lfs
        case lofs
        case fdesc
        case portal
        case null
        case umap
        case kernfs
        case procfs
        case afs
        case isofs
        case mockfs
        case hfs
        case zfs
        case devfs
        case webdav
        case udf
        case afp
        case cdda
        case cifs
        case other
        case apfs
        case lockerfs
        case bindfs
        case unknown(fsobj_tag_t)

        internal init(_ tag: fsobj_tag_t) {
            switch vtagtype(rawValue: tag) {
            case VT_NON:
                self = .none
            case VT_UFS:
                self = .ufs
            case VT_NFS:
                self = .nfs
            case VT_MFS:
                self = .mfs
            case VT_MSDOSFS:
                self = .msdosfs
            case VT_LFS:
                self = .lfs
            case VT_LOFS:
                self = .lofs
            case VT_FDESC:
                self = .fdesc
            case VT_PORTAL:
                self = .portal
            case VT_NULL:
                self = .null
            case VT_UMAP:
                self = .umap
            case VT_KERNFS:
                self = .kernfs
            case VT_PROCFS:
                self = .procfs
            case VT_AFS:
                self = .afs
            case VT_ISOFS:
                self = .isofs
            case VT_MOCKFS:
                self = .mockfs
            case VT_HFS:
                self = .hfs
            case VT_ZFS:
                self = .zfs
            case VT_DEVFS:
                self = .devfs
            case VT_WEBDAV:
                self = .webdav
            case VT_UDF:
                self = .udf
            case VT_AFP:
                self = .afp
            case VT_CDDA:
                self = .cdda
            case VT_CIFS:
                self = .cifs
            case VT_OTHER:
                self = .other
            case VT_APFS:
                self = .apfs
            case VT_LOCKERFS:
                self = .lockerfs
            case VT_BINDFS:
                self = .bindfs
            default:
                self = .unknown(tag)
            }
        }
    }

    public struct MountStatus: OptionSet, Codable {
        public static let isMountPoint = MountStatus(rawValue: UInt32(DIR_MNTSTATUS_MNTPOINT))
        public static let isAutomountTrigger = MountStatus(rawValue: UInt32(DIR_MNTSTATUS_TRIGGER))

        public let rawValue: UInt32
        public init(rawValue: UInt32) { self.rawValue = rawValue }
    }

    public struct POSIXFlags: OptionSet, Codable {
        public static let doNotDump = POSIXFlags(rawValue: UInt32(UF_NODUMP))
        public static let isImmutable = POSIXFlags(rawValue: UInt32(UF_IMMUTABLE))
        public static let isAppendOnly = POSIXFlags(rawValue: UInt32(UF_APPEND))
        public static let isOpaque = POSIXFlags(rawValue: UInt32(UF_OPAQUE))
        public static let isHidden = POSIXFlags(rawValue: UInt32(UF_HIDDEN))
        public static let isCompressed = POSIXFlags(rawValue: UInt32(UF_COMPRESSED))
        public static let isTracked = POSIXFlags(rawValue: UInt32(UF_TRACKED))
        public static let requiresEntitlement = POSIXFlags(rawValue: UInt32(UF_DATAVAULT))
        public static let superIsArchived = POSIXFlags(rawValue: UInt32(SF_ARCHIVED))
        public static let superIsImmutable = POSIXFlags(rawValue: UInt32(SF_IMMUTABLE))
        public static let superIsAppendOnly = POSIXFlags(rawValue: UInt32(SF_APPEND))
        public static let superRequiresEntitlement = POSIXFlags(rawValue: UInt32(SF_RESTRICTED))
        public static let superIsNonUnlinkable = POSIXFlags(rawValue: UInt32(SF_NOUNLINK))

        public let rawValue: UInt32
        public init(rawValue: UInt32) { self.rawValue = rawValue }
    }

    public struct ExtendedFlags: OptionSet, Codable {
        public static let mayShareBlocks = ExtendedFlags(rawValue: UInt64(EF_MAY_SHARE_BLOCKS))
        public static let noExtendedAttributes = ExtendedFlags(rawValue: UInt64(EF_NO_XATTRS))
        public static let isSyncRoot = ExtendedFlags(rawValue: UInt64(EF_IS_SYNC_ROOT))
        public static let isPurgeable = ExtendedFlags(rawValue: UInt64(EF_IS_PURGEABLE))
        public static let isSparse = ExtendedFlags(rawValue: UInt64(EF_IS_SPARSE))
        public static let isSynthetic = ExtendedFlags(rawValue: UInt64(EF_IS_SYNTHETIC))

        public let rawValue: UInt64
        public init(rawValue: UInt64) { self.rawValue = rawValue }
    }

    public struct UserAccess: OptionSet, Codable {
        public static let canRead = UserAccess(rawValue: UInt32(R_OK))
        public static let canWrite = UserAccess(rawValue: UInt32(W_OK))
        public static let canExecute = UserAccess(rawValue: UInt32(X_OK))

        public let rawValue: UInt32
        public init(rawValue: UInt32) { self.rawValue = rawValue }
    }

    public struct VolumeCapabilities: Equatable, Codable {
        public struct Format: OptionSet, Codable {
            public static let persistentObjectIDs = Format(rawValue: UInt32(VOL_CAP_FMT_PERSISTENTOBJECTIDS))
            public static let symbolicLinks = Format(rawValue: UInt32(VOL_CAP_FMT_SYMBOLICLINKS))
            public static let hardLinks = Format(rawValue: UInt32(VOL_CAP_FMT_HARDLINKS))
            public static let journal = Format(rawValue: UInt32(VOL_CAP_FMT_JOURNAL))
            public static let activeJournal = Format(rawValue: UInt32(VOL_CAP_FMT_JOURNAL_ACTIVE))
            public static let noRootTimes = Format(rawValue: UInt32(VOL_CAP_FMT_NO_ROOT_TIMES))
            public static let sparseFiles = Format(rawValue: UInt32(VOL_CAP_FMT_SPARSE_FILES))
            public static let zeroRuns = Format(rawValue: UInt32(VOL_CAP_FMT_ZERO_RUNS))
            public static let caseSensitive = Format(rawValue: UInt32(VOL_CAP_FMT_CASE_SENSITIVE))
            public static let casePreserving = Format(rawValue: UInt32(VOL_CAP_FMT_CASE_PRESERVING))
            public static let fastStatfs = Format(rawValue: UInt32(VOL_CAP_FMT_FAST_STATFS))
            public static let supports2TBFileSizes = Format(rawValue: UInt32(VOL_CAP_FMT_2TB_FILESIZE))
            public static let openDenyModes = Format(rawValue: UInt32(VOL_CAP_FMT_OPENDENYMODES))
            public static let hiddenFiles = Format(rawValue: UInt32(VOL_CAP_FMT_HIDDEN_FILES))
            public static let pathFromID = Format(rawValue: UInt32(VOL_CAP_FMT_PATH_FROM_ID))
            public static let noVolumeSizes = Format(rawValue: UInt32(VOL_CAP_FMT_NO_VOLUME_SIZES))
            public static let supports64BitObjectIDs = Format(rawValue: UInt32(VOL_CAP_FMT_64BIT_OBJECT_IDS))
            public static let noImmutableFiles = Format(rawValue: UInt32(VOL_CAP_FMT_NO_IMMUTABLE_FILES))
            public static let noPermissions = Format(rawValue: UInt32(VOL_CAP_FMT_NO_PERMISSIONS))
            public static let sharedSpace = Format(rawValue: UInt32(VOL_CAP_FMT_SHARED_SPACE))
            public static let volumeGroups = Format(rawValue: UInt32(VOL_CAP_FMT_VOL_GROUPS))
            public static let sealed = Format(rawValue: UInt32(VOL_CAP_FMT_SEALED))

            public let rawValue: UInt32
            public init(rawValue: UInt32) { self.rawValue = rawValue }
        }

        public struct Interfaces: OptionSet, Codable {
            public static let searchfs = Interfaces(rawValue: UInt32(VOL_CAP_INT_SEARCHFS))
            public static let attrlist = Interfaces(rawValue: UInt32(VOL_CAP_INT_ATTRLIST))
            public static let nfsExport = Interfaces(rawValue: UInt32(VOL_CAP_INT_NFSEXPORT))
            public static let getdirentriesattr = Interfaces(rawValue: UInt32(VOL_CAP_INT_READDIRATTR))
            public static let exchangedata = Interfaces(rawValue: UInt32(VOL_CAP_INT_EXCHANGEDATA))
            public static let copyfile = Interfaces(rawValue: UInt32(VOL_CAP_INT_COPYFILE))
            public static let allocate = Interfaces(rawValue: UInt32(VOL_CAP_INT_ALLOCATE))
            public static let volumeRename = Interfaces(rawValue: UInt32(VOL_CAP_INT_VOL_RENAME))
            public static let advisoryLocks = Interfaces(rawValue: UInt32(VOL_CAP_INT_ADVLOCK))
            public static let flock = Interfaces(rawValue: UInt32(VOL_CAP_INT_FLOCK))
            public static let accessControlLists = Interfaces(rawValue: UInt32(VOL_CAP_INT_EXTENDED_SECURITY))
            public static let userAccess = Interfaces(rawValue: UInt32(VOL_CAP_INT_USERACCESS))
            public static let mandatoryLocks = Interfaces(rawValue: UInt32(VOL_CAP_INT_MANLOCK))
            public static let extendedAttributes = Interfaces(rawValue: UInt32(VOL_CAP_INT_EXTENDED_ATTR))
            public static let cloning = Interfaces(rawValue: UInt32(VOL_CAP_INT_CLONE))
            public static let snapshots = Interfaces(rawValue: UInt32(VOL_CAP_INT_SNAPSHOT))
            public static let namedStreams = Interfaces(rawValue: UInt32(VOL_CAP_INT_NAMEDSTREAMS))
            public static let renameSwap = Interfaces(rawValue: UInt32(VOL_CAP_INT_RENAME_SWAP))
            public static let exclusiveRename = Interfaces(rawValue: UInt32(VOL_CAP_INT_RENAME_EXCL))
            public static let failRenameIfOpen = Interfaces(rawValue: UInt32(VOL_CAP_INT_RENAME_OPENFAIL))

            public let rawValue: UInt32
            public init(rawValue: UInt32) { self.rawValue = rawValue }
        }

        public let format: Format
        public let interfaces: Interfaces

        internal init(capabilities: vol_capabilities_attr_t, implementedOnly: Bool) {
            if implementedOnly {
                self.format = Format(rawValue: capabilities.capabilities.0 & capabilities.valid.0)
                self.interfaces = Interfaces(rawValue: capabilities.capabilities.1 & capabilities.valid.1)
            } else {
                self.format = Format(rawValue: capabilities.valid.0)
                self.interfaces = Interfaces(rawValue: capabilities.valid.1)
            }
        }
    }
}
