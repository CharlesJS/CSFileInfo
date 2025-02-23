import CSErrors
@testable import CSFileInfo
import DataParser
import System
import XCTest

@available(macOS 13.0, *)
final class ACLTests: XCTestCase {
    func testACLs() throws {
        let defaultACL = AccessControlList()
        let fileACL = try AccessControlList(isDirectory: false)
        let dirACL = try AccessControlList(isDirectory: true)

        try testACL(acl: defaultACL)
        try testACL(acl: fileACL)
        try testACL(acl: dirACL)
    }

    private func testACL(acl: AccessControlList) throws {
        XCTAssertTrue(acl.description.starts(with: "!#acl "))

        try self.testACLFlags(acl: acl)
        try self.testACLEntries(acl: acl)
        self.testValidation(acl: acl)
    }

    private func testACLFlags(acl: AccessControlList) throws {
        try self.testACLFlag(acl: acl, flag: ACL_FLAG_DEFER_INHERIT, name: "defer_inherit", keyPath: \.deferInheritance)
        try self.testACLFlag(acl: acl, flag: ACL_FLAG_NO_INHERIT, name: "no_inherit", keyPath: \.noInheritance)
    }

    private func testACLFlag(
        acl originalACL: AccessControlList,
        flag: acl_flag_t,
        name: String,
        keyPath: WritableKeyPath<AccessControlList, Bool>
    ) throws {
        let originalValue = originalACL[keyPath: keyPath]
        var acl = originalACL

        acl[keyPath: keyPath] = false
        XCTAssertFalse(acl.description.contains(name))
        XCTAssertFalse(acl[keyPath: keyPath])
        XCTAssertEqual(originalValue, originalACL[keyPath: keyPath])
        try self.assertACLFlag(acl: originalACL, flag: flag, value: originalValue)
        try self.assertACLFlag(acl: acl, flag: flag, value: false)

        acl[keyPath: keyPath] = true
        XCTAssertTrue(acl.description.contains(name))
        XCTAssertTrue(acl[keyPath: keyPath])
        XCTAssertEqual(originalValue, originalACL[keyPath: keyPath])
        try self.assertACLFlag(acl: originalACL, flag: flag, value: originalValue)
        try self.assertACLFlag(acl: acl, flag: flag, value: true)
    }

    private func assertACLFlag(acl: AccessControlList, flag: acl_flag_t, value: Bool) throws {
        let flagset = try callPOSIXFunction(expect: .zero) {
            acl_get_flagset_np(UnsafeMutableRawPointer(acl.aclForReading), $0)
        }

        XCTAssertEqual(acl_get_flag_np(flagset, flag), value ? 1 : 0)
    }

    private func testACLEntries(acl originalACL: AccessControlList) throws {
        var acl = originalACL
        let originalCount = originalACL.count

        XCTAssertEqual(acl, originalACL)
        XCTAssertEqual(acl.hashValue, originalACL.hashValue)

        var entry = AccessControlList.Entry()
        entry.rule = .allow
        entry.owner = .user(.current)
        entry.permissions = [.readAttributes]
        entry.flags = [.inheritToFiles]

        acl.append(entry)
        XCTAssertNotEqual(acl, originalACL)
        XCTAssertNotEqual(acl.hashValue, originalACL.hashValue)
        XCTAssertEqual(acl.count, originalCount + 1)
        XCTAssertEqual(originalACL.count, originalCount)
        XCTAssertEqual(acl.last?.rule, .allow)
        XCTAssertEqual(acl.last?.owner, .user(User(id: getuid())))
        XCTAssertEqual(acl.last?.permissions, .readAttributes)
        XCTAssertEqual(acl.last?.flags, .inheritToFiles)

        var acl2 = acl
        XCTAssertEqual(acl, acl2)
        XCTAssertEqual(acl.hashValue, acl2.hashValue)
        acl2[originalCount].rule = .deny
        XCTAssertNotEqual(acl, acl2)
        XCTAssertNotEqual(acl.hashValue, acl2.hashValue)
        acl2[originalCount].owner = .group(.current)
        acl2[originalCount].permissions.insert(.readData)
        acl2[originalCount].flags.insert(.inheritToDirectories)
        XCTAssertEqual(acl.last?.rule, .allow)
        XCTAssertEqual(acl.last?.owner, .user(User(id: getuid())))
        XCTAssertEqual(acl.last?.permissions, .readAttributes)
        XCTAssertEqual(acl.last?.flags, .inheritToFiles)
        XCTAssertEqual(acl2.last?.rule, .deny)
        XCTAssertEqual(acl2.last?.owner, .group(Group(id: getgid())))
        XCTAssertEqual(acl2.last?.permissions, [.readAttributes, .readData])
        XCTAssertEqual(acl2.last?.flags, [.inheritToFiles, .inheritToDirectories])

        while(!acl2.isEmpty) {
            let count = acl2.count
            acl2.remove(at: count - 1)
            XCTAssertEqual(acl2.count, count - 1)
            XCTAssertEqual(acl.count, originalCount + 1)
        }
        XCTAssertEqual(acl2.count, 0)
        XCTAssertNil(acl2.first)
        XCTAssertNil(acl2.last)
    }

