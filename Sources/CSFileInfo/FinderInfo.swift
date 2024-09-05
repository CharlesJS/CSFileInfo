//
//  FinderInfo.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 11/5/17.
//

import DataParser
import CSDataProtocol

extension FileInfo {
    public struct FinderInfo: Codable, Sendable {
        public enum LabelColor: UInt8, Sendable {
            case none = 0
            case grey = 1
            case green = 2
            case purple = 3
            case blue = 4
            case yellow = 5
            case red = 6
            case orange = 7
        }

        public struct Rect: Codable, Equatable, Sendable {
            public static let zero = Rect(top: 0, left: 0, bottom: 0, right: 0)

            public let top: Int16
            public let left: Int16
            public let bottom: Int16
            public let right: Int16

            public var data: some DataProtocol {
                ContiguousArray<UInt8>(unsafeUninitializedCapacity: 8) { byteBuffer, count in
                    byteBuffer.withMemoryRebound(to: Int16.self) { buffer in
                        buffer[0] = self.top.bigEndian
                        buffer[1] = self.left.bigEndian
                        buffer[2] = self.bottom.bigEndian
                        buffer[3] = self.right.bigEndian
                    }

                    count = 8
                }
            }

            public init(top: Int16, left: Int16, bottom: Int16, right: Int16) {
                self.top = top
                self.left = left
                self.bottom = bottom
                self.right = right
            }

            internal init<T>(parser: inout DataParser<T>) throws {
                self.top = try parser.readInt16(byteOrder: .big)
                self.left = try parser.readInt16(byteOrder: .big)
                self.bottom = try parser.readInt16(byteOrder: .big)
                self.right = try parser.readInt16(byteOrder: .big)
            }
        }

        public struct Point: Codable, Equatable, Sendable {
            public static let zero = Point(v: 0, h: 0)

            public let v: Int16
            public let h: Int16

            public var data: some DataProtocol {
                ContiguousArray<UInt8>(unsafeUninitializedCapacity: 4) { byteBuffer, count in
                    byteBuffer.withMemoryRebound(to: Int16.self) { buffer in
                        buffer[0] = self.v.bigEndian
                        buffer[1] = self.h.bigEndian
                    }

                    count = 4
                }
            }

            public init(v: Int16, h: Int16) {
                self.v = v
                self.h = h
            }

            internal init<T>(parser: inout DataParser<T>) throws {
                self.v = try parser.readInt16(byteOrder: .big)
                self.h = try parser.readInt16(byteOrder: .big)
            }
        }

        private struct PseudoTypeCode {
            public static let symbolicLink: UInt32 = 0x736c6e6b // 'slnk'
            public static let directory: UInt32 = 0x666f6c64 // 'fold'
            public static let volume: UInt32 = 0x6469736b // 'disk'
        }

        private struct PseudoCreatorCode {
            public static let symbolicLink: UInt32 = 0x72686170  // 'rhap'
            public static let volumeOrDirectory: UInt32 = 0x4d414353 // 'MACS'
        }

        public struct FinderFlags: OptionSet, Codable, Sendable {
            public static let isOnDesktop               = FinderFlags(rawValue: 0x0001)
            private static let colorMask                = UInt16(0x000e)
            public static let isExtensionHidden         = FinderFlags(rawValue: 0x0010)
            public static let isShared                  = FinderFlags(rawValue: 0x0040)
            public static let hasNoINITs                = FinderFlags(rawValue: 0x0080)
            public static let hasBeenInited             = FinderFlags(rawValue: 0x0100)
            public static let hasCustomIcon             = FinderFlags(rawValue: 0x0400)
            public static let isStationery              = FinderFlags(rawValue: 0x0800)
            public static let isNameLocked              = FinderFlags(rawValue: 0x1000)
            public static let hasBundle                 = FinderFlags(rawValue: 0x2000)
            public static let isInvisible               = FinderFlags(rawValue: 0x4000)
            public static let isAlias                   = FinderFlags(rawValue: 0x8000)

            public var labelColor: LabelColor {
                get { LabelColor(rawValue: UInt8((self.rawValue & FinderFlags.colorMask) >> 1))! }
                set {
                    self.rawValue = (self.rawValue & ~FinderFlags.colorMask) |
                    (UInt16(newValue.rawValue << 1) & FinderFlags.colorMask)
                }
            }

