//
//  Keys_Darwin.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 11/4/17.
//

#if canImport(Darwin)
import Darwin

extension FileInfo {
    public struct Keys: OptionSet, Sendable {
        public static let all: Keys = [.allCommon, .allFile, .allDirectory, .allVolume]
        static let allCommon = Self.common(0x5fffff5f).union(Self.fork(0x7fc))
        static let allFile = Self.file(0x362f)
        static let allDirectory = Self.dir(0x3f)
        static let allVolume = Self.vol(0xf0b7fffe)

        public static let filename = Self.common(ATTR_CMN_NAME)
        public static let fullPath = Self.common(ATTR_CMN_FULLPATH)
        public static let mountRelativePath = Self.fork(ATTR_CMNEXT_RELPATH)
        public static let noFirmLinkPath = Self.fork(ATTR_CMNEXT_NOFIRMLINKPATH)
        public static let deviceID = Self.common(ATTR_CMN_DEVID)
        public static let realDeviceID = Self.fork(ATTR_CMNEXT_REALDEVID)
        public static let fileSystemID = Self.common(ATTR_CMN_FSID)
        public static let realFileSystemID = Self.fork(ATTR_CMNEXT_REALFSID)
        public static let objectType = Self.common(ATTR_CMN_OBJTYPE)
        public static let objectTag = Self.common(ATTR_CMN_OBJTAG)
        public static let inode = Self.common(ATTR_CMN_FILEID)
        public static let linkID = Self.fork(ATTR_CMNEXT_LINKID)
        public static let persistentID = Self.common(ATTR_CMN_OBJPERMANENTID)
        public static let cloneID = Self.fork(ATTR_CMNEXT_CLONEID)
        public static let parentID = Self.common(ATTR_CMN_PARENTID)
        public static let script = Self.common(ATTR_CMN_SCRIPT)
        public static let creationTime = Self.common(ATTR_CMN_CRTIME)
        public static let modificationTime = Self.common(ATTR_CMN_MODTIME)
        public static let attributeModificationTime = Self.common(ATTR_CMN_CHGTIME)
        public static let accessTime = Self.common(ATTR_CMN_ACCTIME)
        public static let backupTime = Self.common(ATTR_CMN_BKUPTIME)
        public static let addedTime = Self.common(ATTR_CMN_ADDEDTIME)
        public static let finderInfo = Self.common(ATTR_CMN_FNDRINFO)
        public static let ownerID = Self.common(ATTR_CMN_OWNERID)
        public static let ownerUUID = Self.common(ATTR_CMN_UUID)
        public static let groupOwnerID = Self.common(ATTR_CMN_GRPID)
        public static let groupOwnerUUID = Self.common(ATTR_CMN_GRPUUID)
        public static let permissionsMode = Self.common(ATTR_CMN_ACCESSMASK)
        public static let accessControlList = Self.common(ATTR_CMN_EXTENDED_SECURITY)
        public static let posixFlags = Self.common(ATTR_CMN_FLAGS)
        public static let protectionFlags = Self.common(ATTR_CMN_DATA_PROTECT_FLAGS)
        public static let extendedFlags = Self.fork(ATTR_CMNEXT_EXT_FLAGS)
        public static let generationCount = Self.common(ATTR_CMN_GEN_COUNT)
        public static let recursiveGenerationCount = Self.fork(ATTR_CMNEXT_RECURSIVE_GENCOUNT)
        public static let documentID = Self.common(ATTR_CMN_DOCUMENT_ID)
        public static let userAccess = Self.common(ATTR_CMN_USERACCESS)
        public static let privateSize = Self.fork(ATTR_CMNEXT_PRIVATESIZE)
        public static let fileLinkCount = Self.file(ATTR_FILE_LINKCOUNT)
        public static let fileTotalLogicalSize = Self.file(ATTR_FILE_TOTALSIZE)
        public static let fileTotalPhysicalSize = Self.file(ATTR_FILE_ALLOCSIZE)
        public static let fileOptimalBlockSize = Self.file(ATTR_FILE_IOBLOCKSIZE)
        public static let fileDataForkLogicalSize = Self.file(ATTR_FILE_DATALENGTH)
        public static let fileDataForkPhysicalSize = Self.file(ATTR_FILE_DATAALLOCSIZE)
        public static let fileResourceForkLogicalSize = Self.file(ATTR_FILE_RSRCLENGTH)
        public static let fileResourceForkPhysicalSize = Self.file(ATTR_FILE_RSRCALLOCSIZE)
        public static let fileDeviceType = Self.file(ATTR_FILE_DEVTYPE)
        public static let directoryLinkCount = Self.dir(ATTR_DIR_LINKCOUNT)
        public static let directoryEntryCount = Self.dir(ATTR_DIR_ENTRYCOUNT)
        public static let directoryMountStatus = Self.dir(ATTR_DIR_MOUNTSTATUS)
        public static let directoryAllocationSize = Self.dir(ATTR_DIR_ALLOCSIZE)
        public static let directoryOptimalBlockSize = Self.dir(ATTR_DIR_IOBLOCKSIZE)
        public static let directoryLogicalSize = Self.dir(ATTR_DIR_DATALENGTH)
        public static let volumeSignature = Self.vol(ATTR_VOL_SIGNATURE)
        public static let volumeSize = Self.vol(ATTR_VOL_SIZE)
        public static let volumeFreeSpace = Self.vol(ATTR_VOL_SPACEFREE)
        public static let volumeAvailableSpace = Self.vol(ATTR_VOL_SPACEAVAIL)
        public static let volumeSpaceUsed = Self.vol(ATTR_VOL_SPACEUSED)
        public static let volumeMinAllocationSize = Self.vol(ATTR_VOL_MINALLOCATION)
        public static let volumeAllocationClumpSize = Self.vol(ATTR_VOL_ALLOCATIONCLUMP)
        public static let volumeOptimalBlockSize = Self.vol(ATTR_VOL_IOBLOCKSIZE)
        public static let volumeObjectCount = Self.vol(ATTR_VOL_OBJCOUNT)
        public static let volumeFileCount = Self.vol(ATTR_VOL_FILECOUNT)
        public static let volumeDirectoryCount = Self.vol(ATTR_VOL_DIRCOUNT)
        public static let volumeMaxObjectCount = Self.vol(ATTR_VOL_MAXOBJCOUNT)
        public static let volumeMountPoint = Self.vol(ATTR_VOL_MOUNTPOINT)
        public static let volumeName = Self.vol(ATTR_VOL_NAME)
        public static let volumeMountFlags = Self.vol(ATTR_VOL_MOUNTFLAGS)
        public static let volumeMountedDevice = Self.vol(ATTR_VOL_MOUNTEDDEVICE)
        public static let volumeEncodingsUsed = Self.vol(ATTR_VOL_ENCODINGSUSED)
        public static let volumeUUID = Self.vol(ATTR_VOL_UUID)
        public static let volumeFileSystemTypeName = Self.vol(ATTR_VOL_FSTYPENAME)
        public static let volumeFileSystemSubtype = Self.vol(ATTR_VOL_FSSUBTYPE)
        public static let volumeQuotaSize = Self.vol(ATTR_VOL_QUOTA_SIZE)
        public static let volumeReservedSize = Self.vol(ATTR_VOL_RESERVED_SIZE)
        public static let volumeCapabilities = Self.vol(ATTR_VOL_CAPABILITIES)
        public static let volumeSupportedKeys = Self.vol(ATTR_VOL_ATTRIBUTES)