    private func testValidation(acl: AccessControlList) {
        XCTAssertNoThrow(try acl.validate())
        let aclPointer = UnsafeMutableRawPointer(acl.aclForReading)
        let magic = aclPointer.load(as: UInt32.self)

        // corrupt the underlying ACL so it fails validation
        aclPointer.storeBytes(of: 0, as: UInt32.self)
        XCTAssertThrowsError(try acl.validate()) {
            XCTAssertEqual($0 as? Errno, .invalidArgument)
        }

        XCTAssertTrue(Errno.invalidArgument.localizedDescription.hasSuffix(acl.description))
        XCTAssertFalse(acl.noInheritance)
        XCTAssertFalse(acl.deferInheritance)

        // restore the ACL and make it valid again
        aclPointer.storeBytes(of: magic, as: UInt32.self)
        XCTAssertNoThrow(try acl.validate())
    }

    func testInvalidTagType() {
        var acl = acl_init(1)
        defer { acl_free(UnsafeMutableRawPointer(acl)) }

        var entry: acl_entry_t?
        acl_create_entry(&acl, &entry)

        // tag type is stored at offset 4 in the _acl_entry structure; corrupt this
        let ptr = UnsafeMutableRawPointer(entry)
        ptr?.storeBytes(of: UInt32.max, toByteOffset: 4, as: UInt32.self)

        XCTAssertThrowsError(try AccessControlList.Entry(aclEntry: entry!, isDirectory: false)) {
            XCTAssertEqual($0 as? Errno, .invalidArgument)
        }
    }

    func testDataRepresentation() throws {
        let data = Data([
            0x01, 0x2c, 0xc1, 0x6d, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x01, 0x79, 0xbe, 0xbb, 0x8a,
            0x27, 0xc4, 0x4b, 0xf4, 0xa1, 0x3f, 0xf5, 0x4c, 0xd1, 0x34, 0x39, 0x86, 0x00, 0x00, 0x00, 0x81,
            0x00, 0x00, 0x08, 0x00, 0xab, 0xcd, 0xef, 0xab, 0xcd, 0xef, 0xab, 0xcd, 0xef, 0xab, 0xcd, 0xef,
            0x00, 0x00, 0x00, 0x14, 0x00, 0x00, 0x00, 0x42, 0x00, 0x00, 0x01, 0x00
        ])

        var acl = try AccessControlList(isDirectory: true)
        acl.deferInheritance = true
        acl.noInheritance = false

        var entry1 = AccessControlList.Entry()
        entry1.rule = .allow
        entry1.owner = .user(.current)
        entry1.permissions = .readSecurity
        entry1.flags = .limitInheritance
        acl.append(entry1)

        var entry2 = AccessControlList.Entry()
        entry2.rule = .deny
        entry2.owner = .group(.current)
        entry2.permissions = .writeAttributes
        entry2.flags = .inheritToDirectories
        acl.append(entry2)

        XCTAssertEqual(try Data(acl.dataRepresentation(native: false)), Data(data))
        XCTAssertEqual(try AccessControlList(data: data, nativeRepresentation: false, isDirectory: true), acl)

        let nonContiguousData: DispatchData = data.withUnsafeBytes {
            let bytes = UnsafeRawBufferPointer($0)

            var dispatchData = DispatchData(bytes: UnsafeRawBufferPointer(rebasing: bytes[0..<48]))
            dispatchData.append(UnsafeRawBufferPointer(rebasing: bytes[48...]))

            return dispatchData
        }

        XCTAssertEqual(nonContiguousData.regions.count, 2)
        XCTAssertEqual(try AccessControlList(data: nonContiguousData, nativeRepresentation: false, isDirectory: true), acl)

        let nativeData = try acl.dataRepresentation(native: true)
        XCTAssertEqual(try AccessControlList(data: nativeData, nativeRepresentation: true, isDirectory: true), acl)

        if ByteOrder.host == ByteOrder.little {
            XCTAssertEqual(data, Data(nativeData))
        } else {
            XCTAssertNotEqual(data, Data(nativeData))
        }
    }

