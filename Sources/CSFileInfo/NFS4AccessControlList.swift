//
//  NFS4AccessControlList.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 5/28/12.
//
//  Currently, this file is only available on BSD platforms (such as Darwin).

#if canImport(Darwin) || os(FreeBSD)

import CSErrors
import ExtrasBase64
import System

#if canImport(Darwin)
import Darwin
#endif

#if Foundation
import Foundation
#endif

public struct NFS4AccessControlList: RangeReplaceableCollection, CustomStringConvertible, @unchecked Sendable {
    public typealias Element = Entry
    public typealias Index = Int

    public struct Entry: Hashable, CustomStringConvertible {
        public enum Rule: UInt8, CustomStringConvertible, Sendable {
            case allow = 1
            case deny = 2

            public var description: String {
                switch self {
                case .allow: "allow"
                case .deny: "deny"
                }
            }
        }

        public struct Permissions: OptionSet, Hashable, CustomStringConvertible, Sendable {
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

            fileprivate func apply(to entry: acl_entry_t) throws {
                try callPOSIXFunction(expect: .zero) { acl_set_permset_mask_np(entry, self.rawValue) }
            }

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

        public struct Flags: OptionSet, Hashable, CustomStringConvertible, Sendable {
            public let rawValue: UInt32
            public init(rawValue: UInt32) { self.rawValue = rawValue }

            public static let inheritToFiles = Flags(rawValue: ACL_ENTRY_FILE_INHERIT.rawValue)
            public static let inheritToDirectories = Flags(rawValue: ACL_ENTRY_DIRECTORY_INHERIT.rawValue)
            public static let limitInheritance = Flags(rawValue: ACL_ENTRY_LIMIT_INHERIT.rawValue)
            public static let onlyInherit = Flags(rawValue: ACL_ENTRY_ONLY_INHERIT.rawValue)
            public static let isInherited = Flags(rawValue: ACL_ENTRY_INHERITED.rawValue)

            private static let allFlags: [Flags] = [
                .inheritToFiles, .inheritToDirectories, .limitInheritance, .onlyInherit, .isInherited
            ]

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
            case .unknown:
                ownerType = "unknown"
            }

            let ownerName = (try? self.owner?.name) ?? "(nil)"
            let ownerString = "\(ownerType):\(ownerName)"

            return [
                ownerString,
                self.rule.description,
                self.permissions.description,
                self.flags.description
            ].filter { !$0.isEmpty }.joined(separator: " ")
        }

        public init() {
            self.init(rule: .allow, owner: .user(.current), permissions: [], flags: [])
        }

        public init(rule: Rule, owner: UserOrGroup, permissions: Permissions, flags: Flags = []) {
            self.rule = rule
            self.owner = owner
            self.permissions = permissions
            self.flags = flags
        }

        internal init(aclEntry entry: acl_entry_t) throws {
            let tagType = try callPOSIXFunction(expect: .zero) { acl_get_tag_type(entry, $0) }
            switch tagType {
            case ACL_EXTENDED_ALLOW:
                self.rule = .allow
            case ACL_EXTENDED_DENY:
                self.rule = .deny
            default:
                throw errno(EINVAL)
            }

            let qualifier = try callPOSIXFunction { acl_get_qualifier(entry) }
            defer { acl_free(qualifier) }

            self.owner = try qualifier.withMemoryRebound(to: uuid_t.self, capacity: 1) {
                try UserOrGroup(uuid: $0.pointee, allowUnknown: true)
            }

            self.permissions = try Permissions(rawValue: callPOSIXFunction(expect: .zero) {
                acl_get_permset_mask_np(entry, $0)
            })

            self.flags = try Flags(flagset: callPOSIXFunction(expect: .zero) {
                acl_get_flagset_np(UnsafeMutableRawPointer(entry), $0)
            })
        }

        fileprivate func apply(to entry: acl_entry_t) throws {
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

            try self.permissions.apply(to: entry)

            try self.flags.apply(to: try callPOSIXFunction(expect: .zero) {
                acl_get_flagset_np(UnsafeMutableRawPointer(entry), $0)
            })
        }
    }

