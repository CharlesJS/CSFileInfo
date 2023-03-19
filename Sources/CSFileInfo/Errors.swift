//
//  Errors.h
//  CSFileUtils
//
//  Created by Charles Srstka on 2/19/12.
//  Copyright © 2012-2023 Charles Srstka. All rights reserved.
//

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

extension FileInfo {
    public enum Error: Swift.Error {
        case invalidTypeCode(String)
        case invalidCreatorCode(String)
        case extendedAttributesNotSupported(name: String)
        case extendedAttributeNotFound(name: String, path: String?)
        case extendedAttributeAlreadyExists(name: String, path: String?)
        case uidNotFound(uid_t)
        case userNameNotFound(String)
        case gidNotFound(gid_t)
        case groupNameNotFound(String)
        case unknownError
    }
}
