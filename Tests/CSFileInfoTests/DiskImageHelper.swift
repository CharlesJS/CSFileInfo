//
//  DiskImageHelper.swift
//
//
//  Created by Charles Srstka on 10/28/23.
//

import XCTest

struct DiskImageHelper {
    static let shared = Self.init()

    func createImage(url: URL, size: UInt64) throws {
        let hdiutil = Process()

        hdiutil.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        hdiutil.arguments = ["create", "-size", "\(size)b", url.path]

        try hdiutil.run()
        hdiutil.waitUntilExit()

        if hdiutil.terminationStatus != 0 {
            throw NSError(domain: "hdiutil", code: Int(hdiutil.terminationStatus), userInfo: nil)
        }
    }

    func mountImage(url: URL, readOnly: Bool) throws -> (mountPoint: URL, devEntry: String) {
        let hdiutil = Process()
        let pipe = Pipe()

        var args = ["attach", url.path, "-plist"]
        if readOnly {
            args.append("-readonly")
        }

        hdiutil.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        hdiutil.arguments = args
        hdiutil.standardOutput = pipe

        try hdiutil.run()

        let data = try XCTUnwrap(pipe.fileHandleForReading.readToEnd())
        let dict = try XCTUnwrap(PropertyListSerialization.propertyList(from: data, format: nil) as? [String : Any])

        for eachEntity in try XCTUnwrap(dict["system-entities"] as? [[String : Any]]) {
            if let mountPoint = eachEntity["mount-point"] as? String, let devEntry = eachEntity["dev-entry"] as? String {
                return (mountPoint: URL(filePath: mountPoint), devEntry: devEntry)
            }
        }

        throw CocoaError(.fileReadUnknown)
    }

    func unmountImage(devEntry: String) throws {
        let hdiutil = Process()

        hdiutil.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        hdiutil.arguments = ["detach", devEntry]

        try hdiutil.run()
        hdiutil.waitUntilExit()
    }
}
