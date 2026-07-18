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
import CSFileInfo_CShims
private let NSEC_PER_SEC = 1_000_000_000
#endif

#if canImport(SystemPackage)
import SystemPackage
#else
import System
#endif

#if Foundation
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
#endif

#if DEBUG
@TaskLocal private var emulatedVersion: Int = .max

func emulateOSVersion(_ version: Int, closure: () throws -> Void) rethrows {
    try $emulatedVersion.withValue(version) {
        try closure()
    }
}

func emulateOSVersionAsync(_ version: Int, closure: () async throws -> Void) async rethrows {
    try await $emulatedVersion.withValue(version) {
        try await closure()
    }
}

package func versionCheck(_ version: Int) -> Bool { emulatedVersion >= version }
#else
@inline(__always) package func versionCheck(_: Int) -> Bool { true }
#endif

func fsidsEqual(_ lhs: fsid_t?, _ rhs: fsid_t?) -> Bool {
#if canImport(Darwin)
    lhs?.val.0 == rhs?.val.0 && lhs?.val.1 == rhs?.val.1
#elseif canImport(Glibc)
    lhs?.__val.0 == rhs?.__val.0 && lhs?.__val.1 == rhs?.__val.1
#endif
}

func timesEqual(_ l: timespec?, _ r: timespec?) -> Bool {
    l?.tv_sec == r?.tv_sec && l?.tv_nsec == r?.tv_nsec
}

func uuidsEqual(_ l: uuid_t?, _ r: uuid_t?) -> Bool {
    guard var l, var r else { return (l == nil) && (r == nil) }
    return uuid_compare(&l, &r) == 0
}


#if Foundation
extension Date {
    internal init(timespec aTimespec: timespec) {
        self = Date(timeIntervalSince1970: TimeInterval(aTimespec.tv_sec) + TimeInterval(aTimespec.tv_nsec) / TimeInterval(NSEC_PER_SEC))
    }

    internal var timespec: timespec {
        var iPart = 0.0
        let fPart = modf(self.timeIntervalSince1970, &iPart)

#if canImport(Darwin)
        return Darwin.timespec(tv_sec: __darwin_time_t(lrint(iPart)), tv_nsec: lrint(fPart * Double(NSEC_PER_SEC)))
#else
        return Glibc.timespec(tv_sec: __time_t(lrint(iPart)), tv_nsec: lrint(fPart * Double(NSEC_PER_SEC)))
#endif
    }
}
#endif
