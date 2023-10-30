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
    public let noFirmLinkPath: String?
    public let deviceID: dev_t?
    public let realDeviceID: dev_t?
    public let fileSystemID: fsid_t?
    public let realFileSystemID: fsid_t?
    public let objectType: ObjectType?
    public let objectTag: ObjectTag?
    public let linkID: UInt64?
    public let inode: ino_t?
    public let persistentID: UInt64?
    public let cloneID: UInt64?
    public let parentID: UInt64?
    public var script: text_encoding_t?
    public var creationTime: timespec?
    public var modificationTime: timespec?
    public internal(set) var attributeModificationTime: timespec?
    public var accessTime: timespec?
    public var backupTime: timespec?
    public var addedTime: timespec?
    internal var _finderInfo: FinderInfo?
    public var finderInfo: FinderInfo? {
        get { self._finderInfo }
        set {
            guard let newValue else {
                self._finderInfo = nil
                return
            }

            let mountStatus = self.directoryMountStatus ?? []

            var info = self._finderInfo
            let objectType = self.objectType ?? .regular

            if info == nil {
                info = FinderInfo(data: [], objectType: objectType, mountStatus: mountStatus)
            }

            info!.update(from: newValue, objectType: objectType, mountStatus: mountStatus)

            Self.sync(finderInfo: &info, posixFlags: &self._posixFlags, favorPosix: false)

            self._finderInfo = info
        }
    }

    public var ownerID: uid_t?
    public var ownerUUID: uuid_t?
    public var groupOwnerID: gid_t?
    public var groupOwnerUUID: uuid_t?
    public var permissionsMode: mode_t?
    public var accessControlList: AccessControlList?

    internal var _posixFlags: POSIXFlags?
    public var posixFlags: POSIXFlags? {
        get { self._posixFlags }
        set {
            if newValue != self._posixFlags {
                var flags = newValue

                Self.sync(finderInfo: &self._finderInfo, posixFlags: &flags, favorPosix: true)

                self._posixFlags = flags
            }
        }
    }
    public var protectionFlags: UInt32?
    public var extendedFlags: ExtendedFlags?
    public let generationCount: UInt32?
    public let recursiveGenerationCount: UInt64?
    public let documentID: UInt32?
    public let userAccess: UserAccess?
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
    public let volumeSpaceUsed: off_t?
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
    public let volumeFileSystemTypeName: String?
    public let volumeFileSystemSubtype: UInt32?
    public let volumeQuotaSize: off_t?
    public let volumeReservedSize: off_t?
    public let volumeNativeCapabilities: VolumeCapabilities?
    public let volumeAllowedCapabilities: VolumeCapabilities?
    public let volumeNativelySupportedKeys: Keys?
    public let volumeAllowedKeys: Keys?

    private static func sync(finderInfo _fi: inout FinderInfo?, posixFlags _pf: inout POSIXFlags?, favorPosix: Bool) {
        guard var finderInfo = _fi, let posixFlags = _pf else { return }

        if favorPosix {
            if posixFlags.contains(.isHidden) {
                if !finderInfo.finderFlags.contains(.isInvisible) {
                    finderInfo.finderFlags.insert(.isInvisible)
                    _fi = finderInfo
                }
            } else if finderInfo.finderFlags.contains(.isInvisible) {
                finderInfo.finderFlags.remove(.isInvisible)
                _fi = finderInfo
            }
        } else {
            if finderInfo.finderFlags.contains(.isInvisible) {
                if !posixFlags.contains(.isHidden) {
                    _pf = posixFlags.union(.isHidden)
                }
            } else if posixFlags.contains(.isHidden) {
                _pf = posixFlags.subtracting(.isHidden)
            }
        }
    }

    public init() {
        self.init(
            filename: nil,
            pathString: nil,
            mountRelativePath: nil,
            noFirmLinkPath: nil,
            deviceID: nil,
            realDeviceID: nil,
            fileSystemID: nil,
            realFileSystemID: nil,
            objectType: nil,
            objectTag: nil,
            linkID: nil,
            persistentID: nil,
            inode: nil,
            cloneID: nil,
            parentID: nil,
            script: nil,
            creationTime: nil,
            modificationTime: nil,
            attributeModificationTime: nil,
            accessTime: nil,
            backupTime: nil,
            addedTime: nil,
            finderInfo: nil,
            ownerID: nil,
            ownerUUID: nil,
            groupOwnerID: nil,
            groupOwnerUUID: nil,
            permissionsMode: nil,
            accessControlList: nil,
            posixFlags: nil,
            extendedFlags: nil,
            generationCount: nil,
            recursiveGenerationCount: nil,
            documentID: nil,
            userAccess: nil,
            protectionFlags: nil,
            privateSize: nil,
            fileLinkCount: nil,
            fileTotalLogicalSize: nil,
            fileTotalPhysicalSize: nil,
            fileOptimalBlockSize: nil,
            fileAllocationClumpSize: nil,
            fileDataForkLogicalSize: nil,
            fileDataForkPhysicalSize: nil,
            fileResourceForkLogicalSize: nil,
            fileResourceForkPhysicalSize: nil,
            fileDeviceType: nil,
            directoryLinkCount: nil,
            directoryEntryCount: nil,
            directoryMountStatus: nil,
            directoryAllocationSize: nil,
            directoryOptimalBlockSize: nil,
            directoryLogicalSize: nil,
            volumeSignature: nil,
            volumeSize: nil,
            volumeFreeSpace: nil,
            volumeAvailableSpace: nil,
            volumeSpaceUsed: nil,
            volumeMinAllocationSize: nil,
            volumeAllocationClumpSize: nil,
            volumeOptimalBlockSize: nil,
            volumeObjectCount: nil,
            volumeFileCount: nil,
            volumeDirectoryCount: nil,
            volumeMaxObjectCount: nil,
            volumeMountPointPathString: nil,
            volumeName: nil,
            volumeMountFlags: nil,
            volumeMountedDevice: nil,
            volumeEncodingsUsed: nil,
            volumeUUID: nil,
            volumeFileSystemTypeName: nil,
            volumeFileSystemSubtype: nil,
            volumeQuotaSize: nil,
            volumeReservedSize: nil,
            volumeNativeCapabilities: nil,
            volumeAllowedCapabilities: nil,
            volumeNativelySupportedKeys: nil,
            volumeAllowedKeys: nil
        )
    }

    internal init(
        filename: String?,
        pathString: String?,
        mountRelativePath: String?,
        noFirmLinkPath: String?,
        deviceID: dev_t?,
        realDeviceID: dev_t?,
        fileSystemID: fsid_t?,
        realFileSystemID: fsid_t?,
        objectType: ObjectType?,
        objectTag: ObjectTag?,
        linkID: UInt64?,
        persistentID: UInt64?,
        inode: ino_t?,
        cloneID: UInt64?,
        parentID: UInt64?,
        script: text_encoding_t?,
        creationTime: timespec?,
        modificationTime: timespec?,
        attributeModificationTime: timespec?,
        accessTime: timespec?,
        backupTime: timespec?,
        addedTime: timespec?,
        finderInfo: FinderInfo?,
        ownerID: uid_t?,
        ownerUUID: uuid_t?,
        groupOwnerID: gid_t?,
        groupOwnerUUID: uuid_t?,
        permissionsMode: mode_t?,
        accessControlList: AccessControlList?,
        posixFlags: POSIXFlags?,
        extendedFlags: ExtendedFlags?,
        generationCount: UInt32?,
        recursiveGenerationCount: UInt64?,
        documentID: UInt32?,
        userAccess: UserAccess?,
        protectionFlags: UInt32?,
        privateSize: off_t?,
        fileLinkCount: UInt32?,
        fileTotalLogicalSize: off_t?,
        fileTotalPhysicalSize: off_t?,
        fileOptimalBlockSize: UInt32?,
        fileAllocationClumpSize: UInt32?,
        fileDataForkLogicalSize: off_t?,
        fileDataForkPhysicalSize: off_t?,
        fileResourceForkLogicalSize: off_t?,
        fileResourceForkPhysicalSize: off_t?,
        fileDeviceType: UInt32?,
        directoryLinkCount: UInt32?,
        directoryEntryCount: UInt32?,
        directoryMountStatus: MountStatus?,
        directoryAllocationSize: off_t?,
        directoryOptimalBlockSize: UInt32?,
        directoryLogicalSize: off_t?,
        volumeSignature: UInt32?,
        volumeSize: off_t?,
        volumeFreeSpace: off_t?,
        volumeAvailableSpace: off_t?,
        volumeSpaceUsed: off_t?,
        volumeMinAllocationSize: off_t?,
        volumeAllocationClumpSize: off_t?,
        volumeOptimalBlockSize: UInt32?,
        volumeObjectCount: UInt32?,
        volumeFileCount: UInt32?,
        volumeDirectoryCount: UInt32?,
        volumeMaxObjectCount: UInt32?,
        volumeMountPointPathString: String?,
        volumeName: String?,
        volumeMountFlags: UInt32?,
        volumeMountedDevice: String?,
        volumeEncodingsUsed: CUnsignedLongLong?,
        volumeUUID: uuid_t?,
        volumeFileSystemTypeName: String?,
        volumeFileSystemSubtype: UInt32?,
        volumeQuotaSize: off_t?,
        volumeReservedSize: off_t?,
        volumeNativeCapabilities: VolumeCapabilities?,
        volumeAllowedCapabilities: VolumeCapabilities?,
        volumeNativelySupportedKeys: Keys?,
        volumeAllowedKeys: Keys?
    ) {
        self.filename = filename
        self.pathString = pathString
        self.mountRelativePath = mountRelativePath
        self.noFirmLinkPath = noFirmLinkPath
        self.deviceID = deviceID
        self.realDeviceID = realDeviceID
        self.fileSystemID = fileSystemID
        self.realFileSystemID = realFileSystemID
        self.objectType = objectType
        self.objectTag = objectTag
        self.linkID = linkID
        self.persistentID = persistentID
        self.inode = inode
        self.cloneID = cloneID
        self.parentID = parentID
        self.script = script
        self.creationTime = creationTime
        self.modificationTime = modificationTime
        self.attributeModificationTime = attributeModificationTime
        self.accessTime = accessTime
        self.backupTime = backupTime
        self.addedTime = addedTime
        self._finderInfo = finderInfo
        self.ownerID = ownerID
        self.ownerUUID = ownerUUID
        self.groupOwnerID = groupOwnerID
        self.groupOwnerUUID = groupOwnerUUID
        self.permissionsMode = permissionsMode
        self.accessControlList = accessControlList
        self._posixFlags = posixFlags
        self.extendedFlags = extendedFlags
        self.generationCount = generationCount
        self.recursiveGenerationCount = recursiveGenerationCount
        self.documentID = documentID
        self.userAccess = userAccess
        self.protectionFlags = protectionFlags
        self.privateSize = privateSize
        self.fileLinkCount = fileLinkCount
        self.fileTotalLogicalSize = fileTotalLogicalSize
        self.fileTotalPhysicalSize = fileTotalPhysicalSize
        self.fileOptimalBlockSize = fileOptimalBlockSize
        self.fileAllocationClumpSize = fileAllocationClumpSize
        self.fileDataForkLogicalSize = fileDataForkLogicalSize
        self.fileDataForkPhysicalSize = fileDataForkPhysicalSize
        self.fileResourceForkLogicalSize = fileResourceForkLogicalSize
        self.fileResourceForkPhysicalSize = fileResourceForkPhysicalSize
        self.fileDeviceType = fileDeviceType
        self.directoryLinkCount = directoryLinkCount
        self.directoryEntryCount = directoryEntryCount
        self.directoryMountStatus = directoryMountStatus
        self.directoryAllocationSize = directoryAllocationSize
        self.directoryOptimalBlockSize = directoryOptimalBlockSize
        self.directoryLogicalSize = directoryLogicalSize
        self.volumeSignature = volumeSignature
        self.volumeSize = volumeSize
        self.volumeFreeSpace = volumeFreeSpace
        self.volumeAvailableSpace = volumeAvailableSpace
        self.volumeSpaceUsed = volumeSpaceUsed
        self.volumeMinAllocationSize = volumeMinAllocationSize
        self.volumeAllocationClumpSize = volumeAllocationClumpSize
        self.volumeOptimalBlockSize = volumeOptimalBlockSize
        self.volumeObjectCount = volumeObjectCount
        self.volumeFileCount = volumeFileCount
        self.volumeDirectoryCount = volumeDirectoryCount
        self.volumeMaxObjectCount = volumeMaxObjectCount
        self.volumeMountPointPathString = volumeMountPointPathString
        self.volumeName = volumeName
        self.volumeMountFlags = volumeMountFlags
        self.volumeMountedDevice = volumeMountedDevice
        self.volumeEncodingsUsed = volumeEncodingsUsed
        self.volumeUUID = volumeUUID
        self.volumeFileSystemTypeName = volumeFileSystemTypeName
        self.volumeFileSystemSubtype = volumeFileSystemSubtype
        self.volumeQuotaSize = volumeQuotaSize
        self.volumeReservedSize = volumeReservedSize
        self.volumeNativeCapabilities = volumeNativeCapabilities
        self.volumeAllowedCapabilities = volumeAllowedCapabilities
        self.volumeNativelySupportedKeys = volumeNativelySupportedKeys
        self.volumeAllowedKeys = volumeAllowedKeys
    }

    
    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public init(path: FilePath, keys: Keys) throws {
        let pathString: String
        let attrList: ContiguousArray<UInt8>
        let supports64BitObjectIDs: Bool

        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12) {
            pathString = path.string

            (attrList, supports64BitObjectIDs) = try path.withPlatformString { cPath in
                try Self.getAttrList(path: pathString, keys: keys) { getattrlist(cPath, $0, $1, $2, $3) }
            }
        } else {
            pathString = String(decoding: path)

            (attrList, supports64BitObjectIDs) = try path.withCString { cPath in
                try Self.getAttrList(path: pathString, keys: keys) { getattrlist(cPath, $0, $1, $2, $3) }
            }
        }

        try self.init(path: pathString, attrList: attrList, supports64BitObjectIDs: supports64BitObjectIDs)
    }

    public init(path: String, keys: Keys) throws {
        let attrList: ContiguousArray<UInt8>
        let supports64BitObjectIDs: Bool

        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12) {
            (attrList, supports64BitObjectIDs) = try path.withPlatformString { cPath in
                try Self.getAttrList(path: path, keys: keys) { getattrlist(cPath, $0, $1, $2, $3) }
            }
        } else {
            (attrList, supports64BitObjectIDs) = try path.withCString { cPath in
                try Self.getAttrList(path: path, keys: keys) { getattrlist(cPath, $0, $1, $2, $3) }
            }
        }

        try self.init(path: path, attrList: attrList, supports64BitObjectIDs: supports64BitObjectIDs)
    }

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public init(fileDescriptor: FileDescriptor, keys: Keys) throws {
        try self.init(fileDescriptor: fileDescriptor.rawValue, keys: keys)
    }

    public init(fileDescriptor fd: Int32, keys: Keys) throws {
        let (attrList, supports64BitObjectIDs) = try Self.getAttrList(fileDescriptor: fd, keys: keys) {
            fgetattrlist(fd, $0, $1, $2, $3)
        }

        try self.init(path: nil, attrList: attrList, supports64BitObjectIDs: supports64BitObjectIDs)
    }

    private static func getAttrList(
        path: String? = nil,
        fileDescriptor fd: Int32? = nil,
        keys: Keys,
        getFunc: (UnsafeMutableRawPointer, UnsafeMutableRawPointer, Int, UInt32) -> Int32
    ) throws -> (ContiguousArray<UInt8>, Bool) {
        let fixedKeys: Keys = {
            if keys.contains(.finderInfo) {
                return keys.union([.objectType, .directoryMountStatus])
            } else if keys.contains(.fullPath) {
                return keys.union(.objectType)
            } else {
                return keys
            }
        }()

        var requestedAttrs = fixedKeys.attrList
        let supports64BitIDs = try self.adjustFileIDAttrs(&requestedAttrs, path: path, fileDescriptor: fd)

        let opts = UInt32(FSOPT_NOFOLLOW) | (requestedAttrs.forkattr != 0 ? UInt32(FSOPT_ATTR_CMN_EXTENDED) : 0)

        var bufsize: UInt32 = 0
        try callPOSIXFunction(expect: .zero, path: path) {
            getFunc(&requestedAttrs, &bufsize, MemoryLayout<UInt32>.size, UInt32(FSOPT_REPORT_FULLSIZE) | opts)
        }

        precondition(bufsize >= MemoryLayout<UInt32>.size)

        let attrList = try ContiguousArray<UInt8>(unsafeUninitializedCapacity: Int(bufsize)) { buf, count in
            try callPOSIXFunction(expect: .zero, path: path) { getFunc(&requestedAttrs, buf.baseAddress!, buf.count, opts) }
            count = buf.count
        }

        return (attrList, supports64BitIDs)
    }

    private static func adjustFileIDAttrs(_ attrs: inout attrlist, path: String?, fileDescriptor: Int32?) throws -> Bool {
        let cmn32BitLinkID = UInt32(bitPattern: ATTR_CMN_OBJID)
        let fork64BitLinkID = UInt32(bitPattern: ATTR_CMNEXT_LINKID)
        let cmn32BitParentID = UInt32(bitPattern: ATTR_CMN_PAROBJID)
        let cmn64BitParentID = UInt32(bitPattern: ATTR_CMN_PARENTID)

        let requestLinkID = attrs.commonattr & cmn32BitLinkID != 0 || attrs.forkattr & fork64BitLinkID != 0
        let requestParentID = attrs.commonattr & (cmn32BitParentID | cmn64BitParentID) != 0

        if requestLinkID || requestParentID {
            let mountPoint = try self.getMountPoint(path: path, fileDescriptor: fileDescriptor)
            let volInfo = try FileInfo(path: mountPoint, keys: [.volumeCapabilities, .volumeSupportedKeys])

            let supports64BitLinkID = volInfo.volumeAllowedKeys?.contains(.fork(fork64BitLinkID)) ?? false
            let supports64BitParentID = volInfo.volumeAllowedKeys?.contains(.common(cmn64BitParentID)) ?? false
            let supports64BitObjectIDs = volInfo.volumeNativeCapabilities?.format.contains(.supports64BitObjectIDs) ?? false

            if requestLinkID && supports64BitLinkID {
                attrs.forkattr |= fork64BitLinkID
            } else {
                attrs.forkattr &= ~fork64BitLinkID
            }

            if requestLinkID && !supports64BitLinkID && !supports64BitObjectIDs {
                attrs.commonattr |= cmn32BitLinkID
            } else {
                attrs.commonattr &= ~cmn32BitLinkID
            }

            if requestParentID && supports64BitParentID {
                attrs.commonattr |= cmn64BitParentID
            } else {
                attrs.commonattr &= ~cmn64BitParentID
            }

            if requestParentID && !supports64BitParentID {
                attrs.commonattr |= cmn32BitParentID
            } else {
                attrs.commonattr &= ~cmn32BitParentID
            }

            return supports64BitObjectIDs
        }

        return false
    }

    private static func getMountPoint(path: String?, fileDescriptor fd: Int32?) throws -> String {
        var statfsBuf: statfs

        if let path {
            if #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, macCatalyst 15.0, *), versionCheck(12) {
                statfsBuf = try path.withPlatformString { cPath in
                    try callPOSIXFunction(expect: .zero, path: path) { statfs(cPath, $0) }
                }
            } else {
                statfsBuf = try path.withCString { cPath in
                    try callPOSIXFunction(expect: .zero, path: path) { statfs(cPath, $0) }
                }
            }
        } else if let fd {
            statfsBuf = try callPOSIXFunction(expect: .zero) { fstatfs(fd, $0) }
        } else {
            throw errno(EINVAL)
        }

        return withUnsafeBytes(of: &statfsBuf.f_mntonname) { nameBuf in
            if #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, macCatalyst 15.0, *), versionCheck(12) {
                return String(platformString: nameBuf.bindMemory(to: CInterop.PlatformChar.self).baseAddress!)
            } else {
                return String(cString: nameBuf.bindMemory(to: UInt8.self).baseAddress!)
            }
        }
    }

    private init(path: String?, attrList: ContiguousArray<UInt8>, supports64BitObjectIDs: Bool) throws {
        let length = attrList.withUnsafeBytes { $0.load(as: UInt32.self) }
        var parser = DataParser(attrList[4..<Int(length)])

        func readAttr<T>(_ type: T.Type) throws -> T {
            try parser.withUnsafeBytes(count: MemoryLayout<T>.size) {
                $0.loadUnaligned(as: T.self)
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
                var endIndex = $0.endIndex

                if let nullTerminator = $0.firstIndex(of: 0) {
                    endIndex = nullTerminator
                }

                return String(decoding: $0[..<endIndex], as: UTF8.self)
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
        let linkID32 = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_OBJID, type: fsobj_id_t.self)
        if supports64BitObjectIDs {
            self.persistentID = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_OBJPERMANENTID, type: UInt64.self)
        } else {
            let id = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_OBJPERMANENTID, type: fsobj_id_t.self)
            self.persistentID = id.map { UInt64($0.fid_objno) }
        }
        let parentID32 = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_PAROBJID, type: fsobj_id_t.self)
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
        let parentID64 = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_PARENTID, type: UInt64.self).map { UInt64($0) }
        self.pathString = try readString(group: attrs.commonattr, tag: ATTR_CMN_FULLPATH)
        self.addedTime = try readTime(group: attrs.commonattr, tag: ATTR_CMN_ADDEDTIME)
        self.protectionFlags = try readAttr(group: attrs.commonattr, tag: ATTR_CMN_DATA_PROTECT_FLAGS, type: UInt32.self)

        _ = try readAttr(group: attrs.volattr, tag: ATTR_VOL_FSTYPE, type: UInt32.self)
        self.volumeSignature = try readAttr(group: attrs.volattr, tag: ATTR_VOL_SIGNATURE, type: UInt32.self)
        self.volumeSize = try readAttr(group: attrs.volattr, tag: ATTR_VOL_SIZE, type: off_t.self)
        self.volumeFreeSpace = try readAttr(group: attrs.volattr, tag: ATTR_VOL_SPACEFREE, type: off_t.self)
        self.volumeAvailableSpace = try readAttr(group: attrs.volattr, tag: ATTR_VOL_SPACEAVAIL, type: off_t.self)
        self.volumeSpaceUsed = try readAttr(group: attrs.volattr, tag: ATTR_VOL_SPACEUSED, type: off_t.self)
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
        self.volumeEncodingsUsed = try readAttr(
            group: attrs.volattr,
            tag: ATTR_VOL_ENCODINGSUSED,
            type: CUnsignedLongLong.self
        )
        if let caps = try readAttr(group: attrs.volattr, tag: ATTR_VOL_CAPABILITIES, type: vol_capabilities_attr_t.self) {
            self.volumeNativeCapabilities = VolumeCapabilities(capabilities: caps, implementedOnly: true)
            self.volumeAllowedCapabilities = VolumeCapabilities(capabilities: caps, implementedOnly: false)
        } else {
            self.volumeNativeCapabilities = nil
            self.volumeAllowedCapabilities = nil
        }
        self.volumeUUID = try readAttr(group: attrs.volattr, tag: ATTR_VOL_UUID, type: uuid_t.self)
        self.volumeFileSystemTypeName = try readString(group: attrs.volattr, tag: ATTR_VOL_FSTYPENAME)
        self.volumeFileSystemSubtype = try readAttr(group: attrs.volattr, tag: ATTR_VOL_FSSUBTYPE, type: UInt32.self)
        self.volumeQuotaSize = try readAttr(group: attrs.volattr, tag: ATTR_VOL_QUOTA_SIZE, type: off_t.self)
        self.volumeReservedSize = try readAttr(group: attrs.volattr, tag: ATTR_VOL_RESERVED_SIZE, type: off_t.self)
        if let attrs = try readAttr(group: attrs.volattr, tag: ATTR_VOL_ATTRIBUTES, type: vol_attributes_attr_t.self) {
            self.volumeNativelySupportedKeys = Keys(rawValue: attrs.nativeattr).intersection(Keys(rawValue: attrs.validattr))
            self.volumeAllowedKeys = Keys(rawValue: attrs.validattr)
        } else {
            self.volumeNativelySupportedKeys = nil
            self.volumeAllowedKeys = nil
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
        _ = try readAttr(group: attrs.fileattr, tag: ATTR_FILE_FORKCOUNT, type: UInt32.self)
        self.fileDataForkLogicalSize = try readAttr(group: attrs.fileattr, tag: ATTR_FILE_DATALENGTH, type: off_t.self)
        self.fileDataForkPhysicalSize = try readAttr(group: attrs.fileattr, tag: ATTR_FILE_DATAALLOCSIZE, type: off_t.self)
        self.fileResourceForkLogicalSize = try readAttr(group: attrs.fileattr, tag: ATTR_FILE_RSRCLENGTH, type: off_t.self)
        self.fileResourceForkPhysicalSize = try readAttr(
            group: attrs.fileattr,
            tag: ATTR_FILE_RSRCALLOCSIZE,
            type: off_t.self
        )
        self.mountRelativePath = try readString(group: attrs.forkattr, tag: ATTR_CMNEXT_RELPATH)
        self.privateSize = try readAttr(group: attrs.forkattr, tag: ATTR_CMNEXT_PRIVATESIZE, type: off_t.self)
        let linkID64 = try readAttr(group: attrs.forkattr, tag: ATTR_CMNEXT_LINKID, type: UInt64.self)
        self.noFirmLinkPath = try readString(group: attrs.forkattr, tag: ATTR_CMNEXT_NOFIRMLINKPATH)
        self.realDeviceID = try readAttr(group: attrs.forkattr, tag: ATTR_CMNEXT_REALDEVID, type: dev_t.self)
        self.realFileSystemID = try readAttr(group: attrs.forkattr, tag: ATTR_CMNEXT_REALFSID, type: fsid_t.self)
        self.cloneID = try readAttr(group: attrs.forkattr, tag: ATTR_CMNEXT_CLONEID, type: UInt64.self)
        self.extendedFlags = try readAttr(group: attrs.forkattr, tag: ATTR_CMNEXT_EXT_FLAGS, type: UInt64.self).map {
            ExtendedFlags(rawValue: $0)
        }

        self.recursiveGenerationCount = try readAttr(
            group: attrs.forkattr,
            tag: ATTR_CMNEXT_RECURSIVE_GENCOUNT,
            type: UInt64.self
        )

        self.linkID = linkID64 ?? linkID32.map { UInt64($0.fid_objno) }
        self.parentID = parentID64 ?? parentID32.map { UInt64($0.fid_objno) }

        var finderInfo = finderInfoData.map { FinderInfo(data: $0, objectType: objectType!, mountStatus: mountStatus ?? []) }
        Self.sync(finderInfo: &finderInfo, posixFlags: &posixFlags, favorPosix: posixFlags != nil)
        self.finderInfo = finderInfo
        self.posixFlags = posixFlags
    }

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public func apply(to path: FilePath) throws {
        guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12) else {
            try path.withCString { try self.apply(path: String(decoding: path), cPath: $0) }
            return
        }

        try path.withPlatformString { try self.apply(path: path.string, cPath: $0) }
    }

    public func apply(toPath path: String) throws {
        guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12) else {
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
                let alignment = MemoryLayout<UInt32>.stride
                let remainder = data.count % alignment

                attrRefOffsets.append(attrData.count)
                trailerData += data

                if remainder != 0 {
                    trailerData += (0..<(alignment - remainder)).map { _ in 0 }
                }

                writeAttr(attrRef, group: &group, tag: tag)
            }
        }

        func writeString(_ string: String?, group: inout attrgroup_t, tag: Int32) throws {
            if var string {
                string += "\0"
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
