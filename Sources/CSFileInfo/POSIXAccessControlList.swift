//
//  POSIXAccessControlList.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 6/26/26.
//
//  Currently, this file is only available on Linux.

#if canImport(Glibc)
import CSErrors
import CShims
import ExtrasBase64
import Glibc
import SystemPackage

public struct POSIXAccessControlList: CustomStringConvertible, @unchecked Sendable {
    public enum ValidationError: Error, Hashable, Sendable {
        case duplicateID(position: Int32)
        case duplicateTagType(position: Int32)
        case invalidTagType(position: Int32)
        case missingEntry
        case unknown(code: Int32)

        fileprivate init(rawValue: Int32, last: Int32) {
            self = switch rawValue {
            case ACL_MULTI_ERROR: .duplicateTagType(position: last)
            case ACL_DUPLICATE_ERROR: .duplicateID(position: last)
            case ACL_MISS_ERROR: .missingEntry
            case ACL_ENTRY_ERROR: .invalidTagType(position: last)
            default: .unknown(code: rawValue)
            }
        }
    }

    public struct Entry: Hashable, CustomStringConvertible {
        public enum Scope: Hashable, CustomStringConvertible, Sendable {
            case owner
            case groupOwner
            case user(User)
            case group(Group)
            case mask
            case other

            public var description: String {
                switch self {
                case .owner: "owner"
                case .groupOwner: "group owner"
                case .user(let user): "user:\(user.id)"
                case .group(let group): "group:\(group.id)"
                case .mask: "mask"
                case .other: "other"
                }
            }

            fileprivate init(tagType: acl_tag_t, entry: acl_entry_t) throws {
                switch tagType {
                case ACL_USER_OBJ:
                    self = .owner
                case ACL_GROUP_OBJ:
                    self = .groupOwner
                case ACL_USER:
                    let qualifier = try callPOSIXFunction { acl_get_qualifier(entry) }
                    defer { acl_free(qualifier) }

                    self = qualifier.withMemoryRebound(to: uid_t.self, capacity: 1) { .user(User(id: $0.pointee)) }
                case ACL_GROUP:
                    let qualifier = try callPOSIXFunction { acl_get_qualifier(entry) }
                    defer { acl_free(qualifier) }

                    self = qualifier.withMemoryRebound(to: gid_t.self, capacity: 1) { .group(Group(id: $0.pointee)) }
                case ACL_MASK:
                    self = .mask
                case ACL_OTHER:
                    self = .other
                default:
                    throw errno(EINVAL)
                }
            }

            fileprivate func apply(to entry: acl_entry_t) throws {
                switch self {
                case .owner:
                    try callPOSIXFunction(expect: .zero) { acl_set_tag_type(entry, ACL_USER_OBJ) }
                case .groupOwner:
                    try callPOSIXFunction(expect: .zero) { acl_set_tag_type(entry, ACL_GROUP_OBJ) }
                case .user(var uid):
                    try callPOSIXFunction(expect: .zero) { acl_set_tag_type(entry, ACL_USER) }
                    try callPOSIXFunction(expect: .zero) { acl_set_qualifier(entry, &uid) }
                case .group(var gid):
                    try callPOSIXFunction(expect: .zero) { acl_set_tag_type(entry, ACL_GROUP) }
                    try callPOSIXFunction(expect: .zero) { acl_set_qualifier(entry, &gid) }
                case .mask:
                    try callPOSIXFunction(expect: .zero) { acl_set_tag_type(entry, ACL_MASK) }
                case .other:
                    try callPOSIXFunction(expect: .zero) { acl_set_tag_type(entry, ACL_OTHER) }
                }
            }
        }

        public struct Permissions: OptionSet, Hashable, CustomStringConvertible, Sendable {
            public static let read = Permissions(rawValue: acl_perm_t(ACL_READ))
            public static let write = Permissions(rawValue: acl_perm_t(ACL_WRITE))
            public static let execute = Permissions(rawValue: acl_perm_t(ACL_EXECUTE))
            private static let all = [Self.read, Self.write, Self.execute]

