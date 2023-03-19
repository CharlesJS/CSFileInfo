//
//  FileInfo.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 2/28/12.
//  Copyright © 2012-2023 Charles Srstka. All rights reserved.
//

import CSDataProtocol
import CSErrors
import DataParser
import System

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

public struct FileInfo {
    public let filename: String?
    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public var path: FilePath? { self.pathString.map { FilePath($0) } }
    public let pathString: String?
    public let mountRelativePath: String?
    public let deviceID: dev_t?
    public let fileSystemID: fsid_t?
    public let objectType: ObjectType?
    public let objectTag: ObjectTag?
    public let inode: ino_t?
    public let parentInode: ino_t?
    public let linkID: UInt64?
    public var script: text_encoding_t?
    public var creationTime: timespec?
    public var modificationTime: timespec?
    public let attributeModificationTime: timespec?
    public var accessTime: timespec?
    public var backupTime: timespec?
    public var addedTime: timespec?
    private var _finderInfo: FinderInfo?
    public var finderInfo: FinderInfo? {
        get { self._finderInfo }
        set {
            guard let newValue else {
                self._finderInfo = nil
                return
            }

            let objectType = self.objectType ?? .regular
            let mountStatus = self.directoryMountStatus ?? []

            var info = self._finderInfo

            if info == nil {
                info = FinderInfo(data: [], objectType: objectType, mountStatus: mountStatus)
            }

            info!.update(from: newValue, objectType: objectType, mountStatus: mountStatus)

            Self.sync(finderInfo: &info, posixFlags: &self.posixFlags, favorPosix: false)

            self._finderInfo = info
        }
    }
    public var owner: User? {
        get {
            if let uuid = self.ownerUUID, case .user(let user) = try? UserOrGroup(uuid: uuid) {
                return user
            }

            if let id = self.ownerID {
                return User(id: id)
            }

            return nil
        }
        set {
            if let owner = newValue {
                self.ownerID = owner.id
                self.ownerUUID = try? owner.uuid
            } else {
                self.ownerID = nil
                self.ownerUUID = nil
            }
        }
    }
    public var ownerName: String? { try? self.owner?.name }
    public var ownerID: uid_t?
    public var ownerUUID: uuid_t?
    public var groupOwner: Group? {
        get {
            if let uuid = self.groupOwnerUUID, case .group(let group) = try? UserOrGroup(uuid: uuid) {
                return group
            }

            if let id = self.groupOwnerID {
                return Group(id: id)
            }

            return nil
        }
        set {
            if let group = newValue {
                self.groupOwnerID = group.id
                self.groupOwnerUUID = try? group.uuid
            } else {
                self.groupOwnerID = nil
                self.groupOwnerUUID = nil
            }
        }
    }
    public var groupOwnerName: String? { try? self.groupOwner?.name }
    public var groupOwnerID: gid_t?
    public var groupOwnerUUID: uuid_t?
    public var permissionsMode: mode_t?
    public var accessControlList: AccessControlList?
    private var _posixFlags: POSIXFlags?
    public var posixFlags: POSIXFlags? {
        get { self._posixFlags }
        set {
            if newValue != self._posixFlags {
                var flags = newValue

                Self.sync(finderInfo: &self.finderInfo, posixFlags: &flags, favorPosix: true)

                self._posixFlags = flags
            }
        }
    }
    public let generationCount: UInt32?
    public let documentID: UInt32?
    public let userAccess: UserAccess?
    public var protectionFlags: UInt32?
    public let privateSize: off_t?
    public let fileLinkCount: UInt32?
    public let fileTotalLogicalSize: off_t?
    public let fileTotalPhysicalSize: off_t?
    public let fileOptimalBlockSize: UInt32?
    public let fileAllocationClumpSize: UInt32?
    public let fileDataForkLogicalSize: off_t?
    public let fileDataForkPhysicalSize: off_t?
    public let fileResourceForkLogicalSize: off_t?
    public let fileResourceForkPhysicalSize: off_t?
    public var fileDeviceType: UInt32?
    public let fileForkCount: UInt32?
    public let directoryLinkCount: UInt32?
    public let directoryEntryCount: UInt32?
    public let directoryMountStatus: MountStatus?
    public let directoryAllocationSize: off_t?
    public let directoryOptimalBlockSize: UInt32?
    public let directoryLogicalSize: off_t?
    public let volumeSignature: UInt32?
    public let volumeSize: off_t?
    public let volumeFreeSpace: off_t?
    public let volumeAvailableSpace: off_t?
    public let volumeMinAllocationSize: off_t?
    public let volumeAllocationClumpSize: off_t?
    public let volumeOptimalBlockSize: UInt32?
    public let volumeObjectCount: UInt32?
    public let volumeFileCount: UInt32?
    public let volumeDirectoryCount: UInt32?
    public let volumeMaxObjectCount: UInt32?
    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public var volumeMountPoint: FilePath? { self.volumeMountPointPathString.map { FilePath($0) } }
    public let volumeMountPointPathString: String?
    public var volumeName: String?
    public let volumeMountFlags: UInt32?
    public let volumeMountedDevice: String?
    public let volumeEncodingsUsed: CUnsignedLongLong?
    public let volumeUUID: uuid_t?
    public let volumeQuotaSize: off_t?
    public let volumeReservedSize: off_t?
    public let volumeCapabilities: VolumeCapabilities?
    public let fileSystemValidCapabilities: VolumeCapabilities?
    public let volumeSupportedKeys: Keys?
    public let fileSystemValidKeys: Keys?

