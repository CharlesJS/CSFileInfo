//
//  Internal.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 5/9/17.
//

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

#if DEBUG
private var emulatedVersion: Int = .max

func emulateOSVersion(_ version: Int, closure: () throws -> Void) rethrows {
    emulatedVersion = version
    defer { emulatedVersion = .max }

    try closure()
}

func emulateOSVersionAsync(_ version: Int, closure: () async throws -> Void) async throws {
    emulatedVersion = version
    defer { emulatedVersion = .max }

    try await closure()
}

package func versionCheck(_ version: Int) -> Bool { emulatedVersion >= version }
#else
@inline(__always) package func versionCheck(_: Int) -> Bool { true }
#endif

func fsidsEqual(_ lhs: fsid_t?, _ rhs: fsid_t?) -> Bool {
    lhs?.val.0 == rhs?.val.0 && lhs?.val.1 == rhs?.val.1
}
