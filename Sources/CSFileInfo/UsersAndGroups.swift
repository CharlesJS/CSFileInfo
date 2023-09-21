//
//  UsersAndGroups.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 5/20/17.
//
//

import CSErrors
import Membership

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
        errno = 0

        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12),
           let pw = name.withPlatformString({ getpwnam($0) }) {
            self.id = pw.pointee.pw_uid
        } else if let pw = name.withCString({ getpwnam($0) }) {
            self.id = pw.pointee.pw_uid
        } else if errno != 0 {
            throw errno()
        } else {
            return nil
        }
    }

    public let id: uid_t

    public var name: String? {
        get throws {
            errno = 0

            if let pw = getpwuid(self.id) {
                guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12) else {
                    return String(cString: pw.pointee.pw_name)
                }

                return String(platformString: pw.pointee.pw_name)
            } else if errno != 0 {
                throw errno()
            }

            return nil
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
        errno = 0

        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12),
           let grp = name.withPlatformString({ getgrnam($0) }) {
            self.id = grp.pointee.gr_gid
        } else if let grp = name.withCString({ getgrnam($0) }) {
            self.id = grp.pointee.gr_gid
        } else if errno != 0 {
            throw errno()
        } else {
            return nil
        }
    }

    public let id: gid_t

    public var name: String? {
        get throws {
            errno = 0

            if let grp = getgrgid(self.id) {
                guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12) else {
                    return String(cString: grp.pointee.gr_name)
                }

                return String(platformString: grp.pointee.gr_name)
            } else if errno != 0 {
                throw errno()
            }

            return nil
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