    private static func sync(finderInfo _fi: inout FinderInfo?, posixFlags _pf: inout POSIXFlags?, favorPosix: Bool) {
        guard var finderInfo = _fi, let posixFlags = _pf else { return }

        if favorPosix {
            if posixFlags.contains(.isHidden) && !finderInfo.finderFlags.contains(.isInvisible) {
                finderInfo.finderFlags.insert(.isInvisible)
                _fi = finderInfo
            } else if finderInfo.finderFlags.contains(.isInvisible) {
                finderInfo.finderFlags.remove(.isInvisible)
                _fi = finderInfo
            }
        } else {
            if finderInfo.finderFlags.contains(.isInvisible) && !posixFlags.contains(.isHidden) {
                _pf = posixFlags.union(.isHidden)
            } else if posixFlags.contains(.isHidden) {
                _pf = posixFlags.subtracting(.isHidden)
            }
        }
    }

    public init() {
        self.filename = nil
        self.pathString = nil
        self.mountRelativePath = nil
        self.deviceID = nil
        self.fileSystemID = nil
        self.objectType = nil
        self.objectTag = nil
        self.linkID = nil
        self.script = nil
        self.creationTime = nil
        self.modificationTime = nil
        self.attributeModificationTime = nil
        self.accessTime = nil
        self.backupTime = nil
        self.addedTime = nil
        self.generationCount = nil
        self.documentID = nil
        self.userAccess = nil
        self.inode = nil
        self.parentInode = nil
        self.protectionFlags = nil
        self.privateSize = nil
        self.fileLinkCount = nil
        self.fileTotalLogicalSize = nil
        self.fileTotalPhysicalSize = nil
        self.fileOptimalBlockSize = nil
        self.fileAllocationClumpSize = nil
        self.fileDataForkLogicalSize = nil
        self.fileDataForkPhysicalSize = nil
        self.fileResourceForkLogicalSize = nil
        self.fileResourceForkPhysicalSize = nil
        self.fileDeviceType = nil
        self.fileForkCount = nil
        self.directoryLinkCount = nil
        self.directoryEntryCount = nil
        self.directoryMountStatus = nil
        self.directoryAllocationSize = nil
        self.directoryOptimalBlockSize = nil
        self.directoryLogicalSize = nil
        self.volumeSignature = nil
        self.volumeSize = nil
        self.volumeFreeSpace = nil
        self.volumeAvailableSpace = nil
        self.volumeMinAllocationSize = nil
        self.volumeAllocationClumpSize = nil
        self.volumeOptimalBlockSize = nil
        self.volumeObjectCount = nil
        self.volumeFileCount = nil
        self.volumeDirectoryCount = nil
        self.volumeMaxObjectCount = nil
        self.volumeMountPointPathString = nil
        self.volumeName = nil
        self.volumeMountFlags = nil
        self.volumeMountedDevice = nil
        self.volumeEncodingsUsed = nil
        self.volumeUUID = nil
        self.volumeQuotaSize = nil
        self.volumeReservedSize = nil
        self.volumeCapabilities = nil
        self.fileSystemValidCapabilities = nil
        self.volumeSupportedKeys = nil
        self.fileSystemValidKeys = nil
    }

    
    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public init(path: FilePath, keys: Keys) throws {
        let pathString: String
        let attrList: ContiguousArray<UInt8>

        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12) {
            pathString = path.string
            attrList = try path.withPlatformString { cPath in
                try Self.getAttrList(path: pathString, keys: keys) { getattrlist(cPath, $0, $1, $2, $3) }
            }
        } else {
            pathString = String(decoding: path)
            attrList = try path.withCString { cPath in
                try Self.getAttrList(path: pathString, keys: keys) { getattrlist(cPath, $0, $1, $2, $3) }
            }
        }

