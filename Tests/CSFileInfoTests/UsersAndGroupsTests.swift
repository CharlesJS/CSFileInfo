//
//  UsersAndGroupsTests.swift
//  
//
//  Created by Charles Srstka on 6/3/23.
//

@testable import CSFileInfo
import CShims
import Testing

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(SystemPackage)
import SystemPackage
#else
import System
#endif

@Suite
struct UsersAndGroupsTests {
    private let meUID = getuid()
#if canImport(Darwin)
    private let meUUID: UUID = {
        var uuid: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

        withUnsafeMutableBytes(of: &uuid) {
            #expect($0.withMemoryRebound(to: UInt8.self) { mbr_uid_to_uuid(getuid(), $0.baseAddress) } == 0)
        }

        return UUID(uuid: uuid)
    }()

    private let rootUID = 0
    private let rootUUID: UUID = {
        var uuid: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

        withUnsafeMutableBytes(of: &uuid) {
            #expect($0.withMemoryRebound(to: UInt8.self) { mbr_uid_to_uuid(0, $0.baseAddress) } == 0)
        }

        return UUID(uuid: uuid)
    }()

    private let myGroupUID = getgid()
    private let myGroupName = String(cString: getgrgid(getgid())!.pointee.gr_name)
    private let myGroupUUID: UUID = {
        var uuid: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

        withUnsafeMutableBytes(of: &uuid) {
            #expect($0.withMemoryRebound(to: UInt8.self) { mbr_gid_to_uuid(getgid(), $0.baseAddress) } == 0)
        }

        return UUID(uuid: uuid)
    }()

    private let wheelUID = getgid()
    private let wheelUUID: UUID = {
        var uuid: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

        withUnsafeMutableBytes(of: &uuid) {
            #expect($0.withMemoryRebound(to: UInt8.self) { mbr_gid_to_uuid(0, $0.baseAddress) } == 0)
        }

        return UUID(uuid: uuid)
    }()
#else
    private let meUUID: UUID = UUID()
    private let rootUUID: UUID = UUID()
    private let myGroupUUID: UUID = UUID()
    private let wheelUUID: UUID = UUID()
    private let myGroupName = String(cString: getgrgid(getgid())!.pointee.gr_name)
#endif

    @Test(arguments: [10, 11, 12, 13, .max])
    func testOSVersion(version: Int) throws {
        try emulateOSVersion(version) {
            try self.testCurrentUser()
            try self.testUserByID()
            try self.testUserByName()
            try self.testCurrentGroup()
            try self.testGroupByID()
            try self.testGroupByName()
#if canImport(Darwin)
            try self.testLookupByUUID()
#endif
        }
    }

    @Test
    func testCurrentUser() throws {
        let user = User.current

        #expect(user.id == getuid())
        #expect(try user.name == ProcessInfo.processInfo.userName)
#if canImport(Darwin)
        #expect(try UUID(uuid: user.uuid) == meUUID)
#endif
        #expect(user.description == "\(ProcessInfo.processInfo.userName) (UID \(getuid()))")
        #expect(try user.homeDirectory == FilePath(FileManager.default.homeDirectoryForCurrentUser.path))
        #expect(try user.homeDirectoryStringPath == FileManager.default.homeDirectoryForCurrentUser.path)
    }

    @Test
    func testUserByID() throws {
        let me = User(id: getuid())
        let root = User(id: 0)

        #expect(me.id == getuid())
        #expect(try me.name == ProcessInfo.processInfo.userName)
#if canImport(Darwin)
        #expect(try UUID(uuid: me.uuid) == meUUID)
#endif
        #expect(me.description == "\(ProcessInfo.processInfo.userName) (UID \(getuid()))")
        #expect(try me.homeDirectory == FilePath(FileManager.default.homeDirectoryForCurrentUser.path))
        #expect(try me.homeDirectoryStringPath == FileManager.default.homeDirectoryForCurrentUser.path)

        #expect(root.id == 0)
        #expect(try root.name == "root")
#if canImport(Darwin)
        #expect(try UUID(uuid: root.uuid) == rootUUID)
#endif
        #expect(root.description == "root (UID 0)")
        #expect(try root.homeDirectory == FilePath(FileManager.default.homeDirectory(forUser: "root")!.path))
        #expect(try root.homeDirectoryStringPath == FileManager.default.homeDirectory(forUser: "root")!.path)
    }