    func testReadInvalidDataRepresentation() {
        let data = "not a legit data representation".data(using: .ascii)!

        XCTAssertThrowsError(try AccessControlList(data: data, isDirectory: false)) {
            XCTAssertEqual($0 as? Errno, .invalidArgument)
        }
    }

    func testReadingACLs() throws {
        let tempURL = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { _ = try? FileManager.default.removeItem(at: tempURL) }

        try Data().write(to: tempURL)

        let rawACL = """
        user:\(NSUserName()) deny delete_child,readextattr
        group:staff allow readsecurity,writeextattr,file_inherit
        """
        try self.setRawACL(acl: rawACL, at: tempURL)

        for eachVersion in [11, 13] {
            try emulateOSVersion(eachVersion) {
                let acls = try [
                    AccessControlList(at: FilePath(tempURL.path)),
                    AccessControlList(atPath: String(tempURL.path))
                ]

                for eachACL in acls {
                    try self.testACL(acl: eachACL)
                    XCTAssertEqual(eachACL.count, 2)

                    let entry1 = eachACL[0]
                    let entry2 = eachACL[1]

                    XCTAssertEqual(entry1.owner, .user(.current))
                    XCTAssertEqual(entry1.rule, .deny)
                    XCTAssertEqual(entry1.permissions, [.deleteChild, .readExtendedAttributes])
                    XCTAssertEqual(entry1.flags, [])

                    XCTAssertEqual(entry2.owner, try Group(name: "staff").map { .group($0) })
                    XCTAssertEqual(entry2.rule, .allow)
                    XCTAssertEqual(entry2.permissions, [.readSecurity, .writeExtendedAttributes])
                    XCTAssertEqual(entry2.flags, .inheritToFiles)
                }
            }
        }
    }

    func testWritingACLs() throws {
        let tempURL = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { _ = try? FileManager.default.removeItem(at: tempURL) }

        for eachVersion in [11, 13] {
            try emulateOSVersion(eachVersion) {
                var acl = AccessControlList()
                acl.deferInheritance = true
                acl.noInheritance = false
                
                var entry1 = AccessControlList.Entry()
                entry1.rule = .allow
                entry1.owner = .user(.current)
                entry1.permissions = .readSecurity
                entry1.flags = .limitInheritance
                acl.append(entry1)
                
                var entry2 = AccessControlList.Entry()
                entry2.rule = .deny
                entry2.owner = .group(.current)
                entry2.permissions = .writeAttributes
                entry2.flags = .inheritToDirectories
                acl.append(entry2)
                
                let expectedLines = [
                    " 0: user:\(NSUserName()) allow readsecurity,limit_inherit",
                    " 1: group:\(try Group.current.name ?? "") deny writeattr"
                ]
                
                try Data().write(to: tempURL)
                try acl.apply(to: FilePath(tempURL.path))
                try self.doubleCheckWrittenACL(at: tempURL, expect: expectedLines)
                
                try FileManager.default.removeItem(at: tempURL)
                try Data().write(to: tempURL)
                try acl.apply(toPath: tempURL.path)
                try self.doubleCheckWrittenACL(at: tempURL, expect: expectedLines)
            }
        }
    }

    private func setRawACL(acl: String, at url: URL) throws {
        let process = Process()
        let pipe = Pipe()
        let handle = pipe.fileHandleForWriting

        process.executableURL = URL(filePath: "/bin/chmod")
        process.arguments = ["-E", url.path]
        process.standardInput = pipe

        try process.run()
        try handle.write(contentsOf: acl.data(using: .utf8)!)
        try handle.write(contentsOf: "\n".data(using: .utf8)!)
        try handle.close()

        process.waitUntilExit()
    }