    private final class ACLWrapper {
        var acl: acl_t?
        init(acl: acl_t?) { self.acl = acl }
        deinit {
            if let acl = self.acl {
                acl_free(UnsafeMutableRawPointer(acl))
            }
        }
    }

    private var aclWrapper: ACLWrapper

    @discardableResult
    private func withACLForReading<T>(_ body: (acl_t) throws -> T) throws -> T {
        guard let acl = self.aclWrapper.acl else {
            let acl = try callPOSIXFunction { acl_init(0) }
            defer { acl_free(UnsafeMutableRawPointer(acl)) }

            return try body(acl)
        }

        return try body(acl)
    }

    internal var aclForWriting: acl_t {
        mutating get throws {
            guard let acl = self.aclWrapper.acl else {
                let acl = try callPOSIXFunction { acl_init(0) }
                self.aclWrapper = ACLWrapper(acl: acl)
                return acl
            }

            if !isKnownUniquelyReferenced(&self.aclWrapper) {
                let newACL = try callPOSIXFunction(isWrite: true) { acl_dup(acl) }
                self.aclWrapper = ACLWrapper(acl: newACL)
                return newACL
            }

            return acl
        }
    }

    public init() {
        self.aclWrapper = ACLWrapper(acl: nil)
    }

    public init(entries: some Collection<Entry>) throws {
        try self.init(acl: callPOSIXFunction { acl_init(0) })

        for eachEntry in entries {
            self.append(eachEntry)
        }
    }

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public init(at path: FilePath) throws {
        let acl = try callPOSIXFunction(path: path) {
            guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12) else {
                return path.withCString { acl_get_file($0, ACL_TYPE_EXTENDED) }
            }

            return path.withPlatformString { acl_get_file($0, ACL_TYPE_EXTENDED) }
        }

