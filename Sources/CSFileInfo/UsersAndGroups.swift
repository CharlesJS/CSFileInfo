//
//  UsersAndGroups.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 5/20/17.
//
//

import CSErrors
import CSFileInfo_Membership

public enum UserOrGroup: Hashable, CustomStringConvertible {
    case user(User)
    case group(Group)

    public init(uuid: uuid_t) throws {
        var id: id_t = 0
        var type: Int32 = 0

        try callPOSIXFunction(expect: .zero, errorFrom: .returnValue) {
            var uuid = uuid

            return withUnsafePointer(to: &uuid) { mbr_uuid_to_id($0, &id, &type) }
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
            }
        }
    }

    public var description: String {
        switch self {
        case .user(let user):
            return user.description
        case .group(let group):
            return group.description
        }
    }
}

public struct User: Hashable, CustomStringConvertible {
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

    public var description: String {
        guard let name = try? self.name else {
            return "UID \(self.id)"
        }

        return "\(name) (UID \(self.id))"
    }
}

public struct Group: Hashable, CustomStringConvertible {
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

    let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: Int(bufsize))
    defer { buffer.deallocate() }

    let pwd = UnsafeMutablePointer<PwdType>.allocate(capacity: 1)
    defer { pwd.deallocate() }

    var retPwd: UnsafeMutablePointer<PwdType>? = nil

    try callPOSIXFunction(expect: .zero, errorFrom: .returnValue) {
        pwdFunc(argument, pwd, buffer, bufsize, &retPwd)
    }

    if retPwd == nil {
        return nil
    }

    return closure(pwd.pointee)
}