        try self.init(path: pathString, attrList: attrList)
    }

    public init(path: String, keys: Keys) throws {
        let attrList: ContiguousArray<UInt8>

        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12) {
            attrList = try path.withPlatformString { cPath in
                try Self.getAttrList(path: path, keys: keys) { getattrlist(cPath, $0, $1, $2, $3) }
            }
        } else {
            attrList = try path.withCString { cPath in
                try Self.getAttrList(path: path, keys: keys) { getattrlist(cPath, $0, $1, $2, $3) }
            }
        }

        try self.init(path: path, attrList: attrList)
    }

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public init(fileDescriptor: FileDescriptor, keys: Keys) throws {
        try self.init(fileDescriptor: fileDescriptor.rawValue, keys: keys)
    }

    public init(fileDescriptor fd: Int32, keys: Keys) throws {
        let attrList = try Self.getAttrList(path: nil, keys: keys) { fgetattrlist(fd, $0, $1, $2, $3) }
        try self.init(path: nil, attrList: attrList)
    }

    private static func getAttrList(
        path: String?,
        keys: Keys,
        getFunc: (UnsafeMutableRawPointer, UnsafeMutableRawPointer, Int, UInt32) -> Int32
    ) throws -> ContiguousArray<UInt8> {
        let fixedKeys: Keys = {
            if keys.contains(.finderInfo) {
                return keys.union([.objectType, .directoryMountStatus])
            } else if keys.contains(.url) {
                return keys.union(.objectType)
            } else {
                return keys
            }
        }()

        var requestedAttrs = fixedKeys.attrList
        let opts = UInt32(FSOPT_NOFOLLOW) | (requestedAttrs.forkattr != 0 ? UInt32(FSOPT_ATTR_CMN_EXTENDED) : 0)

        var bufsize: UInt32 = 0
        try callPOSIXFunction(expect: .zero, path: path) {
            getFunc(&requestedAttrs, &bufsize, MemoryLayout<UInt32>.size, UInt32(FSOPT_REPORT_FULLSIZE) | opts)
        }

        if bufsize < MemoryLayout<UInt32>.size { throw errno(EFTYPE, path: path) }

        return try ContiguousArray<UInt8>(unsafeUninitializedCapacity: Int(bufsize)) { buf, count in
            try callPOSIXFunction(expect: .zero, path: path) { getFunc(&requestedAttrs, buf.baseAddress!, buf.count, opts) }
            count = buf.count
        }
    }

    private init(path: String?, attrList: ContiguousArray<UInt8>) throws {
        var parser = DataParser(attrList)

        func readAttr<T>(_ type: T.Type) throws -> T {
            try parser.withUnsafeBytes(count: MemoryLayout<T>.size) {
                $0.withMemoryRebound(to: T.self) { $0[0] }
            }
        }

        func readAttr<T>(group: attrgroup_t, tag: Int32, type: T.Type) throws -> T? {
            (group & attrgroup_t(tag) != 0) ? try readAttr(type) : nil
        }

        func readData(group: attrgroup_t, tag: Int32, count: Int) throws -> (some DataProtocol)? {
            (group & attrgroup_t(tag) != 0) ? try parser.readBytes(count: count) : nil
        }

        func readVariableLengthData(group: attrgroup_t, tag: Int32) throws -> (some DataProtocol)? {
            var newParser = parser

            return try readAttr(group: group, tag: tag, type: attrreference.self).map {
                try newParser.skipBytes($0.attr_dataoffset)
                return try newParser.readBytes(count: $0.attr_length)
            }
        }

        func readString(group: attrgroup_t, tag: Int32) throws -> String? {
            try readVariableLengthData(group: group, tag: tag).map {
                String(decoding: $0, as: UTF8.self)
            }
        }

        func readTime(group: attrgroup_t, tag: Int32) throws -> timespec? {
            try readAttr(group: group, tag: tag, type: timespec.self)
        }

        let attrs = try readAttr(attribute_set_t.self)

        self.filename = try readString(group: attrs.commonattr, tag: ATTR_CMN_NAME)
        self.deviceID = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_DEVID, type: dev_t.self)
        self.fileSystemID = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_FSID, type: fsid_t.self)
        let objectType = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_OBJTYPE, type: fsobj_type_t.self).map {
            ObjectType($0)
        }
        self.objectType = objectType
        self.objectTag = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_OBJTAG, type: fsobj_tag_t.self).map {
            ObjectTag($0)
        }
        let objectID = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_OBJID, type: fsobj_id_t.self)
        self.script = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_SCRIPT, type: text_encoding_t.self)
        self.creationTime = try readTime(group: attrs.commonattr, tag: ATTR_CMN_CRTIME)
        self.modificationTime = try readTime(group: attrs.commonattr, tag: ATTR_CMN_MODTIME)
        self.attributeModificationTime = try readTime(group: attrs.commonattr, tag: ATTR_CMN_CHGTIME)
        self.accessTime = try readTime(group: attrs.commonattr, tag: ATTR_CMN_ACCTIME)
        self.backupTime = try readTime(group: attrs.commonattr, tag: ATTR_CMN_BKUPTIME)
        let finderInfoData = try readData(group: attrs.commonattr, tag: ATTR_CMN_FNDRINFO, count: 32)
        self.ownerID = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_OWNERID, type: uid_t.self)
        self.groupOwnerID = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_GRPID, type: gid_t.self)
        self.permissionsMode = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_ACCESSMASK, type: UInt32.self).map {
            mode_t($0 & 0o7777)
        }
        var posixFlags = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_FLAGS, type: UInt32.self).map {
            POSIXFlags(rawValue: $0)
        }
        self.generationCount = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_GEN_COUNT, type: UInt32.self)
        self.documentID = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_DOCUMENT_ID, type: UInt32.self)
        self.userAccess = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_USERACCESS, type: UInt32.self).map {
            UserAccess(rawValue: $0)
        }
        self.accessControlList = try readVariableLengthData(group: attrs.commonattr, tag: ATTR_CMN_EXTENDED_SECURITY).map {
            try AccessControlList(data: $0, nativeRepresentation: true, isDirectory: objectType == .directory)
        }
        self.ownerUUID = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_UUID, type: guid_t.self).map(\.g_guid)
        self.groupOwnerUUID = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_GRPUUID, type: guid_t.self).map(\.g_guid)
        self.inode = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_FILEID, type: UInt64.self).map { ino_t($0) }
        self.parentInode = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_PARENTID, type: UInt64.self).map { ino_t($0) }
        self.pathString = try readString(group: attrs.commonattr, tag: ATTR_CMN_FULLPATH)
        self.addedTime = try readTime(group: attrs.commonattr, tag: ATTR_CMN_ADDEDTIME)
        self.protectionFlags = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_DATA_PROTECT_FLAGS, type: UInt32.self)

        self.volumeSignature = try readAttr(group: attrs.volattr, tag: ATTR_VOL_SIGNATURE, type: UInt32.self)
        self.volumeSize = try readAttr(group: attrs.volattr, tag: ATTR_VOL_SIZE, type: off_t.self)
        self.volumeFreeSpace = try readAttr(group: attrs.volattr, tag: ATTR_VOL_SPACEFREE, type: off_t.self)
        self.volumeAvailableSpace = try readAttr(group: attrs.volattr, tag: ATTR_VOL_SPACEAVAIL, type: off_t.self)
        self.volumeMinAllocationSize = try readAttr(group: attrs.volattr, tag: ATTR_VOL_MINALLOCATION, type: off_t.self)
        self.volumeAllocationClumpSize = try readAttr(group: attrs.volattr, tag: ATTR_VOL_ALLOCATIONCLUMP, type: off_t.self)
        self.volumeOptimalBlockSize = try readAttr(group: attrs.volattr, tag: ATTR_VOL_IOBLOCKSIZE, type: UInt32.self)
        self.volumeObjectCount = try readAttr(group: attrs.volattr, tag: ATTR_VOL_OBJCOUNT, type: UInt32.self)
        self.volumeFileCount = try readAttr(group: attrs.volattr, tag: ATTR_VOL_FILECOUNT, type: UInt32.self)
        self.volumeDirectoryCount = try readAttr(group: attrs.volattr, tag: ATTR_VOL_DIRCOUNT, type: UInt32.self)
        self.volumeMaxObjectCount = try readAttr(group: attrs.volattr, tag: ATTR_VOL_MAXOBJCOUNT, type: UInt32.self)
        self.volumeMountPointPathString = try readString(group: attrs.volattr, tag: ATTR_VOL_MOUNTPOINT)
        self.volumeName = try readString(group: attrs.volattr, tag: ATTR_VOL_NAME)
        self.volumeMountFlags = try readAttr(group: attrs.volattr, tag: ATTR_VOL_MOUNTFLAGS, type: UInt32.self)
        self.volumeMountedDevice = try readString(group: attrs.volattr, tag: ATTR_VOL_MOUNTEDDEVICE)
        self.volumeEncodingsUsed = try readAttr(group: attrs.volattr, tag: ATTR_VOL_ENCODINGSUSED, type: CUnsignedLongLong.self)
        if let caps = try readAttr(group: attrs.volattr, tag: ATTR_VOL_CAPABILITIES, type: vol_capabilities_attr_t.self) {
            self.volumeCapabilities = VolumeCapabilities(capabilities: caps, validOnly: false)
            self.fileSystemValidCapabilities = VolumeCapabilities(capabilities: caps, validOnly: true)
        } else {
            self.volumeCapabilities = nil
            self.fileSystemValidCapabilities = nil
        }
        self.volumeUUID = try readAttr(group: attrs.volattr, tag: ATTR_VOL_UUID, type: uuid_t.self)
        self.volumeQuotaSize = try readAttr(group: attrs.volattr, tag: ATTR_VOL_QUOTA_SIZE, type: off_t.self)
        self.volumeReservedSize = try readAttr(group: attrs.volattr, tag: ATTR_VOL_RESERVED_SIZE, type: off_t.self)
        if let attrs = try readAttr(group: attrs.volattr, tag: ATTR_VOL_ATTRIBUTES, type: vol_attributes_attr_t.self) {
            self.volumeSupportedKeys = Keys(rawValue: attrs.nativeattr).intersection(Keys(rawValue: attrs.validattr))
            self.fileSystemValidKeys = Keys(rawValue: attrs.validattr)
        } else {
            self.volumeSupportedKeys = nil
            self.fileSystemValidKeys = nil
        }

        self.directoryLinkCount = try readAttr(group: attrs.dirattr, tag: ATTR_DIR_LINKCOUNT, type: UInt32.self)
        self.directoryEntryCount = try readAttr(group: attrs.dirattr, tag: ATTR_DIR_ENTRYCOUNT, type: UInt32.self)
        let mountStatus = try readAttr(group: attrs.dirattr, tag: ATTR_DIR_MOUNTSTATUS, type: UInt32.self).map {
            MountStatus(rawValue: $0)
        }
        self.directoryMountStatus = mountStatus
        self.directoryAllocationSize = try readAttr(group: attrs.dirattr, tag: ATTR_DIR_ALLOCSIZE, type: off_t.self)
        self.directoryOptimalBlockSize = try readAttr(group: attrs.dirattr, tag: ATTR_DIR_IOBLOCKSIZE, type: UInt32.self)
        self.directoryLogicalSize = try readAttr(group: attrs.dirattr, tag: ATTR_DIR_DATALENGTH, type: off_t.self)

        self.fileLinkCount = try readAttr(group: attrs.fileattr, tag: ATTR_FILE_LINKCOUNT, type: UInt32.self)
        self.fileTotalLogicalSize = try readAttr(group: attrs.fileattr, tag: ATTR_FILE_TOTALSIZE, type: off_t.self)
        self.fileTotalPhysicalSize = try readAttr(group: attrs.fileattr, tag: ATTR_FILE_ALLOCSIZE, type: off_t.self)
        self.fileOptimalBlockSize = try readAttr(group: attrs.fileattr, tag: ATTR_FILE_IOBLOCKSIZE, type: UInt32.self)
        self.fileAllocationClumpSize = try readAttr(group: attrs.fileattr, tag: ATTR_FILE_CLUMPSIZE, type: UInt32.self)
        self.fileDeviceType = try readAttr(group: attrs.fileattr, tag: ATTR_FILE_DEVTYPE, type: UInt32.self)
        self.fileForkCount = try readAttr(group: attrs.fileattr, tag: ATTR_FILE_FORKCOUNT, type: UInt32.self)
        self.fileDataForkLogicalSize = try readAttr(group: attrs.fileattr, tag: ATTR_FILE_DATALENGTH, type: off_t.self)
        self.fileDataForkPhysicalSize = try readAttr(group: attrs.fileattr, tag: ATTR_FILE_DATAALLOCSIZE, type: off_t.self)
        self.fileResourceForkLogicalSize = try readAttr(group: attrs.fileattr, tag: ATTR_FILE_RSRCLENGTH, type: off_t.self)
        self.fileResourceForkPhysicalSize = try readAttr(group: attrs.fileattr, tag: ATTR_FILE_RSRCALLOCSIZE, type: off_t.self)

        self.mountRelativePath = try readString(group: attrs.forkattr, tag: ATTR_CMNEXT_RELPATH)
        self.privateSize = try readAttr(group: attrs.forkattr, tag: ATTR_CMNEXT_PRIVATESIZE, type: off_t.self)

        self.linkID = try readAttr(group: attrs.forkattr, tag: ATTR_CMNEXT_LINKID, type: UInt64.self) ?? objectID.map {
            UInt64($0.fid_objno)
        }

        var finderInfo = finderInfoData.map { FinderInfo(data: $0, objectType: objectType!, mountStatus: mountStatus ?? []) }
        Self.sync(finderInfo: &finderInfo, posixFlags: &posixFlags, favorPosix: posixFlags != nil)
        self.finderInfo = finderInfo
        self.posixFlags = posixFlags
    }

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public func apply(to path: FilePath) throws {
        guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *) else {
            try path.withCString { try self.apply(path: String(decoding: path), cPath: $0) }
            return
        }

        try path.withPlatformString { try self.apply(path: path.string, cPath: $0) }
    }

    public func apply(toPath path: String) throws {
        guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *) else {
            try path.withCString { try self.apply(path: path, cPath: $0) }
            return
        }

        try path.withPlatformString { try self.apply(path: path, cPath: $0) }
    }

    private func apply(path: String, cPath: UnsafePointer<CChar>) throws {
        var (attrlist: attrs, data: data, opts: opts) = try self.generateStructuresForWriting()

        try data.withUnsafeMutableBytes { outBuf in
            _ = try callPOSIXFunction(expect: .zero, path: path, isWrite: true) {
                setattrlist(cPath, &attrs, outBuf.baseAddress, outBuf.count, opts)
            }
        }
    }

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public func apply(to fileDescriptor: FileDescriptor) throws {
        try self.apply(toFileDescriptor: fileDescriptor.rawValue)
    }

    public func apply(toFileDescriptor fd: Int32) throws {
        var (attrlist: attrs, data: data, opts: opts) = try self.generateStructuresForWriting()

        try data.withUnsafeMutableBytes { outBuf in
            _ = try callPOSIXFunction(expect: .zero, isWrite: true) {
                fsetattrlist(fd, &attrs, outBuf.baseAddress, outBuf.count, opts)
            }
        }
    }

    private func generateStructuresForWriting() throws -> (attrlist: attrlist, data: ContiguousArray<UInt8>, opts: UInt32) {
        var attrs = attrlist(
            bitmapcount: u_short(ATTR_BIT_MAP_COUNT),
            reserved: 0,
            commonattr: 0,
            volattr: 0,
            dirattr: 0,
            fileattr: 0,
            forkattr: 0
        )

        var attrData: ContiguousArray<UInt8> = []
        var trailerData: ContiguousArray<UInt8> = []
        var attrRefOffsets: ContiguousArray<Int> = []

        func writeAttr<T>(_ attr: T?, group: inout attrgroup_t, tag: Int32) {
            if var attr {
                group |= attrgroup_t(tag)
                withUnsafeBytes(of: &attr) { attrData.append(contentsOf: $0) }
            }
        }

        func writeFixedLengthData(_ data: (some DataProtocol)?, group: inout attrgroup_t, tag: Int32) {
            if let data = data {
                group |= attrgroup_t(tag)
                attrData += data
            }
        }

        func writeVariableLengthData(_ data: (some DataProtocol)?, group: inout attrgroup_t, tag: Int32) throws {
            if let data {
                guard data.count <= UInt32.max, trailerData.count <= Int32.max else { throw errno(EINVAL) }

                let attrRef = attrreference(attr_dataoffset: Int32(trailerData.count), attr_length: UInt32(data.count))

                attrRefOffsets.append(attrData.count)
                trailerData += data
                writeAttr(attrRef, group: &group, tag: tag)
            }
        }

        func writeString(_ string: String?, group: inout attrgroup_t, tag: Int32) throws {
            if var string {
                try string.withUTF8 { try writeVariableLengthData($0, group: &group, tag: tag) }
            }
        }

        writeAttr(self.script, group: &attrs.commonattr, tag: ATTR_CMN_SCRIPT)
        writeAttr(self.creationTime, group: &attrs.commonattr, tag: ATTR_CMN_CRTIME)
        writeAttr(self.modificationTime, group: &attrs.commonattr, tag: ATTR_CMN_MODTIME)
        writeAttr(self.accessTime, group: &attrs.commonattr, tag: ATTR_CMN_ACCTIME)
        writeAttr(self.backupTime, group: &attrs.commonattr, tag: ATTR_CMN_BKUPTIME)
        writeFixedLengthData(self.finderInfo?.data, group: &attrs.commonattr, tag: ATTR_CMN_FNDRINFO)
        writeAttr(self.ownerID, group: &attrs.commonattr, tag: ATTR_CMN_OWNERID)
        writeAttr(self.groupOwnerID, group: &attrs.commonattr, tag: ATTR_CMN_GRPID)
        writeAttr(self.permissionsMode.map { UInt32($0) }, group: &attrs.commonattr, tag: ATTR_CMN_ACCESSMASK)
        writeAttr(self.posixFlags?.rawValue, group: &attrs.commonattr, tag: ATTR_CMN_FLAGS)
        try writeVariableLengthData(
            self.accessControlList?.dataRepresentation(native: true),
            group: &attrs.commonattr,
            tag: ATTR_CMN_EXTENDED_SECURITY
        )
        writeAttr(self.ownerUUID, group: &attrs.commonattr, tag: ATTR_CMN_UUID)
        writeAttr(self.groupOwnerUUID, group: &attrs.commonattr, tag: ATTR_CMN_GRPUUID)
        writeAttr(self.addedTime, group: &attrs.commonattr, tag: ATTR_CMN_ADDEDTIME)
        writeAttr(self.protectionFlags, group: &attrs.commonattr, tag: ATTR_CMN_DATA_PROTECT_FLAGS)

        try writeString(self.volumeName, group: &attrs.volattr, tag: ATTR_VOL_NAME)

        writeAttr(self.fileDeviceType, group: &attrs.fileattr, tag: ATTR_FILE_DEVTYPE)

        try attrData.withUnsafeMutableBytes { attrBuf in
            for eachOffset in attrRefOffsets {
                try (attrBuf.baseAddress! + eachOffset).withMemoryRebound(to: attrreference.self, capacity: 1) { attrPtr in
                    let adjustedOffset = Int(attrPtr.pointee.attr_dataoffset) + attrBuf.count - eachOffset
                    guard adjustedOffset <= Int32.max else { throw errno(EINVAL) }

                    attrPtr.pointee.attr_dataoffset = Int32(adjustedOffset)
                }
            }
        }

        if attrs.volattr != 0 { attrs.volattr |= attrgroup_t(ATTR_VOL_INFO) }

        return (attrlist: attrs, data: attrData + trailerData, opts: UInt32(FSOPT_NOFOLLOW))
    }
}