        try self.init(acl: acl)
    }

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public init(at fd: FileDescriptor) throws {
        let acl = try callPOSIXFunction {
            acl_get_fd_np(fd.rawValue, ACL_TYPE_EXTENDED)
        }

        try self.init(acl: acl)
    }

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public init(atPath path: String) throws {
        let acl = try callPOSIXFunction(path: path) {
            guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12) else {
                return path.withCString { acl_get_file($0, ACL_TYPE_EXTENDED) }
            }

            return path.withPlatformString { acl_get_file($0, ACL_TYPE_EXTENDED) }
        }

        try self.init(acl: acl)
    }

    public init(data: some Collection<UInt8>, nativeRepresentation: Bool = false) throws {
        let acl = try data.withContiguousStorageIfAvailable {
            try Self.makeACL(bytes: UnsafeRawBufferPointer($0), nativeRepresentation: nativeRepresentation)
        } ?? ContiguousArray(data).withUnsafeBytes {
            try Self.makeACL(bytes: $0, nativeRepresentation: nativeRepresentation)
        }

        try self.init(acl: acl)
    }

    public init(textRepresentation: some StringProtocol) throws {
        let acl = try textRepresentation.withCString(encodedAs: UTF8.self) { string in
            try callPOSIXFunction { acl_from_text(string) }
        }

        try self.init(acl: acl)
    }

    private static func makeACL(bytes: UnsafeRawBufferPointer, nativeRepresentation isNative: Bool) throws -> acl_t {
        guard let acl = isNative ? acl_copy_int_native(bytes.baseAddress) : acl_copy_int(bytes.baseAddress) else {
            throw errno()
        }

        return acl
    }

    private init(acl: acl_t) throws {
        self.aclWrapper = ACLWrapper(acl: acl)
    }

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public func apply(to path: FilePath) throws {
        try self.withACLForReading { acl in
            try callPOSIXFunction(expect: .zero, path: path, isWrite: true) {
                guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12) else {
                    return path.withCString { acl_set_file($0, ACL_TYPE_EXTENDED, acl) }
                }

                return path.withPlatformString { acl_set_file($0, ACL_TYPE_EXTENDED, acl) }
            }
        }
    }

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public func apply(toPath path: String) throws {
        try self.withACLForReading { acl in
            try callPOSIXFunction(expect: .zero, path: path, isWrite: true) {
                guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12) else {
                    return path.withCString { acl_set_file($0, ACL_TYPE_EXTENDED, acl) }
                }

                return path.withPlatformString { acl_set_file($0, ACL_TYPE_EXTENDED, acl) }
            }
        }
    }

    public func dataRepresentation(native: Bool = false) throws -> some Collection<UInt8> {
        try self.withACLForReading { acl in
            let size = acl_size(acl)

            return try ContiguousArray<UInt8>(unsafeUninitializedCapacity: size) { buffer, bytesWritten in
                let bytes = buffer.baseAddress

                bytesWritten = 0
                bytesWritten = try callPOSIXFunction(expect: .nonNegative, isWrite: true) {
                    native ? acl_copy_ext_native(bytes, acl, size) : acl_copy_ext(bytes, acl, size)
                }
            }
        }
    }

    public var textRepresentation: String {
        get throws {
            try self.withACLForReading { acl in
                var len = 0
                let desc = try callPOSIXFunction { acl_to_text(acl, &len) }
                defer { acl_free(desc) }

                return String(cString: desc)
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
        do {
            return try self.withACLForReading { acl in
                let ptr = UnsafeMutablePointer<acl_entry_t?>.allocate(capacity: 1)
                defer { ptr.deallocate() }

                var i = 0

                while acl_get_entry(acl, (i == 0 ? ACL_FIRST_ENTRY : ACL_NEXT_ENTRY).rawValue, ptr) == 0 {
                    i += 1
                }

                return i
            }
        } catch {
            return 0
        }
    }

    public var last: Entry? {
        do {
            return try self.withACLForReading { acl in
                let aclEntry = try callPOSIXFunction(expect: .zero) {
                    acl_get_entry(acl, ACL_LAST_ENTRY.rawValue, $0)
                }

                return try aclEntry.map { try Entry(aclEntry: $0) }
            }
        } catch {
            return nil
        }
    }

    public func getEntry(at position: some BinaryInteger) throws -> Entry {
        try self.withACLForReading { acl in
            let aclEntry = try self.getRawEntry(at: position, acl: acl)

            return try Entry(aclEntry: aclEntry)
        }
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

        try entry.apply(to: aclEntry)
    }

    public mutating func removeEntry(at position: some BinaryInteger) throws {
        let acl = try self.aclForWriting
        let aclEntry = try self.getRawEntry(at: position, acl: acl)

        try callPOSIXFunction(expect: .zero) { acl_delete_entry(acl, aclEntry) }
    }

    private mutating func setEntry(_ entry: Entry, at position: some BinaryInteger) throws {
        let acl = try self.aclForWriting
        let aclEntry = try self.getRawEntry(at: position, acl: acl)

        try entry.apply(to: aclEntry)
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
        try self.withACLForReading { acl in
            try callPOSIXFunction(expect: .zero) { acl_valid(acl) }
        }
    }

    public var description: String {
        do {
            return try self.textRepresentation
        } catch {
            return String(describing: error)
        }
    }

    private func value(for flag: acl_flag_t) throws -> Bool {
        try self.withACLForReading { acl in
            let flagset = try callPOSIXFunction(expect: .zero) {
                acl_get_flagset_np(UnsafeMutableRawPointer(acl), $0)
            }

            let flag = try callPOSIXFunction(expect: .nonNegative) { acl_get_flag_np(flagset, flag) }

            return flag != 0
        }
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

extension NFS4AccessControlList: Codable {
    private enum CodingKeys: CodingKey {
        case aclData
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let base64 = try container.decode(String.self, forKey: .aclData)

        let data = try Base64.decode(string: base64)

        try self.init(data: data, nativeRepresentation: false)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(Base64.encodeString(bytes: self.dataRepresentation(native: false)), forKey: .aclData)
    }
}

extension NFS4AccessControlList: Hashable {
    public static func ==(lhs: NFS4AccessControlList, rhs: NFS4AccessControlList) -> Bool {
        do {
            return try lhs.textRepresentation == rhs.textRepresentation
        } catch {
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        try? self.textRepresentation.hash(into: &hasher)
    }
}

#endif