        internal static func common(_ attr: some BinaryInteger) -> Keys {
            Keys(rawValue: attribute_set_t(commonattr: attrgroup_t(attr), volattr: 0, dirattr: 0, fileattr: 0, forkattr: 0))
        }

        internal static func vol(_ attr: some BinaryInteger) -> Keys {
            Keys(rawValue: attribute_set_t(commonattr: 0, volattr: attrgroup_t(attr), dirattr: 0, fileattr: 0, forkattr: 0))
        }

        internal static func dir(_ attr: some BinaryInteger) -> Keys {
            Keys(rawValue: attribute_set_t(commonattr: 0, volattr: 0, dirattr: attrgroup_t(attr), fileattr: 0, forkattr: 0))
        }

        internal static func file(_ attr: some BinaryInteger) -> Keys {
            Keys(rawValue: attribute_set_t(commonattr: 0, volattr: 0, dirattr: 0, fileattr: attrgroup_t(attr), forkattr: 0))
        }

        internal static func fork(_ attr: some BinaryInteger) -> Keys {
            Keys(rawValue: attribute_set_t(commonattr: 0, volattr: 0, dirattr: 0, fileattr: 0, forkattr: attrgroup_t(attr)))
        }

        public init() {
            self.init(rawValue: attribute_set_t())
        }