extension FileInfo: Equatable {
    public static func ==(lhs: FileInfo, rhs: FileInfo) -> Bool {
        func compareTimes(_ l: timespec?, _ r: timespec?) -> Bool {
            l?.tv_sec == r?.tv_sec && l?.tv_nsec == r?.tv_nsec
        }

        func compareUUIDs(_ l: uuid_t?, _ r: uuid_t?) -> Bool {
            guard var l, var r else { return (l != nil) == (r != nil) }
            return uuid_compare(&l, &r) == 0
        }

        if rhs.filename != rhs.filename { return false }
        if lhs.pathString != rhs.pathString { return false }
        if lhs.mountRelativePath != rhs.mountRelativePath { return false }
        if lhs.deviceID != rhs.deviceID { return false }
        if lhs.fileSystemID != rhs.fileSystemID { return false }
        if lhs.objectType != rhs.objectType { return false }
        if lhs.objectTag != rhs.objectTag { return false }
        if lhs.inode != rhs.inode { return false }
        if lhs.parentInode != rhs.parentInode { return false }
        if lhs.linkID != rhs.linkID { return false }
        if lhs.script != rhs.script { return false }
        if !compareTimes(lhs.creationTime, rhs.creationTime) { return false }
        if !compareTimes(lhs.modificationTime, rhs.modificationTime) { return false }
        if !compareTimes(lhs.attributeModificationTime, rhs.attributeModificationTime) { return false }
        if !compareTimes(lhs.accessTime, rhs.accessTime) { return false }
        if !compareTimes(lhs.backupTime, rhs.backupTime) { return false }
        if !compareTimes(lhs.addedTime, rhs.addedTime) { return false }
        if lhs.finderInfo != rhs.finderInfo { return false }
        if lhs.ownerID != rhs.ownerID { return false }
        if !compareUUIDs(lhs.ownerUUID, rhs.ownerUUID) { return false }
        if lhs.groupOwnerID != rhs.groupOwnerID { return false }
        if !compareUUIDs(lhs.groupOwnerUUID, rhs.groupOwnerUUID) { return false }
        if lhs.permissionsMode != rhs.permissionsMode { return false }
        if lhs.accessControlList != rhs.accessControlList { return false }
        if lhs.posixFlags != rhs.posixFlags { return false }
        if lhs.generationCount != rhs.generationCount { return false }
        if lhs.documentID != rhs.documentID { return false }
        if lhs.userAccess != rhs.userAccess { return false }
        if lhs.protectionFlags != rhs.protectionFlags { return false }
        if lhs.privateSize != rhs.privateSize { return false }
        if lhs.fileLinkCount != rhs.fileLinkCount { return false }
        if lhs.fileTotalLogicalSize != rhs.fileTotalLogicalSize { return false }
        if lhs.fileTotalPhysicalSize != rhs.fileTotalPhysicalSize { return false }
        if lhs.fileOptimalBlockSize != rhs.fileOptimalBlockSize { return false }
        if lhs.fileAllocationClumpSize != rhs.fileAllocationClumpSize { return false }
        if lhs.fileDataForkLogicalSize != rhs.fileDataForkLogicalSize { return false }
        if lhs.fileDataForkPhysicalSize != rhs.fileDataForkPhysicalSize { return false }
        if lhs.fileResourceForkLogicalSize != rhs.fileResourceForkLogicalSize { return false }
        if lhs.fileResourceForkPhysicalSize != rhs.fileResourceForkPhysicalSize { return false }
        if lhs.fileDeviceType != rhs.fileDeviceType { return false }
        if lhs.fileForkCount != rhs.fileForkCount { return false }
        if lhs.directoryLinkCount != rhs.directoryLinkCount { return false }
        if lhs.directoryEntryCount != rhs.directoryEntryCount { return false }
        if lhs.directoryMountStatus != rhs.directoryMountStatus { return false }
        if lhs.directoryAllocationSize != rhs.directoryAllocationSize { return false }
        if lhs.directoryOptimalBlockSize != rhs.directoryOptimalBlockSize { return false }
        if lhs.directoryLogicalSize != rhs.directoryLogicalSize { return false }
        if lhs.volumeSignature != rhs.volumeSignature { return false }
        if lhs.volumeSize != rhs.volumeSize { return false }
        if lhs.volumeFreeSpace != rhs.volumeFreeSpace { return false }
        if lhs.volumeAvailableSpace != rhs.volumeAvailableSpace { return false }
        if lhs.volumeMinAllocationSize != rhs.volumeMinAllocationSize { return false }
        if lhs.volumeAllocationClumpSize != rhs.volumeAllocationClumpSize { return false }
        if lhs.volumeOptimalBlockSize != rhs.volumeOptimalBlockSize { return false }
        if lhs.volumeObjectCount != rhs.volumeObjectCount { return false }
        if lhs.volumeFileCount != rhs.volumeFileCount { return false }
        if lhs.volumeDirectoryCount != rhs.volumeDirectoryCount { return false }
        if lhs.volumeMaxObjectCount != rhs.volumeMaxObjectCount { return false }
        if lhs.volumeMountPointPathString != rhs.volumeMountPointPathString { return false }
        if lhs.volumeName != rhs.volumeName { return false }
        if lhs.volumeMountFlags != rhs.volumeMountFlags { return false }
        if lhs.volumeMountedDevice != rhs.volumeMountedDevice { return false }
        if lhs.volumeEncodingsUsed != rhs.volumeEncodingsUsed { return false }
        if !compareUUIDs(lhs.volumeUUID, rhs.volumeUUID) { return false }
        if lhs.volumeQuotaSize != rhs.volumeQuotaSize { return false }
        if lhs.volumeReservedSize != rhs.volumeReservedSize { return false }
        if lhs.volumeCapabilities != rhs.volumeCapabilities { return false }
        if lhs.fileSystemValidCapabilities != rhs.fileSystemValidCapabilities { return false }
        if lhs.volumeSupportedKeys != rhs.volumeSupportedKeys { return false }
        if lhs.fileSystemValidKeys != rhs.fileSystemValidKeys { return false }

        return true
    }
}
