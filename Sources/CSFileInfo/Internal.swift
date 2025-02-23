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

#if Foundation
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
#endif

#if DEBUG
nonisolated(unsafe) private var emulatedVersion: Int = .max

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

#if Foundation
extension Date {
    internal init(timespec aTimespec: timespec) {
        self = Date(timeIntervalSince1970: TimeInterval(aTimespec.tv_sec) + TimeInterval(aTimespec.tv_nsec) / TimeInterval(NSEC_PER_SEC))
    }

    internal var timespec: timespec {
        var iPart = 0.0
        let fPart = modf(self.timeIntervalSince1970, &iPart)

        return Darwin.timespec(tv_sec: __darwin_time_t(lrint(iPart)), tv_nsec: lrint(fPart * Double(NSEC_PER_SEC)))
    }
}
#endif
