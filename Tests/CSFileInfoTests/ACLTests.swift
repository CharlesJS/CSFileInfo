import CSErrors
@testable import CSFileInfo
import DataParser
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
struct ACLTests {
    @Test
    func testACLs() throws {
        let defaultACL = AccessControlList()
        let fileACL = try AccessControlList(isDirectory: false)
        let dirACL = try AccessControlList(isDirectory: true)

        try testACL(acl: defaultACL)
        try testACL(acl: fileACL)
        try testACL(acl: dirACL)
    }

    private func testACL(acl: AccessControlList) throws {
        #expect(acl.description.starts(with: "!#acl "))

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
        #expect(!acl.description.contains(name))
        #expect(!acl[keyPath: keyPath])
        #expect(originalValue == originalACL[keyPath: keyPath])
        try self.assertACLFlag(acl: originalACL, flag: flag, value: originalValue)
        try self.assertACLFlag(acl: acl, flag: flag, value: false)

        acl[keyPath: keyPath] = true
        #expect(acl.description.contains(name))
        #expect(acl[keyPath: keyPath])
        #expect(originalValue == originalACL[keyPath: keyPath])
        try self.assertACLFlag(acl: originalACL, flag: flag, value: originalValue)
        try self.assertACLFlag(acl: acl, flag: flag, value: true)
    }

    private func assertACLFlag(acl: AccessControlList, flag: acl_flag_t, value: Bool) throws {
        let flagset = try callPOSIXFunction(expect: .zero) {
            acl_get_flagset_np(UnsafeMutableRawPointer(acl.aclForReading), $0)
        }

        #expect(acl_get_flag_np(flagset, flag) == (value ? 1 : 0))
    }

    private func testACLEntries(acl originalACL: AccessControlList) throws {
        var acl = originalACL
        let originalCount = originalACL.count

        #expect(acl == originalACL)
        #expect(acl.hashValue == originalACL.hashValue)

        var entry = AccessControlList.Entry()
        entry.rule = .allow
        entry.owner = .user(.current)
        entry.permissions = [.readAttributes]
        entry.flags = [.inheritToFiles]

        acl.append(entry)
        #expect(acl != originalACL)
        #expect(acl.hashValue != originalACL.hashValue)
        #expect(acl.count == originalCount + 1)
        #expect(originalACL.count == originalCount)
        #expect(acl.last?.rule == .allow)
        #expect(acl.last?.owner == .user(User(id: getuid())))
        #expect(acl.last?.permissions == .readAttributes)
        #expect(acl.last?.flags == .inheritToFiles)

        var acl2 = acl
        #expect(acl == acl2)
        #expect(acl.hashValue == acl2.hashValue)
        acl2[originalCount].rule = .deny
        #expect(acl != acl2)
        #expect(acl.hashValue != acl2.hashValue)
        acl2[originalCount].owner = .group(.current)
        acl2[originalCount].permissions.insert(.readData)
        acl2[originalCount].flags.insert(.inheritToDirectories)
        #expect(acl.last?.rule == .allow)
        #expect(acl.last?.owner == .user(User(id: getuid())))
        #expect(acl.last?.permissions == .readAttributes)
        #expect(acl.last?.flags == .inheritToFiles)
        #expect(acl2.last?.rule == .deny)
        #expect(acl2.last?.owner == .group(Group(id: getgid())))
        #expect(acl2.last?.permissions == [.readAttributes, .readData])
        #expect(acl2.last?.flags == [.inheritToFiles, .inheritToDirectories])

        while(!acl2.isEmpty) {
            let count = acl2.count
            acl2.remove(at: count - 1)
            #expect(acl2.count == count - 1)
            #expect(acl.count == originalCount + 1)
        }
        #expect(acl2.count == 0)
        #expect(acl2.first == nil)
        #expect(acl2.last == nil)
    }

    private func testValidation(acl: AccessControlList) {
        #expect(throws: Never.self) { try acl.validate() }
        let aclPointer = UnsafeMutableRawPointer(acl.aclForReading)
        let magic = aclPointer.load(as: UInt32.self)

        // corrupt the underlying ACL so it fails validation
        aclPointer.storeBytes(of: 0, as: UInt32.self)
        #expect(#expect(throws: Errno.self) { try acl.validate() } == .invalidArgument)

        #expect(Errno.invalidArgument.localizedDescription.hasSuffix(acl.description))
        #expect(!acl.noInheritance)
        #expect(!acl.deferInheritance)

        // restore the ACL and make it valid again
        aclPointer.storeBytes(of: magic, as: UInt32.self)
        #expect(throws: Never.self) { try acl.validate() }
    }