            private static func get(permset: acl_permset_t, perm: acl_perm_t) throws -> Bool {
                try callPOSIXFunction(expect: .nonNegative) { acl_get_perm(permset, perm) } != 0
            }

            private static func set(permset: acl_permset_t, perm: acl_perm_t, value: Bool) throws {
                try callPOSIXFunction(expect: .zero) {
                    if value {
                        acl_add_perm(permset, perm)
                    } else {
                        acl_delete_perm(permset, perm)
                    }
                }
            }

            public let rawValue: acl_perm_t
            public init(rawValue: acl_perm_t) { self.rawValue = rawValue }
            fileprivate init(rawValue: acl_permset_t?) throws {
                self = []

                if let permset = rawValue {
                    for eachPerm in Self.all {
                        if try Self.get(permset: permset, perm: eachPerm.rawValue) {
                            self.insert(eachPerm)
                        }
                    }
                }
            }

            fileprivate init(mode: mode_t, readMask: mode_t, writeMask: mode_t, execMask: mode_t) {
                self = []

                if mode & readMask != 0 {
                    self.insert(.read)
                }

                if mode & writeMask != 0 {
                    self.insert(.write)
                }

                if mode & execMask != 0 {
                    self.insert(.execute)
                }
            }

            fileprivate func apply(to entry: acl_entry_t) throws {
                guard let permset = try callPOSIXFunction(expect: .zero, closure: { acl_get_permset(entry, $0) }) else {
                    return
                }

                for eachPerm in Self.all {
                    try Self.set(permset: permset, perm: eachPerm.rawValue, value: self.contains(eachPerm))
                }
            }

            public var description: String {
                var perms: [String] = []

                if self.contains(.read) {
                    perms.append("read")
                }

                if self.contains(.write) {
                    perms.append("write")
                }

                if self.contains(.execute) {
                    perms.append("execute")
                }

                return perms.joined(separator: ", ")
            }
        }

        public var scope: Scope
        public var permissions: Permissions

        public var description: String {
            "\(self.scope.description) \(self.permissions.description)"
        }

        public init() {
            self.init(scope: .user(.current), permissions: [])
        }

        public init(scope: Scope, permissions: Permissions) {
            self.scope = scope
            self.permissions = permissions
        }

        internal init(aclEntry entry: acl_entry_t) throws {
            let tagType = try callPOSIXFunction(expect: .zero) { acl_get_tag_type(entry, $0) }
            let permset = try callPOSIXFunction(expect: .zero) { acl_get_permset(entry, $0) }

            self.scope = try Scope(tagType: tagType, entry: entry)
            self.permissions = try Permissions(rawValue: permset)
        }

        fileprivate func apply(to entry: acl_entry_t) throws {
            try self.scope.apply(to: entry)
            try self.permissions.apply(to: entry)
        }
    }

    private var entries: [Entry]

    public init() {
        let mask = umask(0)
        umask(mask)

        try! self.init(mode: 0o666 & ~mask)
    }

    public init(mode: mode_t) throws {
        let ownerPerms = Entry.Permissions(mode: mode, readMask: S_IRUSR, writeMask: S_IWUSR, execMask: S_IXUSR)
        let groupPerms = Entry.Permissions(mode: mode, readMask: S_IRGRP, writeMask: S_IWGRP, execMask: S_IXGRP)
        let otherPerms = Entry.Permissions(mode: mode, readMask: S_IROTH, writeMask: S_IWOTH, execMask: S_IXOTH)

        try self.init(entries: [
            Entry(scope: .owner, permissions: ownerPerms),
            Entry(scope: .groupOwner, permissions: groupPerms),
            Entry(scope: .other, permissions: otherPerms)
        ])
    }

    public init(entries: some Collection<Entry>) throws {
        self.entries = Array(entries)
    }

    public init(at path: FilePath) throws {
        let acl = try callPOSIXFunction(path: path) {
            path.withPlatformString { acl_get_file($0, acl_type_t(bitPattern: ACL_TYPE_ACCESS)) }
        }

        try self.init(acl: acl)
    }

