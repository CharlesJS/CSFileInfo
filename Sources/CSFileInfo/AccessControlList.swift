//
//  AccessControlList.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 5/28/12.
//
//

import CSDataProtocol
import CSErrors
import System

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

public struct AccessControlList: CustomDebugStringConvertible {
    public struct Entry: Hashable, CustomStringConvertible {
        public enum Rule: UInt8 {
            case unknown = 0
            case allow = 1
            case deny = 2
        }

        public var owner: UserOrGroup? {
            get {
                do {
                    let rule = self.rule

                    if rule != .allow && rule != .deny {
                        return nil
                    }

                    let guid = try callPOSIXFunction { acl_get_qualifier(self.entry) }
                    defer { acl_free(guid) }

                    return try guid.withMemoryRebound(to: uuid_t.self, capacity: 1) {
                        try UserOrGroup(uuid: $0.pointee)
                    }
                } catch {
                    printToStderr("Error getting owner: \(error)")
                    return nil
                }
            }
            set {
                let rule = self.rule

                if rule != .allow && rule != .deny {
                    return
                }

                guard var guid = try? newValue?.uuid else {
                    acl_set_qualifier(self.entry, nil)
                    return
                }

                _ = withUnsafeBytes(of: &guid) { acl_set_qualifier(self.entry, $0.baseAddress) }
            }
        }

        public var rule: Rule {
            get {
                let tag = try? callPOSIXFunction(expect: .zero) { acl_get_tag_type(self.entry, $0) }

                switch tag {
                case ACL_EXTENDED_ALLOW:
                    return .allow
                case ACL_EXTENDED_DENY:
                    return .deny
                default:
                    return .unknown
                }
            }
            set {
                switch newValue {
                case .allow:
                    acl_set_tag_type(self.entry, ACL_EXTENDED_ALLOW)
                case .deny:
                    acl_set_tag_type(self.entry, ACL_EXTENDED_DENY)
                default:
                    break
                }
            }
        }

        /// The following properties apply only to files
        public var readDataPermission: Bool {
            get { self.value(for: ACL_READ_DATA) }
            set { self.setValue(newValue, for: ACL_READ_DATA) }
        }

        public var writeDataPermission: Bool {
            get { self.value(for: ACL_WRITE_DATA) }
            set { self.setValue(newValue, for: ACL_WRITE_DATA) }
        }

        public var appendDataPermission: Bool {
            get { self.value(for: ACL_APPEND_DATA) }
            set { self.setValue(newValue, for: ACL_APPEND_DATA) }
        }

        public var executePermission: Bool {
            get { self.value(for: ACL_EXECUTE) }
            set { self.setValue(newValue, for: ACL_EXECUTE) }
        }

        /// The following properties apply only to directories
        public var listDirectoryPermission: Bool {
            get { self.value(for: ACL_LIST_DIRECTORY) }
            set { self.setValue(newValue, for: ACL_LIST_DIRECTORY) }
        }

        public var addFilePermission: Bool {
            get { self.value(for: ACL_ADD_FILE) }
            set { self.setValue(newValue, for: ACL_ADD_FILE) }
        }

        public var addSubdirectoryPermission: Bool {
            get { self.value(for: ACL_ADD_SUBDIRECTORY) }
            set { self.setValue(newValue, for: ACL_ADD_SUBDIRECTORY) }
        }

        public var searchPermission: Bool {
            get { self.value(for: ACL_SEARCH) }
            set { self.setValue(newValue, for: ACL_SEARCH) }
        }

        public var deleteChildPermission: Bool {
            get { self.value(for: ACL_DELETE_CHILD) }
            set { self.setValue(newValue, for: ACL_DELETE_CHILD) }
        }

        /// The following properties apply to both files and directories
        public var deletePermission: Bool {
            get { self.value(for: ACL_DELETE) }
            set { self.setValue(newValue, for: ACL_DELETE) }
        }

        public var readAttributesPermission: Bool {
            get { self.value(for: ACL_READ_ATTRIBUTES) }
            set { self.setValue(newValue, for: ACL_READ_ATTRIBUTES) }
        }

