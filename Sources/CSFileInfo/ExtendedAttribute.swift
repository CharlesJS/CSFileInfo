//
//  ExtendedAttribute.swift
//
//
//  Created by Charles Srstka on 11/5/23.
//

import CSErrors
import System

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

#if Foundation
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
#endif

public struct ExtendedAttribute: Codable, Hashable, Sendable {
    public struct ReadOptions: OptionSet, Sendable {
        public let rawValue: Int32
        public init(rawValue: Int32) { self.rawValue = rawValue }

        public static let noTraverseLink = ReadOptions(rawValue: XATTR_NOFOLLOW)
        public static let showCompression = ReadOptions(rawValue: XATTR_SHOWCOMPRESSION)
    }
    
    public struct WriteOptions: OptionSet, Sendable {
        public let rawValue: Int32
        public init(rawValue: Int32) { self.rawValue = rawValue }

        public static let noTraverseLink = WriteOptions(rawValue: XATTR_NOFOLLOW)
        public static let create = WriteOptions(rawValue: XATTR_CREATE)
        public static let replace = WriteOptions(rawValue: XATTR_REPLACE)
    }

    public struct RemoveOptions: OptionSet, Sendable {
        public let rawValue: Int32
        public init(rawValue: Int32) { self.rawValue = rawValue }

        public static let noTraverseLink = RemoveOptions(rawValue: XATTR_NOFOLLOW)
    }

#if Foundation
    public static func list(at url: URL, options: ReadOptions = []) throws -> [ExtendedAttribute] {
        guard url.isFileURL else { throw CocoaError(.fileReadUnsupportedScheme, url: url) }

        guard #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *), versionCheck(11) else {
            return try self.list(atPath: url.path, options: options)
        }

        return try self.list(at: FilePath(url.path), options: options)
    }
#endif

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public static func list(at path: FilePath, options: ReadOptions = []) throws -> [ExtendedAttribute] {
        let fdOptions: FileDescriptor.OpenOptions = options.contains(.noTraverseLink) ? .symlink : []
        let descriptor = try FileDescriptor.open(path, .readOnly, options: fdOptions)
        defer { _ = try? descriptor.close() }

        return try self.list(path: String(describing: path), fd: descriptor.rawValue, options: options)
    }

    public static func list(atPath path: String, options: ReadOptions = []) throws -> [ExtendedAttribute] {
        guard #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *), versionCheck(11) else {
            let flags: Int32 = options.contains(.noTraverseLink) ? O_RDONLY | O_SYMLINK : O_RDONLY
            let fd = try callPOSIXFunction(expect: .nonNegative, path: path) { open(path, flags) }
            defer { close(fd) }

            return try self.list(path: path, fd: fd, options: options)
        }

        return try self.list(at: FilePath(path), options: options)
    }

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public static func list(at fileDescriptor: FileDescriptor, options: ReadOptions = []) throws -> [ExtendedAttribute] {
        try self.list(path: nil, fd: fileDescriptor.rawValue, options: options)
    }

    public static func list(atFileDescriptor fd: Int32, options: ReadOptions = []) throws -> [ExtendedAttribute] {
        try self.list(path: nil, fd: fd, options: options)
    }

    private static func list(path: String?, fd: Int32, options opts: ReadOptions) throws -> [ExtendedAttribute] {
        // XATTR_NOFOLLOW is not available for flistxattr
        let options = opts.subtracting(.noTraverseLink)

        let bufsize = try callPOSIXFunction(expect: .nonNegative, path: path) { flistxattr(fd, nil, 0, options.rawValue) }
        let buf = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: bufsize)
        defer { buf.deallocate() }

        let size = try callPOSIXFunction(expect: .nonNegative, path: path) {
            flistxattr(fd, buf.baseAddress, buf.count, options.rawValue)
        }

        return try buf[..<size].split(separator: 0).map {
            let key = String(decoding: $0, as: UTF8.self)

            return try ExtendedAttribute(path: path, fileDescriptor: fd, key: key, options: options)
        }
    }

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public static func write(
        _ attrs: some Sequence<ExtendedAttribute>,
        to path: FilePath,
        options: WriteOptions = []
    ) throws {
        let fdOptions: FileDescriptor.OpenOptions = options.contains(.noTraverseLink) ? .symlink : []
        let descriptor = try FileDescriptor.open(path, .writeOnly, options: fdOptions)
        defer { _ = try? descriptor.close() }

        for eachAttr in attrs {
            try eachAttr.write(to: descriptor, options: options)
        }
    }

    public static func write(
        _ attrs: some Sequence<ExtendedAttribute>,
        toPath path: String,
        options: WriteOptions = []
    ) throws {
        guard #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *), versionCheck(11) else {
            let flags: Int32 = options.contains(.noTraverseLink) ? O_WRONLY | O_SYMLINK : O_WRONLY
            let fd = try callPOSIXFunction(expect: .nonNegative, path: path) { open(path, flags) }
            defer { close(fd) }

            for eachAttr in attrs {
                try eachAttr.write(path: path, fileDescriptor: fd, options: options)
            }

            return
        }

        try self.write(attrs, to: FilePath(path), options: options)
    }

