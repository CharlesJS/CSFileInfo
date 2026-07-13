//
//  UsersAndGroups_Glibc.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 4/18/26.
//

#if canImport(Glibc)
import Glibc
import CSErrors

#if canImport(SystemPackage)
import SystemPackage
#else
import System
#endif

public enum UserOrGroup: Hashable, CustomStringConvertible, Sendable {
    case user(User)
    case group(Group)

    init(userID: uid_t) {
        self = .user(User(id: userID))
    }

    init(groupID: gid_t) {
        self = .group(Group(id: groupID))
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
            try wrapPwdAPI(getpwuid_r, self.id, { String(platformString: $0.pw_name) })
        }
    }

    public var homeDirectory: FilePath? {
        get throws {
            try wrapPwdAPI(getpwuid_r, self.id) {
                FilePath(String(platformString: $0.pw_dir))
            }
        }
    }

    public var homeDirectoryStringPath: String? {
        get throws {
            try wrapPwdAPI(getpwuid_r, self.id) { String(platformString: $0.pw_dir) }
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
            try wrapPwdAPI(getgrgid_r, self.id) { String(platformString: $0.gr_name) }
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
        UnsafeMutablePointer<PwdType>,
        UnsafeMutablePointer<CChar>,
        Int,
        UnsafeMutablePointer<UnsafeMutablePointer<PwdType>?>
    ) -> Int32,
    _ argument: Argument,
    _ closure: (PwdType) -> ReturnValue
) throws -> ReturnValue? {
    let bufsize = sysconf(Int32(_SC_GETPW_R_SIZE_MAX))
    guard bufsize > 0 else {
        throw errno(ENOMEM)
    }

    return try withUnsafeTemporaryAllocation(of: CChar.self, capacity: bufsize) { buffer in
        try withUnsafeTemporaryAllocation(of: PwdType.self, capacity: 1) { pwd in
            var retPwd: UnsafeMutablePointer<PwdType>? = nil

            try callPOSIXFunction(expect: .zero, errorFrom: .returnValue) {
                pwdFunc(argument, pwd.baseAddress!, buffer.baseAddress!, buffer.count, &retPwd)
            }

            if retPwd == nil {
                return nil
            }

            return closure(pwd.baseAddress!.pointee)
        }
    }
}

#endif
