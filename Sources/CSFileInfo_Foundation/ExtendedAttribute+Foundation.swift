//
//  ExtendedAttribute+Foundation.swift
//
//
//  Created by Charles Srstka on 11/5/23.
//

import CSFileInfo
import Foundation
import System

extension ExtendedAttribute {
    public static func list(at url: URL, options: ReadOptions = []) throws -> [ExtendedAttribute] {
        guard url.isFileURL else { throw CocoaError(.fileReadUnsupportedScheme, url: url) }

        guard #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *), versionCheck(11) else {
            return try self.list(atPath: url.path, options: options)
        }

        return try self.list(at: FilePath(url.path), options: options)
    }

    public static func write(_ attrs: some Sequence<ExtendedAttribute>, to url: URL, options: WriteOptions = []) throws {
        guard url.isFileURL else { throw CocoaError(.fileWriteUnsupportedScheme, url: url) }

        guard #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *), versionCheck(11) else {
            try self.write(attrs, toPath: url.path, options: options)
            return
        }

        try self.write(attrs, to: FilePath(url.path), options: options)
    }

    public static func remove(keys: some Sequence<String>, at url: URL, options: RemoveOptions = []) throws {
        guard url.isFileURL else { throw CocoaError(.fileWriteUnsupportedScheme, url: url) }


        guard #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *), versionCheck(11) else {
            try self.remove(keys: keys, atPath: url.path, options: options)
            return
        }

        try self.remove(keys: keys, at: FilePath(url.path), options: options)
    }

    public init(at url: URL, key: String, options: ReadOptions = []) throws {
        guard url.isFileURL else { throw CocoaError(.fileReadUnsupportedScheme, url: url) }

        guard #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *), versionCheck(11) else {
            try self.init(path: url.path, key: key, options: options)
            return
        }

        try self.init(path: FilePath(url.path), key: key, options: options)
    }

    public func write(to url: URL, options: WriteOptions = []) throws {
        guard url.isFileURL else { throw CocoaError(.fileWriteUnsupportedScheme, url: url) }

        guard #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *), versionCheck(11) else {
            try self.write(toPath: url.path, options: options)
            return
        }

        try self.write(to: FilePath(url.path), options: options)
    }
}