            public init(
                isOnDesktop: Bool = false,
                labelColor: LabelColor = .none,
                isExtensionHidden: Bool = false,
                isShared: Bool = false,
                hasNoINITs: Bool = false,
                hasBeenInited: Bool = false,
                hasCustomIcon: Bool = false,
                isStationery: Bool = false,
                isNameLocked: Bool = false,
                hasBundle: Bool = false,
                isInvisible: Bool = false,
                isAlias: Bool = false
            ) {
                self = []

                if isOnDesktop { self.insert(.isOnDesktop) }
                self.labelColor = labelColor
                if isExtensionHidden { self.insert(.isExtensionHidden) }
                if isShared { self.insert(.isShared) }
                if hasNoINITs { self.insert(.hasNoINITs) }
                if hasBeenInited { self.insert(.hasBeenInited) }
                if hasCustomIcon { self.insert(.hasCustomIcon) }
                if isStationery { self.insert(.isStationery) }
                if isNameLocked { self.insert(.isNameLocked) }
                if hasBundle { self.insert(.hasBundle) }
                if isInvisible { self.insert(.isInvisible) }
                if isAlias { self.insert(.isAlias) }
            }

            public var rawValue: UInt16
            public init(rawValue: UInt16) { self.rawValue = rawValue }
        }

        public struct ExtendedFinderFlags: OptionSet, Codable, Sendable {
            public static let extendedFlagsAreInvalid = ExtendedFinderFlags(rawValue: 0x8000)
            public static let hasCustomBadge          = ExtendedFinderFlags(rawValue: 0x0100)
            public static let isBusy                  = ExtendedFinderFlags(rawValue: 0x0080)
            public static let hasRoutingInfo          = ExtendedFinderFlags(rawValue: 0x0004)

            init(extendedFlagsAreInvalid: Bool, hasCustomBadge: Bool, isBusy: Bool, hasRoutingInfo: Bool) {
                self = []

                if extendedFlagsAreInvalid { self.insert(.extendedFlagsAreInvalid) }
                if hasCustomBadge { self.insert(.hasCustomBadge) }
                if isBusy { self.insert(.isBusy) }
                if hasRoutingInfo { self.insert(.hasRoutingInfo) }
            }

            public var rawValue: UInt16
            public init(rawValue: UInt16) { self.rawValue = rawValue }
        }

        private var typeSpecificData: TypeSpecificData
        private enum TypeSpecificData: Codable {
            case file(isSymbolicLink: Bool, typeCode: UInt32, creatorCode: UInt32, reserved: UInt64)
            case directory(isMountPoint: Bool, windowBounds: Rect, scrollPosition: Point, reserved: UInt32)

            init(objectType: ObjectType, mountStatus: MountStatus, data: some Collection<UInt8>) throws {
                var parser = DataParser(data)

                switch objectType {
                case .directory:
                    let isMountPoint = mountStatus.contains(.isMountPoint)
                    let windowBounds = try Rect(parser: &parser)
                    try parser.skipBytes(8)
                    let scrollPosition = try Point(parser: &parser)
                    let rsrv = try parser.readUInt32(byteOrder: .big)

                    self = .directory(
                        isMountPoint: isMountPoint,
                        windowBounds: windowBounds,
                        scrollPosition: scrollPosition,
                        reserved: rsrv
                    )
                case .symbolicLink:
                    try parser.skipBytes(16)
                    let rsrv = try parser.readUInt64(byteOrder: .big)

                    self = .file(isSymbolicLink: true, typeCode: 0, creatorCode: 0, reserved: rsrv)
                default:
                    let type = try parser.readUInt32(byteOrder: .big)
                    let creator = try parser.readUInt32(byteOrder: .big)
                    try parser.skipBytes(8)
                    let rsrv = try parser.readUInt64(byteOrder: .big)

                    self = .file(isSymbolicLink: false, typeCode: type, creatorCode: creator, reserved: rsrv)
                }
            }

            var data: some DataProtocol {
                switch self {
                case .file(isSymbolicLink: _, typeCode: let type, creatorCode: let creator, reserved: let rsrv):

                    var data = ContiguousArray<UInt8>(repeating: 0, count: 32)

                    data.withUnsafeMutableBytes { buffer in
                        buffer.storeBytes(of: type.bigEndian, toByteOffset: 0, as: UInt32.self)
                        buffer.storeBytes(of: creator.bigEndian, toByteOffset: 4, as: UInt32.self)
                        buffer.storeBytes(of: rsrv.bigEndian, toByteOffset: 16, as: UInt64.self)
                    }

                    return data
                case .directory(isMountPoint: _, windowBounds: let wb, scrollPosition: let sp, reserved: let rsrv):
                    var data: ContiguousArray<UInt8> = []

                    data.append(contentsOf: wb.data)
                    data.append(contentsOf: repeatElement(0, count: 8))
                    data.append(contentsOf: sp.data)

                    var bigRsrv = rsrv.bigEndian
                    withUnsafeBytes(of: &bigRsrv) { data.append(contentsOf: $0) }

                    data.append(contentsOf: repeatElement(0, count: 8))

                    assert(data.count == 32)

                    return data
                }
            }

            var isDirectory: Bool {
                switch self {
                case .file:
                    return false
                case .directory:
                    return true
                }
            }
        }

