//
//  AccessControlList.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 5/28/12.
//
//

import CSDataProtocol
import CSErrors
import ExtrasBase64
import System

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

public struct AccessControlList: RangeReplaceableCollection, CustomStringConvertible {
    public typealias Element = Entry
    public typealias Index = Int

    public struct Entry: Hashable, CustomStringConvertible {
        public enum Rule: UInt8 {
            case allow = 1
            case deny = 2
        }

        public struct Permissions: OptionSet, Hashable, CustomStringConvertible {
            /// The following permissions apply only to files
            public static let readData = Permissions(ACL_READ_DATA)
            public static let writeData = Permissions(ACL_WRITE_DATA)
            public static let appendData = Permissions(ACL_APPEND_DATA)
            public static let execute = Permissions(ACL_EXECUTE)

            /// The following permissions apply only to directories
            public static let listDirectory = Permissions(ACL_LIST_DIRECTORY)
            public static let addFile = Permissions(ACL_ADD_FILE)
            public static let addSubdirectory = Permissions(ACL_ADD_SUBDIRECTORY)
            public static let search = Permissions(ACL_SEARCH)
            public static let deleteChild = Permissions(ACL_DELETE_CHILD)

            /// The following permissions apply to both files and directories
            public static let delete = Permissions(ACL_DELETE)
            public static let readAttributes = Permissions(ACL_READ_ATTRIBUTES)
            public static let writeAttributes = Permissions(ACL_WRITE_ATTRIBUTES)
            public static let readExtendedAttributes = Permissions(ACL_READ_EXTATTRIBUTES)
            public static let writeExtendedAttributes = Permissions(ACL_WRITE_EXTATTRIBUTES)
            public static let readSecurity = Permissions(ACL_READ_SECURITY)
            public static let writeSecurity = Permissions(ACL_WRITE_SECURITY)
            public static let changeOwner = Permissions(ACL_CHANGE_OWNER)

            public let rawValue: acl_permset_mask_t
            public init(rawValue: acl_permset_mask_t) { self.rawValue = rawValue }
            private init(_ perm: acl_perm_t) { self.rawValue = acl_permset_mask_t(perm.rawValue) }

            public var description: String {
                var perms: [String] = []

                if self.contains(.readData) {
                    perms.append("read")
                }

                if self.contains(.writeData) {
                    perms.append("write")
                }

                if self.contains(.listDirectory) {
                    perms.append("list")
                }

                if self.contains(.addFile) {
                    perms.append("add_file")
                }

                if self.contains(.execute) {
                    perms.append("execute")
                }

                if self.contains(.search) {
                    perms.append("search")
                }

                if self.contains(.delete) {
                    perms.append("delete")
                }

                if self.contains(.appendData) {
                    perms.append("append")
                }

                if self.contains(.addSubdirectory) {
                    perms.append("add_subdirectory")
                }

                if self.contains(.deleteChild) {
                    perms.append("delete_child")
                }

                if self.contains(.readAttributes) {
                    perms.append("readattr")
                }

                if self.contains(.writeAttributes) {
                    perms.append("writeattr")
                }

                if self.contains(.readExtendedAttributes) {
                    perms.append("readextattr")
                }

                if self.contains(.writeExtendedAttributes) {
                    perms.append("writeextattr")
                }

                if self.contains(.readSecurity) {
                    perms.append("readsecurity")
                }

                if self.contains(.writeSecurity) {
                    perms.append("writesecurity")
                }

                if self.contains(.changeOwner) {
                    perms.append("chown")
                }

                return perms.joined(separator: ", ")
            }
        }

        public struct Flags: OptionSet, Hashable, CustomStringConvertible {
            public static let inheritToFiles = Flags(rawValue: ACL_ENTRY_FILE_INHERIT.rawValue)
            public static let inheritToDirectories = Flags(rawValue: ACL_ENTRY_DIRECTORY_INHERIT.rawValue)
            public static let limitInheritance = Flags(rawValue: ACL_ENTRY_LIMIT_INHERIT.rawValue)
            public static let onlyInherit = Flags(rawValue: ACL_ENTRY_ONLY_INHERIT.rawValue)
            public static let isInherited = Flags(rawValue: ACL_ENTRY_INHERITED.rawValue)

            private static let allFlags: [Flags] = [
                .inheritToFiles, .inheritToDirectories, .limitInheritance, .onlyInherit, .isInherited
            ]

            public let rawValue: UInt32
            public init(rawValue: UInt32) { self.rawValue = rawValue }

            fileprivate init(flagset: acl_flagset_t?) throws {
                self = try Self.allFlags.reduce(into: []) { flags, flag in
                    let rawFlag = acl_flag_t(rawValue: flag.rawValue)
                    if try callPOSIXFunction(expect: .nonNegative, closure: { acl_get_flag_np(flagset, rawFlag) }) != 0 {
                        flags.insert(flag)
                    }
                }
            }