        public mutating func formUnion(_ other: Keys) {
            self = Keys(rawValue: attribute_set_t(
                commonattr: self.rawValue.commonattr | other.rawValue.commonattr,
                volattr: self.rawValue.volattr | other.rawValue.volattr,
                dirattr: self.rawValue.dirattr | other.rawValue.dirattr,
                fileattr: self.rawValue.fileattr | other.rawValue.fileattr,
                forkattr: self.rawValue.forkattr | other.rawValue.forkattr)
            )
        }

        public mutating func formIntersection(_ other: Keys) {
            self = Keys(rawValue: attribute_set_t(
                commonattr: self.rawValue.commonattr & other.rawValue.commonattr,
                volattr: self.rawValue.volattr & other.rawValue.volattr,
                dirattr: self.rawValue.dirattr & other.rawValue.dirattr,
                fileattr: self.rawValue.fileattr & other.rawValue.fileattr,
                forkattr: self.rawValue.forkattr & other.rawValue.forkattr)
            )
        }

        public mutating func formSymmetricDifference(_ other: Keys) {
            self = Keys(rawValue: attribute_set_t(
                commonattr: self.rawValue.commonattr ^ other.rawValue.commonattr,
                volattr: self.rawValue.volattr ^ other.rawValue.volattr,
                dirattr: self.rawValue.dirattr ^ other.rawValue.dirattr,
                fileattr: self.rawValue.fileattr ^ other.rawValue.fileattr,
                forkattr: self.rawValue.forkattr ^ other.rawValue.forkattr)
            )
        }

        public static func ==(lhs: Keys, rhs: Keys) -> Bool {
            lhs.rawValue.commonattr == rhs.rawValue.commonattr &&
                lhs.rawValue.dirattr == rhs.rawValue.dirattr &&
                lhs.rawValue.fileattr == rhs.rawValue.fileattr &&
                lhs.rawValue.volattr == rhs.rawValue.volattr &&
                lhs.rawValue.forkattr == rhs.rawValue.forkattr
        }

        public let rawValue: attribute_set_t
        public init(rawValue: attribute_set_t) {
            // sanitize the attribute set
            var attrs = rawValue

            let linkID = attrgroup_t(bitPattern: ATTR_CMNEXT_LINKID)
            let objID = attrgroup_t(bitPattern: ATTR_CMN_OBJID)

            attrs.commonattr |= attrgroup_t(ATTR_CMN_RETURNED_ATTRS)

            if attrs.forkattr & linkID != 0 || attrs.commonattr & objID != 0 {
                attrs.forkattr |= linkID
                attrs.commonattr &= ~objID
            }

            if attrs.volattr != 0 {
                attrs.volattr |= attrgroup_t(ATTR_VOL_INFO)
            }

            self.rawValue = attrs
        }

        internal var attrList: attrlist {
            attrlist(
                bitmapcount: u_short(ATTR_BIT_MAP_COUNT),
                reserved: 0,
                commonattr: self.rawValue.commonattr,
                volattr: self.rawValue.volattr,
                dirattr: self.rawValue.dirattr,
                fileattr: self.rawValue.fileattr,
                forkattr: self.rawValue.forkattr
            )
        }
    }
}

#endif
