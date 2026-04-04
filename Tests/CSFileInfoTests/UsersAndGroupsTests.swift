//
//  UsersAndGroupsTests.swift
//  
//
//  Created by Charles Srstka on 6/3/23.
//

@testable import CSFileInfo
import Testing

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

    @Test(arguments: [10, 11, 12, 13, .max])
    func testOSVersion(version: Int) throws {
        try emulateOSVersion(version) {
            try self.testCurrentUser()
            try self.testUserByID()
            try self.testUserByName()
            try self.testCurrentGroup()
            try self.testGroupByID()
            try self.testGroupByName()
            try self.testLookupByUUID()
        }
    }

    @Test
    func testCurrentUser() throws {
        let user = User.current

        #expect(user.id == getuid())
        #expect(try user.name == NSUserName())
        #expect(try UUID(uuid: user.uuid) == meUUID)
        #expect(user.description == "\(NSUserName()) (UID \(getuid()))")
        #expect(try user.homeDirectory == FilePath(NSHomeDirectory()))
        #expect(try user.homeDirectoryStringPath == NSHomeDirectory())
    }

    @Test
    func testUserByID() throws {
        let me = User(id: getuid())
        let root = User(id: 0)

        #expect(me.id == getuid())
        #expect(try me.name == NSUserName())
        #expect(try UUID(uuid: me.uuid) == meUUID)
        #expect(me.description == "\(NSUserName()) (UID \(getuid()))")
        #expect(try me.homeDirectory == FilePath(NSHomeDirectory()))
        #expect(try me.homeDirectoryStringPath == NSHomeDirectory())

        #expect(root.id == 0)
        #expect(try root.name == "root")
        #expect(try UUID(uuid: root.uuid) == rootUUID)
        #expect(root.description == "root (UID 0)")
        #expect(try root.homeDirectory == FilePath(NSHomeDirectoryForUser("root")!))
        #expect(try root.homeDirectoryStringPath == NSHomeDirectoryForUser("root"))
    }

    @Test
    func testUserByName() throws {
        let me = try #require(try User(name: NSUserName()))
        let root = try #require(try User(name: "root"))

        #expect(me.id == getuid())
        #expect(try me.name == NSUserName())
        #expect(try UUID(uuid: me.uuid) == meUUID)
        #expect(me.description == "\(NSUserName()) (UID \(getuid()))")
        #expect(try me.homeDirectory == FilePath(NSHomeDirectory()))
        #expect(try me.homeDirectoryStringPath == NSHomeDirectory())

        #expect(root.id == 0)
        #expect(try root.name == "root")
        #expect(try UUID(uuid: root.uuid) == rootUUID)
        #expect(root.description == "root (UID 0)")
        #expect(try root.homeDirectory == FilePath(NSHomeDirectoryForUser("root")!))
        #expect(try root.homeDirectoryStringPath == NSHomeDirectoryForUser("root"))

        #expect(try User(name: "fhqwhgads") == nil)
    }

    @Test
    func testCurrentGroup() throws {
        let group = Group.current

        #expect(group.id == getgid())
        #expect(try group.name == myGroupName)
        #expect(try UUID(uuid: group.uuid) == myGroupUUID)
        #expect(group.description == "\(myGroupName) (GID \(getgid()))")
    }

    @Test
    func testGroupByID() throws {
        let myGroup = Group(id: getgid())
        let wheel = Group(id: 0)

        #expect(myGroup.id == getgid())
        #expect(try myGroup.name == myGroupName)
        #expect(try UUID(uuid: myGroup.uuid) == myGroupUUID)
        #expect(myGroup.description == "\(myGroupName) (GID \(getgid()))")

        #expect(wheel.id == 0)
        #expect(try wheel.name == "wheel")
        #expect(try UUID(uuid: wheel.uuid) == wheelUUID)
        #expect(wheel.description == "wheel (GID 0)")
    }

    @Test
    func testGroupByName() throws {
        let myGroup = try #require(try Group(name: myGroupName))
        let wheel = try #require(try Group(name: "wheel"))

        #expect(myGroup.id == getgid())
        #expect(try myGroup.name == myGroupName)
        #expect(try UUID(uuid: myGroup.uuid) == myGroupUUID)
        #expect(myGroup.description == "\(myGroupName) (GID \(getgid()))")

        #expect(wheel.id == 0)
        #expect(try wheel.name == "wheel")
        #expect(try UUID(uuid: wheel.uuid) == wheelUUID)
        #expect(wheel.description == "wheel (GID 0)")

        #expect(try Group(name: "not_a_real_group_name") == nil)
    }

    @Test
    func testLookupByUUID() throws {
        let me = try UserOrGroup(uuid: meUUID.uuid)
        let root = try UserOrGroup(uuid: rootUUID.uuid)
        let myGroup = try UserOrGroup(uuid: myGroupUUID.uuid)
        let wheel = try UserOrGroup(uuid: wheelUUID.uuid)

        #expect(me == UserOrGroup.user(.current))
        #expect(me.description == "\(NSUserName()) (UID \(getuid()))")

        #expect(root == UserOrGroup.user(User(id: 0)))
        #expect(root.description == "root (UID 0)")

        #expect(myGroup == UserOrGroup.group(.current))
        #expect(myGroup.description == "\(myGroupName) (GID \(getgid()))")

        #expect(wheel == UserOrGroup.group(Group(id: 0)))
        #expect(wheel.description == "wheel (GID 0)")

#if Foundation
        #expect(#expect(throws: CocoaError.self) { try UserOrGroup(uuid: UUID().uuid) }?.code == .fileReadNoSuchFile)
#else
        #expect(#expect(throws: Errno.self) { try UserOrGroup(uuid: UUID().uuid) } == .noSuchFileOrDirectory)
#endif
    }
}