            fileprivate func apply(to flagset: acl_flagset_t?) throws {
                for eachFlag in Self.allFlags {
                    let rawFlag = acl_flag_t(rawValue: eachFlag.rawValue)

                    if self.contains(eachFlag) {
                        try callPOSIXFunction(expect: .zero) { acl_add_flag_np(flagset, rawFlag) }
                    } else {
                        try callPOSIXFunction(expect: .zero) { acl_delete_flag_np(flagset, rawFlag) }
                    }
                }
            }

            public var description: String {
                var flags: [String] = []

                if self.contains(.inheritToFiles) {
                    flags.append("file_inherit")
                }

                if self.contains(.inheritToDirectories) {
                    flags.append("directory_inherit")
                }

                if self.contains(.limitInheritance) {
                    flags.append("limit_inherit")
                }

                if self.contains(.onlyInherit) {
                    flags.append("only_inherit")
                }

                return flags.joined(separator: ", ")
            }
        }

        public var rule: Rule
        public var owner: UserOrGroup?
        public var permissions: Permissions
        public var flags: Flags

        public var description: String {
            let ownerType: String

            switch self.owner {
            case .none:
                ownerType = "(nil)"
            case .user:
                ownerType = "user"
            case .group:
                ownerType = "group"
            }

            let ownerName = (try? self.owner?.name) ?? "(nil)"
            let ownerString = "\(ownerType):\(ownerName)"

            let ruleString: String

            switch self.rule {
            case .allow:
                ruleString = "allow"
            case .deny:
                ruleString = "deny"
            }

            return [
                ownerString,
                ruleString,
                self.permissions.description,
                self.flags.description
            ].filter { !$0.isEmpty }.joined(separator: " ")
        }

        public init() {
            self.rule = .allow
            self.owner = .user(.current)
            self.permissions = []
            self.flags = []
        }

        internal init(aclEntry entry: acl_entry_t, isDirectory: Bool) throws {
            switch try callPOSIXFunction(expect: .zero, closure: { acl_get_tag_type(entry, $0) }) {
            case ACL_EXTENDED_ALLOW:
                self.rule = .allow
            case ACL_EXTENDED_DENY:
                self.rule = .deny
            default:
                throw errno(EINVAL)
            }

            let guid = try callPOSIXFunction { acl_get_qualifier(entry) }
            defer { acl_free(guid) }

            self.owner = try guid.withMemoryRebound(to: uuid_t.self, capacity: 1) {
                try UserOrGroup(uuid: $0.pointee)
            }

            self.permissions = try Permissions(rawValue: callPOSIXFunction(expect: .zero) {
                acl_get_permset_mask_np(entry, $0)
            })

            self.flags = try Flags(flagset: callPOSIXFunction(expect: .zero) {
                acl_get_flagset_np(UnsafeMutableRawPointer(entry), $0)
            })
        }

        fileprivate func apply(to entry: acl_entry_t, isDirectory: Bool) throws {
            switch self.rule {
            case .allow:
                try callPOSIXFunction(expect: .zero) { acl_set_tag_type(entry, ACL_EXTENDED_ALLOW) }
            case .deny:
                try callPOSIXFunction(expect: .zero) { acl_set_tag_type(entry, ACL_EXTENDED_DENY) }
            }

            if let owner = self.owner, [.allow, .deny].contains(rule) {
                var guid = try owner.uuid

                _ = try withUnsafeBytes(of: &guid) { bytes in
                    try callPOSIXFunction(expect: .zero) { acl_set_qualifier(entry, bytes.baseAddress) }
                }
            }

            try callPOSIXFunction(expect: .zero) { acl_set_permset_mask_np(entry, self.permissions.rawValue) }

            try self.flags.apply(to: try callPOSIXFunction(expect: .zero) {
                acl_get_flagset_np(UnsafeMutableRawPointer(entry), $0)
            })
        }
    }

    private final class ACLWrapper {
        var acl: acl_t
        init(acl: acl_t) { self.acl = acl }
        deinit { acl_free(UnsafeMutableRawPointer(acl)) }
    }

    private var aclWrapper: ACLWrapper
    internal var aclForReading: acl_t { self.aclWrapper.acl }
    private var aclForWriting: acl_t {
        mutating get throws {
            if !isKnownUniquelyReferenced(&self.aclWrapper) {
                let newACL = try callPOSIXFunction(isWrite: true) { acl_dup(self.aclWrapper.acl) }
                self.aclWrapper = ACLWrapper(acl: newACL)
            }

            return self.aclWrapper.acl
        }
    }

    internal let isDirectory: Bool