        public var writeAttributesPermission: Bool {
            get { self.value(for: ACL_WRITE_ATTRIBUTES) }
            set { self.setValue(newValue, for: ACL_WRITE_ATTRIBUTES) }
        }

        public var readExtendedAttributesPermission: Bool {
            get { self.value(for: ACL_READ_EXTATTRIBUTES) }
            set { self.setValue(newValue, for: ACL_READ_EXTATTRIBUTES) }
        }

        public var writeExtendedAttributesPermission: Bool {
            get { self.value(for: ACL_WRITE_EXTATTRIBUTES) }
            set { self.setValue(newValue, for: ACL_WRITE_EXTATTRIBUTES) }
        }

        public var readSecurityPermission: Bool {
            get { self.value(for: ACL_READ_SECURITY) }
            set { self.setValue(newValue, for: ACL_READ_SECURITY) }
        }

        public var writeSecurityPermission: Bool {
            get { self.value(for: ACL_WRITE_SECURITY) }
            set { self.setValue(newValue, for: ACL_WRITE_SECURITY) }
        }

        public var changeOwnerPermission: Bool {
            get { self.value(for: ACL_CHANGE_OWNER) }
            set { self.setValue(newValue, for: ACL_CHANGE_OWNER) }
        }

        public var stringRepresentationOfPermissions: String {
            var perms = [String]()

            if !self.isDirectory && self.readDataPermission {
                perms.append("read")
            }

            if !self.isDirectory && self.writeDataPermission {
                perms.append("write")
            }

            if self.isDirectory && self.listDirectoryPermission {
                perms.append("list")
            }

            if self.isDirectory && self.addFilePermission {
                perms.append("add_file")
            }

            if !self.isDirectory && self.executePermission {
                perms.append("execute")
            }

            if self.isDirectory && self.searchPermission {
                perms.append("search")
            }

            if self.deletePermission {
                perms.append("delete")
            }

            if !self.isDirectory && self.appendDataPermission {
                perms.append("append")
            }

            if self.isDirectory && self.addSubdirectoryPermission {
                perms.append("add_subdirectory")
            }

            if self.isDirectory && self.deleteChildPermission {
                perms.append("delete_child")
            }

            if self.readAttributesPermission {
                perms.append("readattr")
            }

            if self.writeAttributesPermission {
                perms.append("writeattr")
            }

            if self.readExtendedAttributesPermission {
                perms.append("readextattr")
            }

            if self.writeExtendedAttributesPermission {
                perms.append("writeextattr")
            }

            if self.readSecurityPermission {
                perms.append("readsecurity")
            }

            if self.writeSecurityPermission {
                perms.append("writesecurity")
            }

            if self.changeOwnerPermission {
                perms.append("chown")
            }

            if self.inheritToFiles {
                perms.append("file_inherit")
            }

            if self.inheritToDirectories {
                perms.append("directory_inherit")
            }

            if self.limitInheritance {
                perms.append("limit_inherit")
            }

            if self.onlyInherit {
                perms.append("only_inherit")
            }

            return perms.joined(separator: ", ")
        }

        public var isInherited: Bool { self.value(for: ACL_ENTRY_INHERITED) }

        public var inheritToFiles: Bool {
            get { self.value(for: ACL_ENTRY_FILE_INHERIT) }
            set { self.setValue(newValue, for: ACL_ENTRY_FILE_INHERIT) }
        }

        public var inheritToDirectories: Bool {
            get { self.value(for: ACL_ENTRY_DIRECTORY_INHERIT) }
            set { self.setValue(newValue, for: ACL_ENTRY_DIRECTORY_INHERIT) }
        }

        public var limitInheritance: Bool {
            get { self.value(for: ACL_ENTRY_LIMIT_INHERIT) }
            set { self.setValue(newValue, for: ACL_ENTRY_LIMIT_INHERIT) }
        }

        public var onlyInherit: Bool {
            get { self.value(for: ACL_ENTRY_ONLY_INHERIT) }
            set { self.setValue(newValue, for: ACL_ENTRY_ONLY_INHERIT) }
        }

        fileprivate var entry: acl_entry_t
        private let isDirectory: Bool

