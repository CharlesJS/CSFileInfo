//
//  FileInfo_Foundation.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 4/25/26.
//

#if Foundation

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(System)
import System
#else
import SystemPackage
#endif

extension FileInfo {
    public var creationDate: Date? {
        get { self.creationTime.map { Date(timespec: $0) } }
        set { self.creationTime = newValue?.timespec }
    }

    public var modificationDate: Date? {
        get { self.modificationTime.map { Date(timespec: $0) } }
        set { self.modificationTime = newValue?.timespec }
    }

    public var attributeModificationDate: Date? { self.attributeModificationTime.map { Date(timespec: $0) } }

    public var accessDate: Date? {
        get { self.accessTime.map { Date(timespec: $0) } }
        set { self.accessTime = newValue?.timespec }
    }

#if canImport(Darwin)
    public var backupDate: Date? {
        get { self.backupTime.map { Date(timespec: $0) } }
        set { self.backupTime = newValue?.timespec }
    }

    public var addedDate: Date? {
        get { self.addedTime.map { Date(timespec: $0) } }
        set { self.addedTime = newValue?.timespec }
    }
#endif

    public init(at url: URL, keys: Keys) throws {
#if canImport(Darwin)
        guard #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *), versionCheck(11) else {
            try self.init(atPath: url.path, keys: keys)
            return
        }
#endif

        try self.init(at: FilePath(url.path), keys: keys)
    }

    public func apply(to url: URL) throws {
#if canImport(Darwin)
        guard #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *), versionCheck(11) else {
            try self.apply(toPath: url.path)
            return
        }
#endif

        try self.apply(to: FilePath(url.path))
    }
}

#endif