    public init() { try! self.init(isDirectory: false) }
    public init(isDirectory: Bool) throws {
        try self.init(acl: callPOSIXFunction { acl_init(0) }, isDirectory: isDirectory)
    }

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public init(path: FilePath) throws {
        let isDirectory = try FileInfo(path: path, keys: .objectType).objectType == .directory
        let acl = try callPOSIXFunction(path: path) {
            guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12) else {
                return path.withCString { acl_get_file($0, ACL_TYPE_EXTENDED) }
            }

            return path.withPlatformString { acl_get_file($0, ACL_TYPE_EXTENDED) }
        }

        try self.init(acl: acl, isDirectory: isDirectory)
    }

    public init(path: String) throws {
        let isDirectory = try FileInfo(path: path, keys: .objectType).objectType == .directory
        let acl = try callPOSIXFunction(path: path) {
            guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12) else {
                return path.withCString { acl_get_file($0, ACL_TYPE_EXTENDED) }
            }

            return path.withPlatformString { acl_get_file($0, ACL_TYPE_EXTENDED) }
        }

        try self.init(acl: acl, isDirectory: isDirectory)
    }

    public init(data: some DataProtocol, nativeRepresentation: Bool = false, isDirectory: Bool) throws {
        if data.regions.count == 1, let region = data.regions.first {
            try self.init(region: region, nativeRepresentation: nativeRepresentation, isDirectory: isDirectory)
        } else {
            try self.init(
                region: ContiguousArray(data),
                nativeRepresentation: nativeRepresentation,
                isDirectory: isDirectory
            )
        }
    }

    private init(region: some ContiguousBytes, nativeRepresentation: Bool, isDirectory: Bool) throws {
        let acl = try region.withUnsafeBytes {
            guard let acl = nativeRepresentation ? acl_copy_int_native($0.baseAddress) : acl_copy_int($0.baseAddress) else {
                throw errno()
            }

            return acl
        }

        try self.init(acl: acl, isDirectory: isDirectory)
    }

    private init(acl: acl_t, isDirectory: Bool) throws {
        self.aclWrapper = ACLWrapper(acl: acl)
        self.isDirectory = isDirectory
    }

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public func apply(to path: FilePath) throws {
        try callPOSIXFunction(expect: .zero, path: path, isWrite: true) {
            guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12) else {
                return path.withCString { acl_set_file($0, ACL_TYPE_EXTENDED, self.aclForReading) }
            }

            return path.withPlatformString { acl_set_file($0, ACL_TYPE_EXTENDED, self.aclForReading) }
        }
    }

    public func apply(toPath path: String) throws {
        try callPOSIXFunction(expect: .zero, path: path, isWrite: true) {
            guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12) else {
                return path.withCString { acl_set_file($0, ACL_TYPE_EXTENDED, self.aclForReading) }
            }

            return path.withPlatformString { acl_set_file($0, ACL_TYPE_EXTENDED, self.aclForReading) }
        }
    }

    public func dataRepresentation(native: Bool = false) throws -> some DataProtocol {
        let acl = self.aclForReading
        let size = acl_size(acl)

        return try ContiguousArray<UInt8>(unsafeUninitializedCapacity: size) { buffer, bytesWritten in
            let bytes = buffer.baseAddress

            bytesWritten = 0
            bytesWritten = try callPOSIXFunction(expect: .nonNegative, isWrite: true) {
                native ? acl_copy_ext_native(bytes, acl, size) : acl_copy_ext(bytes, acl, size)
            }
        }
    }

    public var deferInheritance: Bool {
        get { (try? self.value(for: ACL_FLAG_DEFER_INHERIT)) ?? false }
        set { _ = try? self.setValue(newValue, for: ACL_FLAG_DEFER_INHERIT) }
    }

    public var noInheritance: Bool {
        get { (try? self.value(for: ACL_FLAG_NO_INHERIT)) ?? false }
        set { _ = try? self.setValue(newValue, for: ACL_FLAG_NO_INHERIT) }
    }

    public var startIndex: Int { 0 }
    public var endIndex: Int { self.count }
    public func index(after i: Int) -> Int { i + 1 }

    public var count: Int {
        let ptr = UnsafeMutablePointer<acl_entry_t?>.allocate(capacity: 1)
        defer { ptr.deallocate() }

        let acl = self.aclForReading
        var i = 0

        while acl_get_entry(acl, (i == 0 ? ACL_FIRST_ENTRY : ACL_NEXT_ENTRY).rawValue, ptr) == 0 {
            i += 1
        }

        return i
    }

    public var last: Entry? {
        do {
            let aclEntry = try callPOSIXFunction(expect: .zero) {
                acl_get_entry(self.aclForReading, ACL_LAST_ENTRY.rawValue, $0)
            }

            return try Entry(aclEntry: aclEntry!, isDirectory: self.isDirectory)
        } catch {
            return nil
        }
    }

    public func getEntry(at position: some BinaryInteger) throws -> Entry {
        let aclEntry = try self.getRawEntry(at: position, acl: self.aclForReading)

        return try Entry(aclEntry: aclEntry, isDirectory: self.isDirectory)
    }

    private func getRawEntry(at position: some BinaryInteger, acl: acl_t) throws -> acl_entry_t {
        var i = 0

        let ptr = UnsafeMutablePointer<acl_entry_t?>.allocate(capacity: 1)
        defer { ptr.deallocate() }

        while i < position {
            defer { i += 1 }

            try callPOSIXFunction(expect: .zero) {
                acl_get_entry(acl, (i == 0 ? ACL_FIRST_ENTRY : ACL_NEXT_ENTRY).rawValue, ptr)
            }
        }

        return try callPOSIXFunction(expect: .zero) {
            acl_get_entry(acl, (position == 0 ? ACL_FIRST_ENTRY : ACL_NEXT_ENTRY).rawValue, $0)
        }!
    }

    public mutating func insertEntry(_ entry: Entry, at position: some BinaryInteger) throws {
        var acl: acl_t? = try self.aclForWriting

        let aclEntry = try callPOSIXFunction(expect: .zero) {
            acl_create_entry_np(&acl, $0, ACL_FIRST_ENTRY.rawValue + Int32(position))
        }!

        try entry.apply(to: aclEntry, isDirectory: self.isDirectory)
    }

    public mutating func removeEntry(at position: some BinaryInteger) throws {
        let acl = try self.aclForWriting
        let aclEntry = try self.getRawEntry(at: position, acl: acl)

        try callPOSIXFunction(expect: .zero) { acl_delete_entry(acl, aclEntry) }
    }

    private mutating func setEntry(_ entry: Entry, at position: some BinaryInteger) throws {
        let acl = try self.aclForWriting
        let aclEntry = try self.getRawEntry(at: position, acl: acl)

        try entry.apply(to: aclEntry, isDirectory: self.isDirectory)
    }

    public subscript(position: Int) -> Entry {
        get { try! self.getEntry(at: position) }
        set { try! self.setEntry(newValue, at: position) }
    }

    public mutating func replaceSubrange(_ range: Range<Int>, with entries: some Collection<Entry>) {
        for _ in 0..<range.count {
            try! self.removeEntry(at: range.lowerBound)
        }

        for (index, eachEntry) in entries.enumerated() {
            try! self.insertEntry(eachEntry, at: range.lowerBound + index)
        }
    }

    public func validate() throws {
        try callPOSIXFunction(expect: .zero) { acl_valid(self.aclForReading) }
    }

    public var description: String {
        do {
            var len = 0
            let desc = try callPOSIXFunction { acl_to_text(self.aclForReading, &len) }
            defer { acl_free(desc) }

            return String(cString: desc)
        } catch {
            return String(describing: error)
        }
    }

    private func value(for flag: acl_flag_t) throws -> Bool {
        let flagset = try callPOSIXFunction(expect: .zero) {
            acl_get_flagset_np(UnsafeMutableRawPointer(self.aclForReading), $0)
        }

        let flag = try callPOSIXFunction(expect: .nonNegative) { acl_get_flag_np(flagset, flag) }

        return flag != 0
    }

    private mutating func setValue(_ value: Bool, for flag: acl_flag_t) throws {
        let acl = try self.aclForWriting
        let flagset = try callPOSIXFunction(expect: .zero, isWrite: true) {
            acl_get_flagset_np(UnsafeMutableRawPointer(acl), $0)
        }

        if value {
            try callPOSIXFunction(expect: .zero, isWrite: true) { acl_add_flag_np(flagset, flag) }
        } else {
            try callPOSIXFunction(expect: .zero, isWrite: true) { acl_delete_flag_np(flagset, flag) }
        }

        try callPOSIXFunction(expect: .zero, isWrite: true) {
            acl_set_flagset_np(UnsafeMutableRawPointer(acl), flagset)
        }
    }
}

extension AccessControlList: Codable {
    private enum CodingKeys: CodingKey {
        case aclData
        case isDirectory
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let base64 = try container.decode(String.self, forKey: .aclData)
        let isDir = try container.decode(Bool.self, forKey: .isDirectory)

        let data = try Base64.decode(string: base64)

        try self.init(data: data, nativeRepresentation: false, isDirectory: isDir)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(Base64.encodeString(bytes: self.dataRepresentation(native: false)), forKey: .aclData)
        try container.encode(self.isDirectory, forKey: .isDirectory)
    }
}

extension AccessControlList: Hashable {
    public static func ==(lhs: AccessControlList, rhs: AccessControlList) -> Bool {
        lhs.description == rhs.description
    }

    public func hash(into hasher: inout Hasher) {
        self.description.hash(into: &hasher)
    }
}