        public var description: String {
            var description: String

            switch self.owner {
            case .none:
                description = "(nil)"
            case .user:
                description = "user"
            case .group:
                description = "group"
            }

            description += ":"

            do {
                description += try self.owner?.name ?? "(nil)"
            } catch {
                description += "error: \(error)"
            }

            description += " "

            switch self.rule {
            case .allow:
                description += "allow"
            case .deny:
                description += "deny"
            default:
                description += "unknown"
            }

            description += " \(self.stringRepresentationOfPermissions)"

            return description.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        fileprivate init(aclEntry: acl_entry_t, isDirectory: Bool) {
            self.isDirectory = isDirectory
            self.entry = aclEntry
        }

        private func value(for permission: acl_perm_t) -> Bool {
            do {
                let permset = try callPOSIXFunction(expect: .zero) { acl_get_permset(self.entry, $0) }
                let perm = try callPOSIXFunction(expect: .nonNegative) { acl_get_perm_np(permset, permission) }

                return perm != 0
            } catch {
                printToStderr("Error getting value for permission \(permission)")
                return false
            }
        }

        private mutating func setValue(_ newValue: Bool, for permission: acl_perm_t) {
            do {
                let permset = try callPOSIXFunction(expect: .zero) { acl_get_permset(self.entry, $0) }

                if newValue {
                    try callPOSIXFunction(expect: .zero) { acl_add_perm(permset, permission) }
                } else {
                    try callPOSIXFunction(expect: .zero) { acl_delete_perm(permset, permission) }
                }

                try callPOSIXFunction(expect: .zero) { acl_set_permset(self.entry, permset) }
            } catch {
                printToStderr("Error setting value \(newValue) for permission \(permission)")
            }
        }

        private func value(for flag: acl_flag_t) -> Bool {
            do {
                let flagset = try callPOSIXFunction(expect: .zero) {
                    acl_get_flagset_np(UnsafeMutableRawPointer(self.entry), $0)
                }

                let flag = try callPOSIXFunction(expect: .nonNegative) { acl_get_flag_np(flagset, flag) }

                return flag != 0
            } catch {
                printToStderr("Error getting value for flag \(flag)")
                return false
            }
        }

        private func setValue(_ newValue: Bool, for flag: acl_flag_t) {
            do {
                let flagset = try callPOSIXFunction(expect: .zero) {
                    acl_get_flagset_np(UnsafeMutableRawPointer(self.entry), $0)
                }

                if newValue {
                    try callPOSIXFunction(expect: .zero) { acl_add_flag_np(flagset, flag) }
                } else {
                    try callPOSIXFunction(expect: .zero) { acl_delete_flag_np(flagset, flag) }
                }

                try callPOSIXFunction(expect: .zero) {
                    acl_set_flagset_np(UnsafeMutableRawPointer(self.entry), flagset)
                }
            } catch {
                printToStderr("Error setting value \(newValue) for flag \(flag)")
            }
        }
    }

    private final class ACLWrapper {
        var acl: acl_t
        init(acl: acl_t) { self.acl = acl }
        deinit { acl_free(UnsafeMutableRawPointer(acl)) }
    }

    private var aclWrapper: ACLWrapper
    private var aclForReading: acl_t { self.aclWrapper.acl }
    private var aclForWriting: acl_t {
        mutating get throws {
            if !isKnownUniquelyReferenced(&self.aclWrapper) {
                let newACL = try callPOSIXFunction(isWrite: true) { acl_dup(self.aclWrapper.acl) }
                self.aclWrapper = ACLWrapper(acl: newACL)
            }

            return self.aclWrapper.acl
        }
    }

    private let isDirectory: Bool

    private static func getACLEntries(for acl: acl_t, isDirectory: Bool) throws -> [Entry] {
        var entries: [Entry] = []

        while let entry = try callPOSIXFunction(expect: .zero, closure: {
            acl_get_entry(acl, (entries.isEmpty ? ACL_FIRST_ENTRY : ACL_NEXT_ENTRY).rawValue, $0)
        }) {
            entries.append(Entry(aclEntry: entry, isDirectory: isDirectory))
        }

        return entries
    }