    @Test
    func testInvalidTagType() {
        var acl = acl_init(1)
        defer { acl_free(UnsafeMutableRawPointer(acl)) }

        var entry: acl_entry_t?
        acl_create_entry(&acl, &entry)

        // tag type is stored at offset 4 in the _acl_entry structure; corrupt this
        let ptr = UnsafeMutableRawPointer(entry)
        ptr?.storeBytes(of: UInt32.max, toByteOffset: 4, as: UInt32.self)

        #expect(
            #expect(throws: Errno.self) {
                try AccessControlList.Entry(aclEntry: entry!, isDirectory: false)
            } == .invalidArgument
        )
    }

    @Test
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

        #expect(try Data(acl.dataRepresentation(native: false)) == Data(data))
        #expect(try AccessControlList(data: data, nativeRepresentation: false, isDirectory: true) == acl)

        let nonContiguousData: DispatchData = data.withUnsafeBytes {
            let bytes = UnsafeRawBufferPointer($0)

            var dispatchData = DispatchData(bytes: UnsafeRawBufferPointer(rebasing: bytes[0..<48]))
            dispatchData.append(UnsafeRawBufferPointer(rebasing: bytes[48...]))

            return dispatchData
        }

        #expect(nonContiguousData.regions.count == 2)
        #expect(try AccessControlList(data: nonContiguousData, nativeRepresentation: false, isDirectory: true) == acl)

        let nativeData = try acl.dataRepresentation(native: true)
        #expect(try AccessControlList(data: nativeData, nativeRepresentation: true, isDirectory: true) == acl)

        if ByteOrder.host == ByteOrder.little {
            #expect(data == Data(nativeData))
        } else {
            #expect(data != Data(nativeData))
        }
    }

    @Test
    func testReadInvalidDataRepresentation() {
        let data = "not a legit data representation".data(using: .ascii)!

        #expect(#expect(throws: Errno.self) { try AccessControlList(data: data, isDirectory: false) } == .invalidArgument)
    }

    @Test
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
                    #expect(eachACL.count == 2)

                    let entry1 = eachACL[0]
                    let entry2 = eachACL[1]

                    #expect(entry1.owner == .user(.current))
                    #expect(entry1.rule == .deny)
                    #expect(entry1.permissions == [.deleteChild, .readExtendedAttributes])
                    #expect(entry1.flags == [])

                    #expect(try entry2.owner == Group(name: "staff").map { .group($0) })
                    #expect(entry2.rule == .allow)
                    #expect(entry2.permissions == [.readSecurity, .writeExtendedAttributes])
                    #expect(entry2.flags == .inheritToFiles)
                }
            }
        }
    }

    @Test
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
            #expect(Bool(false), "Couldn't get /bin/ls output")
            return
        }

        #expect(firstLine.components(separatedBy: .whitespaces).first?.last == "+")
        #expect(Array(lines[1...]) == expectedLines)
    }

    @Test
    func testPermissionDescription() {
        var perms: AccessControlList.Entry.Permissions = []

        #expect(perms.description == "")

        perms.insert(.readData)
        #expect(perms.description.contains("read"))

        perms.insert(.writeData)
        #expect(perms.description.contains("write"))

        perms.insert(.appendData)
        #expect(perms.description.contains("append"))

        perms.insert(.execute)
        #expect(perms.description.contains("execute"))

        perms = .listDirectory
        #expect(perms.description.contains("list"))

        perms.insert(.addFile)
        #expect(perms.description.contains("add_file"))

        perms.insert(.addSubdirectory)
        #expect(perms.description.contains("add_subdirectory"))

        perms.insert(.search)
        #expect(perms.description.contains("search"))

        perms.insert(.deleteChild)
        #expect(perms.description.contains("delete_child"))

        perms = .delete
        #expect(perms.description == "delete")

        perms.insert(.readAttributes)
        #expect(perms.description == "delete, readattr")

        perms.insert(.writeAttributes)
        #expect(perms.description == "delete, readattr, writeattr")

        perms.insert(.readExtendedAttributes)
        #expect(perms.description == "delete, readattr, writeattr, readextattr")

        perms.insert(.writeExtendedAttributes)
        #expect(perms.description == "delete, readattr, writeattr, readextattr, writeextattr")

        perms.insert(.readSecurity)
        #expect(perms.description == "delete, readattr, writeattr, readextattr, writeextattr, readsecurity")

        perms.insert(.writeSecurity)
        #expect(perms.description == "delete, readattr, writeattr, readextattr, writeextattr, readsecurity, writesecurity")

        perms.insert(.changeOwner)
        #expect(
            perms.description == "delete, readattr, writeattr, readextattr, writeextattr, readsecurity, writesecurity, chown"
        )
    }

    @Test
    func testFlagDescriptions() {
        var flags: AccessControlList.Entry.Flags = []
        #expect(flags.description == "")

        flags.insert(.inheritToFiles)
        #expect(flags.description == "file_inherit")

        flags.insert(.inheritToDirectories)
        #expect(flags.description == "file_inherit, directory_inherit")

        flags.insert(.limitInheritance)
        #expect(flags.description == "file_inherit, directory_inherit, limit_inherit")

        flags.insert(.onlyInherit)
        #expect(flags.description == "file_inherit, directory_inherit, limit_inherit, only_inherit")
    }

    @Test
    func testEntryDescriptions() throws {
        var entry = AccessControlList.Entry()

        #expect(entry.description == "user:\(NSUserName()) allow")

        entry.rule = .deny
        #expect(entry.description == "user:\(NSUserName()) deny")

        entry.owner = .group(try Group(name: "staff")!)
        #expect(entry.description == "group:staff deny")

        entry.owner = nil
        #expect(entry.description == "(nil):(nil) deny")

        entry.owner = .user(User(id: .max))
        #expect(entry.description == "user:(nil) deny")
    }
}
