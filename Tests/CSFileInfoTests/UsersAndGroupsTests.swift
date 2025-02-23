//
//  UsersAndGroupsTests.swift
//  
//
//  Created by Charles Srstka on 6/3/23.
//

@testable import CSFileInfo
import System
import XCTest

class UsersAndGroupsTests: XCTestCase {
    private let meUID = getuid()
    private let meUUID: UUID = {
        var uuid: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

        withUnsafeMutableBytes(of: &uuid) {
            XCTAssertEqual($0.withMemoryRebound(to: UInt8.self) { mbr_uid_to_uuid(getuid(), $0.baseAddress) }, 0)
        }

        return UUID(uuid: uuid)
    }()

    private let rootUID = 0
    private let rootUUID: UUID = {
        var uuid: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

        withUnsafeMutableBytes(of: &uuid) {
            XCTAssertEqual($0.withMemoryRebound(to: UInt8.self) { mbr_uid_to_uuid(0, $0.baseAddress) }, 0)
        }

        return UUID(uuid: uuid)
    }()

    private let myGroupUID = getgid()
    private let myGroupName = String(cString: getgrgid(getgid())!.pointee.gr_name)
    private let myGroupUUID: UUID = {
        var uuid: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

        withUnsafeMutableBytes(of: &uuid) {
            XCTAssertEqual($0.withMemoryRebound(to: UInt8.self) { mbr_gid_to_uuid(getgid(), $0.baseAddress) }, 0)
        }

        return UUID(uuid: uuid)
    }()

    private let wheelUID = getgid()
    private let wheelUUID: UUID = {
        var uuid: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

        withUnsafeMutableBytes(of: &uuid) {
            XCTAssertEqual($0.withMemoryRebound(to: UInt8.self) { mbr_gid_to_uuid(0, $0.baseAddress) }, 0)
        }

        return UUID(uuid: uuid)
    }()

    func testAll() throws {
        for version in [10, 11, 12, 13] {
            try emulateOSVersion(version) {
                self.testCurrentUser()
                self.testUserByID()
                try self.testUserByName()
                self.testCurrentGroup()
                self.testGroupByID()
                try self.testGroupByName()
                try self.testLookupByUUID()
            }
        }
    }

    func testCurrentUser() {
        let user = User.current

        XCTAssertEqual(user.id, getuid())
        XCTAssertEqual(try user.name, NSUserName())
        XCTAssertEqual(try UUID(uuid: user.uuid), meUUID)
        XCTAssertEqual(user.description, "\(NSUserName()) (UID \(getuid()))")
        XCTAssertEqual(try user.homeDirectory, FilePath(NSHomeDirectory()))
        XCTAssertEqual(try user.homeDirectoryStringPath, NSHomeDirectory())
    }

    func testUserByID() {
        let me = User(id: getuid())
        let root = User(id: 0)

        XCTAssertEqual(me.id, getuid())
        XCTAssertEqual(try me.name, NSUserName())
        XCTAssertEqual(try UUID(uuid: me.uuid), meUUID)
        XCTAssertEqual(me.description, "\(NSUserName()) (UID \(getuid()))")
        XCTAssertEqual(try me.homeDirectory, FilePath(NSHomeDirectory()))
        XCTAssertEqual(try me.homeDirectoryStringPath, NSHomeDirectory())

        XCTAssertEqual(root.id, 0)
        XCTAssertEqual(try root.name, "root")
        XCTAssertEqual(try UUID(uuid: root.uuid), rootUUID)
        XCTAssertEqual(root.description, "root (UID 0)")
        XCTAssertEqual(try root.homeDirectory, FilePath(NSHomeDirectoryForUser("root")!))
        XCTAssertEqual(try root.homeDirectoryStringPath, NSHomeDirectoryForUser("root"))
    }