#if Foundation
    public static func write(_ attrs: some Sequence<ExtendedAttribute>, to url: URL, options: WriteOptions = []) throws {
        guard url.isFileURL else { throw CocoaError(.fileWriteUnsupportedScheme, url: url) }

        guard #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *), versionCheck(11) else {
            try self.write(attrs, toPath: url.path, options: options)
            return
        }

        try self.write(attrs, to: FilePath(url.path), options: options)
    }
#endif

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public static func remove(keys: some Sequence<String>, at path: FilePath, options: RemoveOptions = []) throws {
        let openOptions: FileDescriptor.OpenOptions = options.contains(.noTraverseLink) ? .symlink : []
        let fileDescriptor = try FileDescriptor.open(path, .writeOnly, options: openOptions)
        defer { _ = try? fileDescriptor.close() }

        guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12) else {
            try self.remove(keys: keys, path: String(describing: path), fd: fileDescriptor.rawValue)
            return
        }

        try self.remove(keys: keys, path: path.string, fd: fileDescriptor.rawValue)
    }

    public static func remove(keys: some Sequence<String>, atPath path: String, options: RemoveOptions = []) throws {
        guard #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *), versionCheck(11) else {
            let flags = options.contains(.noTraverseLink) ? O_WRONLY | O_SYMLINK : O_WRONLY
            let fd = try callPOSIXFunction(expect: .nonNegative) { open(path, flags) }
            defer { close(fd) }

            try self.remove(keys: keys, path: path, fd: fd)
            return
        }

        try self.remove(keys: keys, at: FilePath(path), options: options)
    }

#if Foundation
    public static func remove(keys: some Sequence<String>, at url: URL, options: RemoveOptions = []) throws {
        guard url.isFileURL else { throw CocoaError(.fileWriteUnsupportedScheme, url: url) }


        guard #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *), versionCheck(11) else {
            try self.remove(keys: keys, atPath: url.path, options: options)
            return
        }

        try self.remove(keys: keys, at: FilePath(url.path), options: options)
    }
#endif

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public static func remove(keys: some Sequence<String>, at fd: FileDescriptor, options: RemoveOptions = []) throws {
        try self.remove(keys: keys, path: nil, fd: fd.rawValue)
    }

    public static func remove(keys: some Sequence<String>, atFileDescriptor fd: Int32, options: RemoveOptions = []) throws {
        try self.remove(keys: keys, path: nil, fd: fd)
    }

    private static func remove(keys: some Sequence<String>, path: String?, fd: Int32) throws {
        for eachKey in keys {
            try callPOSIXFunction(expect: .zero, path: path) { fremovexattr(fd, eachKey, 0) }
        }
    }

    public var key: String
    public var data: ContiguousArray<UInt8>

    public init(key: String, data: some Sequence<UInt8>) {
        self.key = key
        self.data = ContiguousArray(data)
    }

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public init(at path: FilePath, key: String, options: ReadOptions = []) throws {
        guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12) else {
            self = try path.withCString {
                try ExtendedAttribute(path: String(describing: path), cPath: $0, key: key, options: options)
            }

            return
        }

        self = try path.withPlatformString {
            try ExtendedAttribute(path: path.string, cPath: $0, key: key, options: options)
        }
    }
    
    public init(atPath path: String, key: String, options: ReadOptions = []) throws {
        guard #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *), versionCheck(12) else {
            self = try path.withCString { try ExtendedAttribute(path: path, cPath: $0, key: key, options: options) }
            return
        }

        try self.init(at: FilePath(path), key: key, options: options)
    }