        internal var directoryStatus: (isDirectory: Bool, isMountPoint: Bool) {
            switch self.typeSpecificData {
            case let .directory(isMountPoint: isMountPoint, windowBounds: _, scrollPosition: _, reserved: _):
                return (isDirectory: true, isMountPoint: isMountPoint)
            case .file:
                return (isDirectory: false, isMountPoint: false)
            }
        }

        public var type: String {
            get { String(hfsTypeCode: self.typeCode) }
            set { self.typeCode = (try? self.fixTypeCode(newValue, isCreator: false))?.hfsTypeCode ?? 0 }
        }

        public var typeCode: UInt32 {
            get {
                switch self.typeSpecificData {
                case let .file(isSymbolicLink: isSymbolicLink, typeCode: typeCode, creatorCode: _, reserved: _):
                    return isSymbolicLink ? PseudoTypeCode.symbolicLink : typeCode
                case let .directory(isMountPoint: isMountPoint, windowBounds: _, scrollPosition: _, reserved: _):
                    return isMountPoint ? PseudoTypeCode.volume : PseudoTypeCode.directory
                }
            }
            set {
                switch self.typeSpecificData {
                case let .file(isSymbolicLink: isLink, typeCode: _, creatorCode: creator, reserved: rsrv) where !isLink:
                    self.typeSpecificData = .file(
                        isSymbolicLink: isLink,
                        typeCode: newValue,
                        creatorCode: creator,
                        reserved: rsrv
                    )
                default:
                    break
                }
            }
        }
        public var creator: String {
            get { String(hfsTypeCode: self.creatorCode) }
            set { self.creatorCode = (try? self.fixTypeCode(newValue, isCreator: true))?.hfsTypeCode ?? 0 }
        }

        public var creatorCode: UInt32 {
            get {
                switch self.typeSpecificData {
                case let .file(isSymbolicLink: isSymbolicLink, typeCode: _, creatorCode: creator, reserved: _):
                    return isSymbolicLink ? PseudoCreatorCode.symbolicLink : creator
                case .directory:
                    return PseudoCreatorCode.volumeOrDirectory
                }
            }
            set {
                switch self.typeSpecificData {
                case let .file(isSymbolicLink: isLink, typeCode: type, creatorCode: _, reserved: rsrv) where !isLink:
                    self.typeSpecificData = .file(
                        isSymbolicLink: isLink,
                        typeCode: type,
                        creatorCode: newValue,
                        reserved: rsrv
                    )
                default:
                    break
                }
            }
        }

        private var hasFakeTypeAndCreator: Bool {
            switch self.typeSpecificData {
            case let .file(isSymbolicLink: isLink, typeCode: _, creatorCode: _, reserved: _) where !isLink:
                return false
            default:
                return true
            }
        }

        private func fixTypeCode(_ type: String, isCreator: Bool) throws -> String {
            if self.hasFakeTypeAndCreator {
                return isCreator ? self.creator : self.type
            }

            if type.isEmpty {
                return ""
            }

            guard let code = type.hfsTypeCode else {
                throw isCreator ? Error.invalidCreatorCode(type) : Error.invalidTypeCode(type)
            }

            return String(hfsTypeCode: code)
        }

        public var finderFlags: FinderFlags
        public var extendedFinderFlags: ExtendedFinderFlags
        public var iconLocation: Point
        public var windowBounds: Rect {
            get {
                switch self.typeSpecificData {
                case .directory(isMountPoint: _, windowBounds: let bounds, scrollPosition: _, reserved: _):
                    return bounds
                default:
                    return .zero
                }
            }
            set {
                switch self.typeSpecificData {
                case .directory(isMountPoint: let mp, windowBounds: _, scrollPosition: let sp, reserved: let rsrv):
                    self.typeSpecificData = .directory(
                        isMountPoint: mp,
                        windowBounds: newValue,
                        scrollPosition: sp,
                        reserved: rsrv
                    )
                default: break
                }
            }
        }
        public var scrollPosition: Point {
            get {
                switch self.typeSpecificData {
                case .directory(isMountPoint: _, windowBounds: _, scrollPosition: let position, reserved: _):
                    return position
                default:
                    return .zero
                }
            }
            set {
                switch self.typeSpecificData {
                case .directory(isMountPoint: let mp, windowBounds: let wb, scrollPosition: _, reserved: let rsrv):
                    self.typeSpecificData = .directory(
                        isMountPoint: mp,
                        windowBounds: wb,
                        scrollPosition: newValue,
                        reserved: rsrv
                    )
                default: break
                }
            }
        }
        public var putAwayFolderID: UInt32
        private var reservedFinderInfo: UInt16
        private var reservedExtendedFinderInfo: UInt16