    public init(isDirectory: Bool) throws {
        try self.init(acl: callPOSIXFunction { acl_init(0) }, isDirectory: isDirectory)
    }

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public init(path: FilePath) throws {
        let isDirectory = try FileInfo(path: path, keys: .objectType).objectType == .directory
        let acl = try callPOSIXFunction(path: path) {
            guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *) else {
                return path.withCString { acl_get_file($0, ACL_TYPE_EXTENDED) }
            }

            return path.withPlatformString { acl_get_file($0, ACL_TYPE_EXTENDED) }
        }

        try self.init(acl: acl, isDirectory: isDirectory)
    }

    public init(path: String) throws {
        let isDirectory = try FileInfo(path: path, keys: .objectType).objectType == .directory
        let acl = try callPOSIXFunction(path: path) {
            guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *) else {
                return path.withCString { acl_get_file($0, ACL_TYPE_EXTENDED) }
            }

            return path.withPlatformString { acl_get_file($0, ACL_TYPE_EXTENDED) }
        }

        try self.init(acl: acl, isDirectory: isDirectory)
    }

    public init(data: some DataProtocol, nativeRepresentation: Bool, isDirectory: Bool) throws {
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
            if let acl = nativeRepresentation ? acl_copy_int_native($0.baseAddress) : acl_copy_int($0.baseAddress) {
                return acl
            } else {
                throw errno()
            }
        }

        try self.init(acl: acl, isDirectory: isDirectory)
    }

    private init(acl: acl_t, isDirectory: Bool) throws {
        self.aclWrapper = ACLWrapper(acl: acl)
        self.isDirectory = isDirectory
        self.entries = try Self.getACLEntries(for: acl, isDirectory: isDirectory)
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

    public func dataRepresentation(native: Bool) throws -> some DataProtocol {
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

    public private(set) var entries: [Entry]

    @discardableResult public mutating func makeEntry() throws -> Entry? {
        let acl = try self.aclForWriting
        let newEntry = try callPOSIXFunction(expect: .zero, isWrite: true) {
            var acl: acl_t? = acl
            return acl_create_entry(&acl, $0)
        }

        var entry = Entry(aclEntry: newEntry!, isDirectory: self.isDirectory)

        entry.rule = .allow
        entry.owner = .user(User.current)

        self.entries.append(entry)

        return entry
    }

    public mutating func removeEntry(_ entry: Entry) throws {
        try self.removeEntries(CollectionOfOne(entry))
    }

    public mutating func removeEntries(_ entries: some Sequence<Entry>) throws {
        let acl = try self.aclForWriting
        let entriesToRemove = Set(entries.map(\.entry))

        for eachEntry in entries {
            if entriesToRemove.contains(eachEntry.entry) {
                try callPOSIXFunction(expect: .zero, isWrite: true) {
                    acl_delete_entry(acl, eachEntry.entry)
                }
            }
        }

        self.entries = try Self.getACLEntries(for: acl, isDirectory: self.isDirectory)
    }

    public func validate() throws {
        try callPOSIXFunction(expect: .zero) { acl_valid(self.aclForReading) }
    }

    public var debugDescription: String {
        do {
            var len = 0
            let desc = try callPOSIXFunction { acl_to_text(self.aclForReading, &len) }
            defer { acl_free(desc) }

            return String(cString: desc)
        } catch {
            return error.localizedDescription
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

        try callPOSIXFunction(expect: .zero, isWrite: true) {
            if value {
                return acl_add_flag_np(flagset, flag)
            } else {
                return acl_delete_flag_np(flagset, flag)
            }
        }

        try callPOSIXFunction(expect: .zero, isWrite: true) {
            acl_set_flagset_np(UnsafeMutableRawPointer(acl), flagset)
        }
    }
}

extension AccessControlList: Hashable {
    public static func == (lhs: AccessControlList, rhs: AccessControlList) -> Bool {
        lhs.debugDescription == rhs.debugDescription
    }

    public func hash(into hasher: inout Hasher) {
        self.debugDescription.hash(into: &hasher)
    }
}
