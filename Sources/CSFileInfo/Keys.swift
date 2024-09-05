//
//  Keys.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 11/4/17.
//

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

extension FileInfo {
    public struct Keys: OptionSet, Sendable {
        public static let all: Keys = [.allCommon, .allFile, .allDirectory, .allVolume]
        public static let allCommon = Keys.common(0x5fffff5f).union(Keys.fork(0x7fc))
        public static let allFile = Keys.file(0x362f)
        public static let allDirectory = Keys.dir(0x3f)
        public static let allVolume = Keys.vol(0xf0b7fffe)

        public static let filename = Keys.common(ATTR_CMN_NAME)
        public static let fullPath = Keys.common(ATTR_CMN_FULLPATH)
        public static let mountRelativePath = Keys.fork(ATTR_CMNEXT_RELPATH)
        public static let noFirmLinkPath = Keys.fork(ATTR_CMNEXT_NOFIRMLINKPATH)
        public static let deviceID = Keys.common(ATTR_CMN_DEVID)
        public static let realDeviceID = Keys.fork(ATTR_CMNEXT_REALDEVID)
        public static let fileSystemID = Keys.common(ATTR_CMN_FSID)
        public static let realFileSystemID = Keys.fork(ATTR_CMNEXT_REALFSID)
        public static let objectType = Keys.common(ATTR_CMN_OBJTYPE)
        public static let objectTag = Keys.common(ATTR_CMN_OBJTAG)
        public static let linkID = Keys.fork(ATTR_CMNEXT_LINKID)
        public static let inode = Keys.common(ATTR_CMN_FILEID)
        public static let persistentID = Keys.common(ATTR_CMN_OBJPERMANENTID)
        public static let cloneID = Keys.fork(ATTR_CMNEXT_CLONEID)
        public static let parentID = Keys.common(ATTR_CMN_PARENTID)
        public static let script = Keys.common(ATTR_CMN_SCRIPT)
        public static let creationTime = Keys.common(ATTR_CMN_CRTIME)
        public static let modificationTime = Keys.common(ATTR_CMN_MODTIME)
        public static let attributeModificationTime = Keys.common(ATTR_CMN_CHGTIME)
        public static let accessTime = Keys.common(ATTR_CMN_ACCTIME)
        public static let backupTime = Keys.common(ATTR_CMN_BKUPTIME)
        public static let addedTime = Keys.common(ATTR_CMN_ADDEDTIME)
        public static let finderInfo = Keys.common(ATTR_CMN_FNDRINFO)
        public static let ownerID = Keys.common(ATTR_CMN_OWNERID)
        public static let ownerUUID = Keys.common(ATTR_CMN_UUID)
        public static let groupOwnerID = Keys.common(ATTR_CMN_GRPID)
        public static let groupOwnerUUID = Keys.common(ATTR_CMN_GRPUUID)
        public static let permissionsMode = Keys.common(ATTR_CMN_ACCESSMASK)
        public static let accessControlList = Keys.common(ATTR_CMN_EXTENDED_SECURITY)
        public static let posixFlags = Keys.common(ATTR_CMN_FLAGS)
        public static let protectionFlags = Keys.common(ATTR_CMN_DATA_PROTECT_FLAGS)
        public static let extendedFlags = Keys.fork(ATTR_CMNEXT_EXT_FLAGS)
        public static let generationCount = Keys.common(ATTR_CMN_GEN_COUNT)
        public static let recursiveGenerationCount = Keys.fork(ATTR_CMNEXT_RECURSIVE_GENCOUNT)
        public static let documentID = Keys.common(ATTR_CMN_DOCUMENT_ID)
        public static let userAccess = Keys.common(ATTR_CMN_USERACCESS)
        public static let privateSize = Keys.fork(ATTR_CMNEXT_PRIVATESIZE)
        public static let fileLinkCount = Keys.file(ATTR_FILE_LINKCOUNT)
        public static let fileTotalLogicalSize = Keys.file(ATTR_FILE_TOTALSIZE)
        public static let fileTotalPhysicalSize = Keys.file(ATTR_FILE_ALLOCSIZE)
        public static let fileOptimalBlockSize = Keys.file(ATTR_FILE_IOBLOCKSIZE)
        public static let fileDataForkLogicalSize = Keys.file(ATTR_FILE_DATALENGTH)
        public static let fileDataForkPhysicalSize = Keys.file(ATTR_FILE_DATAALLOCSIZE)
        public static let fileResourceForkLogicalSize = Keys.file(ATTR_FILE_RSRCLENGTH)
        public static let fileResourceForkPhysicalSize = Keys.file(ATTR_FILE_RSRCALLOCSIZE)
        public static let fileDeviceType = Keys.file(ATTR_FILE_DEVTYPE)
        public static let directoryLinkCount = Keys.dir(ATTR_DIR_LINKCOUNT)
        public static let directoryEntryCount = Keys.dir(ATTR_DIR_ENTRYCOUNT)
        public static let directoryMountStatus = Keys.dir(ATTR_DIR_MOUNTSTATUS)
        public static let directoryAllocationSize = Keys.dir(ATTR_DIR_ALLOCSIZE)
        public static let directoryOptimalBlockSize = Keys.dir(ATTR_DIR_IOBLOCKSIZE)
        public static let directoryLogicalSize = Keys.dir(ATTR_DIR_DATALENGTH)
        public static let volumeSignature = Keys.vol(ATTR_VOL_SIGNATURE)
        public static let volumeSize = Keys.vol(ATTR_VOL_SIZE)
        public static let volumeFreeSpace = Keys.vol(ATTR_VOL_SPACEFREE)
        public static let volumeAvailableSpace = Keys.vol(ATTR_VOL_SPACEAVAIL)
        public static let volumeSpaceUsed = Keys.vol(ATTR_VOL_SPACEUSED)
        public static let volumeMinAllocationSize = Keys.vol(ATTR_VOL_MINALLOCATION)
        public static let volumeAllocationClumpSize = Keys.vol(ATTR_VOL_ALLOCATIONCLUMP)
        public static let volumeOptimalBlockSize = Keys.vol(ATTR_VOL_IOBLOCKSIZE)
        public static let volumeObjectCount = Keys.vol(ATTR_VOL_OBJCOUNT)
        public static let volumeFileCount = Keys.vol(ATTR_VOL_FILECOUNT)
        public static let volumeDirectoryCount = Keys.vol(ATTR_VOL_DIRCOUNT)
        public static let volumeMaxObjectCount = Keys.vol(ATTR_VOL_MAXOBJCOUNT)
        public static let volumeMountPoint = Keys.vol(ATTR_VOL_MOUNTPOINT)
        public static let volumeName = Keys.vol(ATTR_VOL_NAME)
        public static let volumeMountFlags = Keys.vol(ATTR_VOL_MOUNTFLAGS)
        public static let volumeMountedDevice = Keys.vol(ATTR_VOL_MOUNTEDDEVICE)
        public static let volumeEncodingsUsed = Keys.vol(ATTR_VOL_ENCODINGSUSED)
        public static let volumeUUID = Keys.vol(ATTR_VOL_UUID)
        public static let volumeFileSystemTypeName = Keys.vol(ATTR_VOL_FSTYPENAME)
        public static let volumeFileSystemSubtype = Keys.vol(ATTR_VOL_FSSUBTYPE)
        public static let volumeQuotaSize = Keys.vol(ATTR_VOL_QUOTA_SIZE)
        public static let volumeReservedSize = Keys.vol(ATTR_VOL_RESERVED_SIZE)
        public static let volumeCapabilities = Keys.vol(ATTR_VOL_CAPABILITIES)
        public static let volumeSupportedKeys = Keys.vol(ATTR_VOL_ATTRIBUTES)

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