    public init(at fd: FileDescriptor) throws {
        let acl = try callPOSIXFunction {
            acl_get_fd(fd.rawValue)
        }

        try self.init(acl: acl)
    }

    public init(textRepresentation: some StringProtocol) throws {
        let acl = try textRepresentation.withCString(encodedAs: UTF8.self) { cString in
            try callPOSIXFunction { acl_from_text(cString) }
        }

        try self.init(acl: acl)
    }

    private init(acl: acl_t) throws {
        var entries: [Entry] = []
        var next = try callPOSIXFunction(expect: .nonNegative) { acl_get_entry(acl, ACL_FIRST_ENTRY, $0) }

        while let entry = next {
            entries.append(try Entry(aclEntry: entry))

            if try callPOSIXFunction(expect: .nonNegative, closure: { acl_get_entry(acl, ACL_NEXT_ENTRY, &next) }) != 1 {
                break
            }
        }

        self.entries = entries
    }

    @discardableResult
    private func withACL<T>(closure: (acl_t) throws -> T) throws -> T {
        guard let entryCount = Int32(exactly: self.entries.count) else { throw Errno.invalidArgument }
        var acl = try callPOSIXFunction { acl_init(entryCount) }
        defer { acl_free(UnsafeMutableRawPointer(acl)) }

        try withUnsafeMutablePointer(to: &acl) {
            try $0.withMemoryRebound(to: acl_t?.self, capacity: 1) { aclPtr in
                for eachEntry in self.entries {
                    let rawEntry = try callPOSIXFunction(expect: .zero) { acl_create_entry(aclPtr, $0) }!
                    try eachEntry.apply(to: rawEntry)
                }
            }
        }

        return try closure(acl)
    }

    public func apply(to path: FilePath) throws {
        try self.withACL { acl in
            try callPOSIXFunction(expect: .zero, path: path, isWrite: true) {
                path.withPlatformString { acl_set_file($0, UInt32(bitPattern: ACL_TYPE_ACCESS), acl) }
            }
        }
    }

    public func validate() throws {
        try self.withACL { acl in
            var last: Int32 = 0
            let err = try callPOSIXFunction(expect: .nonNegative) { acl_check(acl, &last) }
            if err != 0 {
                throw ValidationError(rawValue: err, last: last)
            }
        }
    }

    public var textRepresentation: String {
        get throws {
            try self.withACL { acl in
                var len = 0
                let desc = try callPOSIXFunction { acl_to_text(acl, &len) }
                defer { acl_free(desc) }

                return String(cString: desc)
            }
        }
    }

    public var description: String {
        do {
            return try self.textRepresentation
        } catch {
            return String(describing: error)
        }
    }
}

extension POSIXAccessControlList: Codable {
    private enum CodingKeys: CodingKey {
        case textRepresentation
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let text = try container.decode(String.self, forKey: .textRepresentation)

        try self.init(textRepresentation: text)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.textRepresentation, forKey: .textRepresentation)
    }
}

extension POSIXAccessControlList: RangeReplaceableCollection {
    public typealias Index = Int
    public typealias Element = Entry

    public var startIndex: Int { 0 }
    public var endIndex: Int { self.entries.count }
    public func index(after i: Int) -> Int { i + 1 }

    public var count: Int { self.entries.count }
    public var last: Entry? { self.entries.last }

    public subscript(position: Int) -> Entry {
        get { self.entries[position] }
        set { self.entries[position] = newValue }
    }

    public mutating func replaceSubrange(_ range: Range<Int>, with entries: some Collection<Entry>) {
        self.entries.replaceSubrange(range, with: entries)
    }
}

extension POSIXAccessControlList: Hashable {
    public static func ==(lhs: POSIXAccessControlList, rhs: POSIXAccessControlList) -> Bool {
        lhs.description == rhs.description
    }

    public func hash(into hasher: inout Hasher) {
        self.description.hash(into: &hasher)
    }
}

#endif