#if Foundation
    public init(at url: URL, key: String, options: ReadOptions = []) throws {
        guard url.isFileURL else { throw CocoaError(.fileReadUnsupportedScheme, url: url) }

        guard #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *), versionCheck(11) else {
            try self.init(atPath: url.path, key: key, options: options)
            return
        }

        try self.init(at: FilePath(url.path), key: key, options: options)
    }
#endif

    private init(path: String, cPath: UnsafePointer<CChar>, key: String, options: ReadOptions) throws {
        let bufsize = try callPOSIXFunction(expect: .nonNegative, path: path) {
            getxattr(cPath, key, nil, 0, 0, options.rawValue)
        }

        self.key = key
        self.data = try ContiguousArray<UInt8>(unsafeUninitializedCapacity: bufsize) { buffer, count in
            count = try callPOSIXFunction(expect: .nonNegative, path: path) {
                getxattr(cPath, key, buffer.baseAddress, buffer.count, 0, options.rawValue)
            }
        }
    }

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public init(at fileDescriptor: FileDescriptor, key: String, options: ReadOptions = []) throws {
        try self.init(path: nil, fileDescriptor: fileDescriptor.rawValue, key: key, options: options)
    }

    public init(atFileDescriptor fd: Int32, key: String, options: ReadOptions = []) throws {
        try self.init(path: nil, fileDescriptor: fd, key: key, options: options)
    }

    private init(path: String?, fileDescriptor fd: Int32, key: String, options opts: ReadOptions) throws {
        // XATTR_NOFOLLOW is not available for fgetxattr
        let options = opts.subtracting(.noTraverseLink)

        let bufsize = try callPOSIXFunction(expect: .nonNegative, path: path) {
            fgetxattr(fd, key, nil, 0, 0, options.rawValue)
        }

        self.key = key
        self.data = try ContiguousArray<UInt8>(unsafeUninitializedCapacity: bufsize) { buffer, count in
            count = try callPOSIXFunction(expect: .nonNegative, path: path) {
                fgetxattr(fd, key, buffer.baseAddress, buffer.count, 0, options.rawValue)
            }
        }
    }

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public func write(to path: FilePath, options: WriteOptions = []) throws {
        guard #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, macCatalyst 15.0, *), versionCheck(12) else {
            try path.withCString { try self.write(path: String(decoding: path), cPath: $0, options: options) }
            return
        }

        return try path.withPlatformString { try self.write(path: path.string, cPath: $0, options: options) }
    }

    public func write(toPath path: String, options: WriteOptions = []) throws {
        guard #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *), versionCheck(12) else {
            return try path.withCString { try self.write(path: path, cPath: $0, options: options) }
        }

        return try self.write(to: FilePath(path), options: options)
    }

#if Foundation
    public func write(to url: URL, options: WriteOptions = []) throws {
        guard url.isFileURL else { throw CocoaError(.fileWriteUnsupportedScheme, url: url) }

        guard #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *), versionCheck(11) else {
            try self.write(toPath: url.path, options: options)
            return
        }

        try self.write(to: FilePath(url.path), options: options)
    }
#endif

    private func write(path: String, cPath: UnsafePointer<CChar>, options: WriteOptions) throws {
        try self.data.withUnsafeBytes { bytes in
            _ = try callPOSIXFunction(expect: .zero, path: path) {
                setxattr(cPath, self.key, bytes.baseAddress, bytes.count, 0, options.rawValue)
            }
        }
    }

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, macCatalyst 14.0, *)
    public func write(to fd: FileDescriptor, options: WriteOptions = []) throws {
        try self.write(path: nil, fileDescriptor: fd.rawValue, options: options)
    }

    public func write(toFileDescriptor fd: Int32, options: WriteOptions = []) throws {
        try self.write(path: nil, fileDescriptor: fd, options: options)
    }

    private func write(path: String?, fileDescriptor fd: Int32, options opts: WriteOptions) throws {
        // XATTR_NOFOLLOW is not available for fsetxattr
        let options = opts.subtracting(.noTraverseLink)

        try self.data.withUnsafeBytes { bytes in
            _ = try callPOSIXFunction(expect: .zero, path: path) {
                fsetxattr(fd, self.key, bytes.baseAddress, bytes.count, 0, options.rawValue)
            }
        }
    }
}