    @Test
    func testUserByName() throws {
        let me = try #require(try User(name: ProcessInfo.processInfo.userName))
        let root = try #require(try User(name: "root"))

        #expect(me.id == getuid())
        #expect(try me.name == ProcessInfo.processInfo.userName)
#if canImport(Darwin)
        #expect(try UUID(uuid: me.uuid) == meUUID)
#endif
        #expect(me.description == "\(ProcessInfo.processInfo.userName) (UID \(getuid()))")
        #expect(try me.homeDirectory == FilePath(FileManager.default.homeDirectoryForCurrentUser.path))
        #expect(try me.homeDirectoryStringPath == FileManager.default.homeDirectoryForCurrentUser.path)

        #expect(root.id == 0)
        #expect(try root.name == "root")
#if canImport(Darwin)
        #expect(try UUID(uuid: root.uuid) == rootUUID)
#endif
        #expect(root.description == "root (UID 0)")
        #expect(try root.homeDirectory == FilePath(FileManager.default.homeDirectory(forUser: "root")!.path))
        #expect(try root.homeDirectoryStringPath == FileManager.default.homeDirectory(forUser: "root")!.path)

        #expect(try User(name: "fhqwhgads") == nil)
    }

    @Test
    func testCurrentGroup() throws {
        let group = Group.current

        #expect(group.id == getgid())
        #expect(try group.name == myGroupName)
#if canImport(Darwin)
        #expect(try UUID(uuid: group.uuid) == myGroupUUID)
#endif
        #expect(group.description == "\(myGroupName) (GID \(getgid()))")
    }

    @Test
    func testGroupByID() throws {
        let myGroup = Group(id: getgid())
        let wheel = Group(id: 0)
        let wheelName = String(cString: getgrgid(0).pointee.gr_name!)

        #expect(myGroup.id == getgid())
        #expect(try myGroup.name == myGroupName)
#if canImport(Darwin)
        #expect(try UUID(uuid: myGroup.uuid) == myGroupUUID)
#endif
        #expect(myGroup.description == "\(myGroupName) (GID \(getgid()))")

        #expect(wheel.id == 0)
        #expect(try wheel.name == wheelName)
        #expect(wheel.description == "\(wheelName) (GID 0)")
#if canImport(Darwin)
        #expect(try UUID(uuid: wheel.uuid) == wheelUUID)
#endif
    }

    @Test
    func testGroupByName() throws {
        let myGroup = try #require(try Group(name: myGroupName))
        let wheelName = String(cString: getgrgid(0).pointee.gr_name!)
        let wheel = try #require(try Group(name: wheelName))

        #expect(myGroup.id == getgid())
        #expect(try myGroup.name == myGroupName)
#if canImport(Darwin)
        #expect(try UUID(uuid: myGroup.uuid) == myGroupUUID)
#endif
        #expect(myGroup.description == "\(myGroupName) (GID \(getgid()))")

        #expect(wheel.id == 0)
        #expect(try wheel.name == wheelName)
        #expect(wheel.description == "\(wheelName) (GID 0)")
#if canImport(Darwin)
        #expect(try UUID(uuid: wheel.uuid) == wheelUUID)
#endif

        #expect(try Group(name: "not_a_real_group_name") == nil)
    }

#if canImport(Darwin)
    @Test
    func testLookupByUUID() throws {
        let me = try UserOrGroup(uuid: meUUID.uuid)
        let root = try UserOrGroup(uuid: rootUUID.uuid)
        let myGroup = try UserOrGroup(uuid: myGroupUUID.uuid)
        let wheel = try UserOrGroup(uuid: wheelUUID.uuid)
        let unknownUUID = UUID()

#if Foundation
        #expect(#expect(throws: CocoaError.self) { try UserOrGroup(uuid: unknownUUID.uuid) }?.code == .fileReadNoSuchFile)
#else
        #expect(#expect(throws: Errno.self) { try UserOrGroup(uuid: unknownUUID.uuid) } == .noSuchFileOrDirectory)
#endif
        let unknown = try UserOrGroup(uuid: unknownUUID.uuid, allowUnknown: true)

        #expect(me == UserOrGroup.user(.current))
        #expect(me.description == "\(ProcessInfo.processInfo.userName) (UID \(getuid()))")

        #expect(root == UserOrGroup.user(User(id: 0)))
        #expect(root != UserOrGroup.group(Group(id: 0)))
        #expect(root.description == "root (UID 0)")

        #expect(myGroup == UserOrGroup.group(.current))
        #expect(myGroup.description == "\(myGroupName) (GID \(getgid()))")

        #expect(wheel == UserOrGroup.group(Group(id: 0)))
        #expect(wheel != UserOrGroup.user(User(id: 0)))
        #expect(wheel.description == "wheel (GID 0)")

        #expect(unknown == UserOrGroup.unknown(unknownUUID.uuid))
        #expect(unknown != UserOrGroup.user(.current))
        #expect(unknown != UserOrGroup.group(.current))
        #expect(unknown.description == "unknown: \(unknownUUID.uuidString)")
    }
#endif
}

