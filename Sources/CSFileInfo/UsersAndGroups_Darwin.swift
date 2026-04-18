//
//  UsersAndGroups_Darwin.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 5/20/17.
//

#if canImport(Darwin)
import CSErrors
import CShims

#if canImport(SystemPackage)
import SystemPackage
#else
import System
#endif

public enum UserOrGroup: CustomStringConvertible, Sendable {
    case user(User)
    case group(Group)
    case unknown(uuid_t)

    public init(uuid: uuid_t, allowUnknown: Bool = false) throws {
        var id: id_t = 0
        var type: Int32 = 0

        var uuid = uuid
        let err = withUnsafePointer(to: &uuid) { mbr_uuid_to_id($0, &id, &type) }

        if allowUnknown && err == ENOENT {
            self = .unknown(uuid)
            return
        }

        if err != 0 {
            throw errno(err)
        }

        switch type {
        case ID_TYPE_UID:
            self = .user(User(id: id))
        case ID_TYPE_GID:
            self = .group(Group(id: id))
        default:
            // should not be reachable in practice
            throw FileInfo.Error.unknownError
        }
    }

    public var uuid: uuid_t {
        get throws {
            switch self {
            case .user(let user):
                return try user.uuid
            case .group(let group):
                return try group.uuid
            case .unknown(let uuid):
                return uuid
            }
        }
    }

    public var name: String? {
        get throws {
            switch self {
            case .user(let user):
                return try user.name
            case .group(let group):
                return try group.name
            case .unknown:
                return nil
            }
        }
    }

    public var description: String {
        switch self {
        case .user(let user):
            return user.description
        case .group(let group):
            return group.description
        case .unknown(var uuid):
            let uuidString = withUnsafeTemporaryAllocation(of: uuid_string_t.self, capacity: 1) {
                $0.withMemoryRebound(to: CChar.self) { str in
                    uuid_unparse(&uuid, str.baseAddress)
                }

                return $0.withMemoryRebound(to: UInt8.self) {
                    guard let str = $0.baseAddress else { return "" }

                    return String(decodingCString: str, as: UTF8.self)
                }
            }

            return "unknown: \(uuidString)"
        }
    }
}

extension UserOrGroup: Equatable {
    public static func == (lhs: UserOrGroup, rhs: UserOrGroup) -> Bool {
        switch (lhs, rhs) {
        case (.user(let lUser), .user(let rUser)):
            return lUser.id == rUser.id
        case (.group(let lGroup), .group(let rGroup)):
            return lGroup.id == rGroup.id
        case (.unknown(var lUUID), .unknown(var rUUID)):
            return uuid_compare(&lUUID, &rUUID) == 0
        default:
            return false
        }
    }
}

extension UserOrGroup: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .user(let user):
            1.hash(into: &hasher)
            user.hash(into: &hasher)
        case .group(let group):
            2.hash(into: &hasher)
            group.hash(into: &hasher)
        case .unknown(let uuid):
            func hashUUID<each T: Hashable>(_ bytes: (repeat each T)) {
                for eachByte in repeat (each bytes) {
                    eachByte.hash(into: &hasher)
                }
            }

            3.hash(into: &hasher)
            hashUUID(uuid)
        }
    }
}

public struct User: Hashable, CustomStringConvertible, Sendable {
    public static var current: User { User(id: getuid()) }

    public init(id: uid_t) {
        self.id = id
    }

    public init?(name: String) throws {
        guard let id = try wrapPwdAPI(getpwnam_r, name, { $0.pw_uid }) else {
            return nil
        }

        self.id = id
    }

    public let id: uid_t

    public var name: String? {
        get throws {
            try wrapPwdAPI(getpwuid_r, self.id, { String(cString: $0.pw_name) })
        }
    }

    public var uuid: uuid_t {
        get throws {
            try callPOSIXFunction(expect: .zero, errorFrom: .returnValue) {
                $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<uuid_t>.size) {
                    mbr_uid_to_uuid(self.id, $0)
                }
            }
        }
    }

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public var homeDirectory: FilePath? {
        get throws {
            try wrapPwdAPI(getpwuid_r, self.id) {
                guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12) else {
                    return FilePath(String(cString: $0.pw_dir))
                }

                return FilePath(platformString: $0.pw_dir)
            }
        }
    }

    public var homeDirectoryStringPath: String? {
        get throws {
            guard #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *), versionCheck(11) else {
                return try wrapPwdAPI(getpwuid_r, self.id) { String(cString: $0.pw_dir) }
            }

            guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12) else {
                return try self.homeDirectory.map { String(describing: $0) }
            }

            return try self.homeDirectory?.string
        }
    }

    public var description: String {
        guard let name = try? self.name else {
            return "UID \(self.id)"
        }

        return "\(name) (UID \(self.id))"
    }
}

public struct Group: Hashable, CustomStringConvertible, Sendable {
    public static var current: Group { Group(id: getgid()) }

    public init(id: gid_t) {
        self.id = id
    }

    public init?(name: String) throws {
        guard let id = try wrapPwdAPI(getgrnam_r, name, { $0.gr_gid }) else {
            return nil
        }

        self.id = id
    }

    public let id: gid_t

    public var name: String? {
        get throws {
            try wrapPwdAPI(getgrgid_r, self.id, { String(cString: $0.gr_name) })
        }
    }

    public var uuid: uuid_t {
        get throws {
            try callPOSIXFunction(expect: .zero, errorFrom: .returnValue) {
                $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<uuid_t>.size) {
                    mbr_gid_to_uuid(self.id, $0)
                }
            }
        }
    }

    public var description: String {
        guard let name = try? self.name else {
            return "GID \(self.id)"
        }

        return "\(name) (GID \(self.id))"
    }
}

private func wrapPwdAPI<Argument, ReturnValue, PwdType>(
    _ pwdFunc: (
        Argument,
        UnsafeMutablePointer<PwdType>?,
        UnsafeMutablePointer<CChar>?,
        Int,
        UnsafeMutablePointer<UnsafeMutablePointer<PwdType>?>?
    ) -> Int32,
    _ argument: Argument,
    _ closure: (PwdType) -> ReturnValue
) throws -> ReturnValue? {
    let bufsize = try callPOSIXFunction(expect: .notSpecific(-1)) {
        errno = ENOTSUP
        return sysconf(_SC_GETPW_R_SIZE_MAX)
    }

    return try withUnsafeTemporaryAllocation(of: CChar.self, capacity: Int(bufsize)) { buffer in
        try withUnsafeTemporaryAllocation(of: PwdType.self, capacity: 1) { pwd in
            var retPwd: UnsafeMutablePointer<PwdType>? = nil

            try callPOSIXFunction(expect: .zero, errorFrom: .returnValue) {
                pwdFunc(argument, pwd.baseAddress, buffer.baseAddress, buffer.count, &retPwd)
            }

            if retPwd == nil {
                return nil
            }

            return closure(pwd.baseAddress!.pointee)
        }
    }
}
#endif