    func testUserByName() throws {
        let me = try XCTUnwrap(User(name: NSUserName()))
        let root = try XCTUnwrap(User(name: "root"))

        XCTAssertEqual(me.id, getuid())
        XCTAssertEqual(try me.name, NSUserName())
        XCTAssertEqual(try UUID(uuid: me.uuid), meUUID)
        XCTAssertEqual(me.description, "\(NSUserName()) (UID \(getuid()))")
        XCTAssertEqual(try me.homeDirectory, FilePath(NSHomeDirectory()))
        XCTAssertEqual(try me.homeDirectoryStringPath, NSHomeDirectory())

        XCTAssertEqual(root.id, 0)
        XCTAssertEqual(try root.name, "root")
        XCTAssertEqual(try UUID(uuid: root.uuid), rootUUID)
        XCTAssertEqual(root.description, "root (UID 0)")
        XCTAssertEqual(try root.homeDirectory, FilePath(NSHomeDirectoryForUser("root")!))
        XCTAssertEqual(try root.homeDirectoryStringPath, NSHomeDirectoryForUser("root"))

        XCTAssertNil(try User(name: "fhqwhgads"))
    }

    func testCurrentGroup() {
        let group = Group.current

        XCTAssertEqual(group.id, getgid())
        XCTAssertEqual(try group.name, myGroupName)
        XCTAssertEqual(try UUID(uuid: group.uuid), myGroupUUID)
        XCTAssertEqual(group.description, "\(myGroupName) (GID \(getgid()))")
    }

    func testGroupByID() {
        let myGroup = Group(id: getgid())
        let wheel = Group(id: 0)

        XCTAssertEqual(myGroup.id, getgid())
        XCTAssertEqual(try myGroup.name, myGroupName)
        XCTAssertEqual(try UUID(uuid: myGroup.uuid), myGroupUUID)
        XCTAssertEqual(myGroup.description, "\(myGroupName) (GID \(getgid()))")

        XCTAssertEqual(wheel.id, 0)
        XCTAssertEqual(try wheel.name, "wheel")
        XCTAssertEqual(try UUID(uuid: wheel.uuid), wheelUUID)
        XCTAssertEqual(wheel.description, "wheel (GID 0)")
    }

    func testGroupByName() throws {
        let myGroup = try XCTUnwrap(Group(name: myGroupName))
        let wheel = try XCTUnwrap(Group(name: "wheel"))

        XCTAssertEqual(myGroup.id, getgid())
        XCTAssertEqual(try myGroup.name, myGroupName)
        XCTAssertEqual(try UUID(uuid: myGroup.uuid), myGroupUUID)
        XCTAssertEqual(myGroup.description, "\(myGroupName) (GID \(getgid()))")

        XCTAssertEqual(wheel.id, 0)
        XCTAssertEqual(try wheel.name, "wheel")
        XCTAssertEqual(try UUID(uuid: wheel.uuid), wheelUUID)
        XCTAssertEqual(wheel.description, "wheel (GID 0)")

        XCTAssertNil(try Group(name: "not_a_real_group_name"))
    }

    func testLookupByUUID() throws {
        let me = try UserOrGroup(uuid: meUUID.uuid)
        let root = try UserOrGroup(uuid: rootUUID.uuid)
        let myGroup = try UserOrGroup(uuid: myGroupUUID.uuid)
        let wheel = try UserOrGroup(uuid: wheelUUID.uuid)

        XCTAssertEqual(me, UserOrGroup.user(.current))
        XCTAssertEqual(me.description, "\(NSUserName()) (UID \(getuid()))")

        XCTAssertEqual(root, UserOrGroup.user(User(id: 0)))
        XCTAssertEqual(root.description, "root (UID 0)")

        XCTAssertEqual(myGroup, UserOrGroup.group(.current))
        XCTAssertEqual(myGroup.description, "\(myGroupName) (GID \(getgid()))")

        XCTAssertEqual(wheel, UserOrGroup.group(Group(id: 0)))
        XCTAssertEqual(wheel.description, "wheel (GID 0)")

        XCTAssertThrowsError(_ = try UserOrGroup(uuid: UUID().uuid)) {
#if Foundation
            XCTAssertEqual(($0 as? CocoaError)?.code, .fileReadNoSuchFile)
#else
            XCTAssertEqual($0 as? Errno, .noSuchFileOrDirectory)
#endif
        }
    }
}