    private func doubleCheckWrittenACL(at url: URL, expect expectedLines: [String]) throws {
        let process = Process()
        let pipe = Pipe()
        let handle = pipe.fileHandleForReading

        process.executableURL = URL(filePath: "/bin/ls")
        process.arguments = ["-led", url.path]
        process.standardOutput = pipe


        try process.run()
        process.waitUntilExit()

        guard let data = try handle.readToEnd(),
              let lines = String(data: data, encoding: .utf8)?.components(separatedBy: .newlines).filter({ !$0.isEmpty }),
              let firstLine = lines.first else {
            XCTFail("Couldn't get /bin/ls output")
            return
        }

        XCTAssertEqual(firstLine.components(separatedBy: .whitespaces).first?.last, "+")
        XCTAssertEqual(Array(lines[1...]), expectedLines)
    }

    func testPermissionDescription() {
        var perms: AccessControlList.Entry.Permissions = []

        XCTAssertEqual(perms.description, "")

        perms.insert(.readData)
        XCTAssertTrue(perms.description.contains("read"))

        perms.insert(.writeData)
        XCTAssertTrue(perms.description.contains("write"))

        perms.insert(.appendData)
        XCTAssertTrue(perms.description.contains("append"))

        perms.insert(.execute)
        XCTAssertTrue(perms.description.contains("execute"))

        perms = .listDirectory
        XCTAssertTrue(perms.description.contains("list"))

        perms.insert(.addFile)
        XCTAssertTrue(perms.description.contains("add_file"))

        perms.insert(.addSubdirectory)
        XCTAssertTrue(perms.description.contains("add_subdirectory"))

        perms.insert(.search)
        XCTAssertTrue(perms.description.contains("search"))

        perms.insert(.deleteChild)
        XCTAssertTrue(perms.description.contains("delete_child"))

        perms = .delete
        XCTAssertEqual(perms.description, "delete")

        perms.insert(.readAttributes)
        XCTAssertEqual(perms.description, "delete, readattr")

        perms.insert(.writeAttributes)
        XCTAssertEqual(perms.description, "delete, readattr, writeattr")

        perms.insert(.readExtendedAttributes)
        XCTAssertEqual(perms.description, "delete, readattr, writeattr, readextattr")

        perms.insert(.writeExtendedAttributes)
        XCTAssertEqual(perms.description, "delete, readattr, writeattr, readextattr, writeextattr")

        perms.insert(.readSecurity)
        XCTAssertEqual(perms.description, "delete, readattr, writeattr, readextattr, writeextattr, readsecurity")

        perms.insert(.writeSecurity)
        XCTAssertEqual(
            perms.description,
            "delete, readattr, writeattr, readextattr, writeextattr, readsecurity, writesecurity"
        )

        perms.insert(.changeOwner)
        XCTAssertEqual(
            perms.description,
            "delete, readattr, writeattr, readextattr, writeextattr, readsecurity, writesecurity, chown"
        )
    }

    func testFlagDescriptions() {
        var flags: AccessControlList.Entry.Flags = []
        XCTAssertEqual(flags.description, "")

        flags.insert(.inheritToFiles)
        XCTAssertEqual(flags.description, "file_inherit")

        flags.insert(.inheritToDirectories)
        XCTAssertEqual(flags.description, "file_inherit, directory_inherit")

        flags.insert(.limitInheritance)
        XCTAssertEqual(flags.description, "file_inherit, directory_inherit, limit_inherit")

        flags.insert(.onlyInherit)
        XCTAssertEqual(flags.description, "file_inherit, directory_inherit, limit_inherit, only_inherit")
    }

    func testEntryDescriptions() throws {
        var entry = AccessControlList.Entry()

        XCTAssertEqual(entry.description, "user:\(NSUserName()) allow")

        entry.rule = .deny
        XCTAssertEqual(entry.description, "user:\(NSUserName()) deny")

        entry.owner = .group(try Group(name: "staff")!)
        XCTAssertEqual(entry.description, "group:staff deny")

        entry.owner = nil
        XCTAssertEqual(entry.description, "(nil):(nil) deny")

        entry.owner = .user(User(id: .max))
        XCTAssertEqual(entry.description, "user:(nil) deny")
    }
}