        public var data: some DataProtocol {
            var data: ContiguousArray<UInt8> = []

            switch self.typeSpecificData {
            case let .file(isSymbolicLink: isSymbolicLink, typeCode: type, creatorCode: creator, reserved: _):
                data.append(isSymbolicLink ? 0 : type, byteOrder: .big)
                data.append(isSymbolicLink ? 0 : creator, byteOrder: .big)
            case let .directory(isMountPoint: _, windowBounds: windowBounds, scrollPosition: _, reserved: _):
                data += windowBounds.data
            }

            data.append(self.finderFlags.rawValue, byteOrder: .big)
            data += self.iconLocation.data

            data.append(self.reservedFinderInfo, byteOrder: .big)

            switch self.typeSpecificData {
            case let .file(isSymbolicLink: _, typeCode: _, creatorCode: _, reserved: rsrv):
                data.append(rsrv, byteOrder: .big)
            case let .directory(isMountPoint: _, windowBounds: _, scrollPosition: scrollPosition, reserved: rsrv):
                data += scrollPosition.data
                data.append(rsrv, byteOrder: .big)
            }

            data.append(self.extendedFinderFlags.rawValue, byteOrder: .big)
            data.append(self.reservedExtendedFinderInfo, byteOrder: .big)
            data.append(self.putAwayFolderID, byteOrder: .big)

            assert(data.count == 32)

            return data
        }

        internal init(
            isDirectory: Bool,
            isSymbolicLink: Bool = false,
            isMountPoint: Bool = false,
            typeCode: UInt32 = 0,
            creatorCode: UInt32 = 0,
            finderFlags: FinderFlags = [],
            extendedFinderFlags: ExtendedFinderFlags = [],
            iconLocation: Point = .zero,
            windowBounds: Rect = .zero,
            scrollPosition: Point = .zero,
            putAwayFolderID: UInt32 = 0
        ) {
            self.typeSpecificData = {
                if isDirectory {
                    return .directory(isMountPoint: isMountPoint, windowBounds: windowBounds, scrollPosition: scrollPosition, reserved: 0)
                } else {
                    return .file(isSymbolicLink: isSymbolicLink, typeCode: typeCode, creatorCode: creatorCode, reserved: 0)
                }
            }()
            self.finderFlags = finderFlags
            self.extendedFinderFlags = extendedFinderFlags
            self.iconLocation = iconLocation
            self.putAwayFolderID = putAwayFolderID
            self.reservedFinderInfo = 0
            self.reservedExtendedFinderInfo = 0
        }

        public init(
            data: some Collection<UInt8> = [],
            objectType: ObjectType = .regular,
            mountStatus: MountStatus = []
        ) {
            // As long as the data is sufficiently long, the initializer should never fail, so we can use `try!`

            if data.count < 32 {
                let padded = ContiguousArray(data) + repeatElement(0, count: 32 - data.count)
                try! self.init(paddedData: padded, objectType: objectType, mountStatus: mountStatus)
            } else {
                try! self.init(paddedData: data, objectType: objectType, mountStatus: mountStatus)
            }
        }

        private init(
            paddedData: some Collection<UInt8> = [],
            objectType: ObjectType = .regular,
            mountStatus: MountStatus = []
        ) throws {
            self.typeSpecificData = try TypeSpecificData(objectType: objectType, mountStatus: mountStatus, data: paddedData)

            var parser = DataParser(paddedData)
            try parser.skipBytes(8)

            self.finderFlags = FinderFlags(rawValue: try parser.readUInt16(byteOrder: .big))
            self.iconLocation = try Point(parser: &parser)
            self.reservedFinderInfo = try parser.readUInt16(byteOrder: .big)

            try parser.skipBytes(8)

            self.extendedFinderFlags = ExtendedFinderFlags(rawValue: try parser.readUInt16(byteOrder: .big))
            self.reservedExtendedFinderInfo = try parser.readUInt16(byteOrder: .big)
            self.putAwayFolderID = try parser.readUInt32(byteOrder: .big)
        }

        internal mutating func update(from: FinderInfo, objectType: ObjectType, mountStatus: MountStatus) {
            var newInfo = from
            let isDirectory = (objectType == .directory)

            if newInfo.typeSpecificData.isDirectory != isDirectory {
                let data = newInfo.typeSpecificData.data

                // This initializer can only fail from insufficient data count, which should be impossible here
                newInfo.typeSpecificData = try! .init(objectType: objectType, mountStatus: mountStatus, data: data)
            }

            self = newInfo
        }
    }
}

extension FileInfo.FinderInfo: Equatable {
    public static func ==(lhs: FileInfo.FinderInfo, rhs: FileInfo.FinderInfo) -> Bool {
        ContiguousArray(lhs.data) == ContiguousArray(rhs.data) &&
        lhs.typeSpecificData.isDirectory == rhs.typeSpecificData.isDirectory
    }
}

