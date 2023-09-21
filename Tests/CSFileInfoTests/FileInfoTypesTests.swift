//
//  FileInfoTypesTests.swift
//
//
//  Created by Charles Srstka on 9/12/23.
//

@testable import CSFileInfo
import XCTest

class FileInfoTypesTests: XCTestCase {
    func testObjectTypeInitialization() {
        XCTAssertEqual(FileInfo.ObjectType(VNON.rawValue), .noType)
        XCTAssertEqual(FileInfo.ObjectType(VREG.rawValue), .regular)
        XCTAssertEqual(FileInfo.ObjectType(VDIR.rawValue), .directory)
        XCTAssertEqual(FileInfo.ObjectType(VLNK.rawValue), .symbolicLink)
        XCTAssertEqual(FileInfo.ObjectType(VBLK.rawValue), .blockSpecial)
        XCTAssertEqual(FileInfo.ObjectType(VCHR.rawValue), .characterSpecial)
        XCTAssertEqual(FileInfo.ObjectType(VSOCK.rawValue), .socket)
        XCTAssertEqual(FileInfo.ObjectType(VFIFO.rawValue), .fifo)
        XCTAssertEqual(FileInfo.ObjectType(0x12345678), .unknown(0x12345678))
    }

    func testObjectTagInitialization() {
        XCTAssertEqual(FileInfo.ObjectTag(VT_NON.rawValue), .none)
        XCTAssertEqual(FileInfo.ObjectTag(VT_UFS.rawValue), .ufs)
        XCTAssertEqual(FileInfo.ObjectTag(VT_NFS.rawValue), .nfs)
        XCTAssertEqual(FileInfo.ObjectTag(VT_MFS.rawValue), .mfs)
        XCTAssertEqual(FileInfo.ObjectTag(VT_MSDOSFS.rawValue), .msdosfs)
        XCTAssertEqual(FileInfo.ObjectTag(VT_LFS.rawValue), .lfs)
        XCTAssertEqual(FileInfo.ObjectTag(VT_LOFS.rawValue), .lofs)
        XCTAssertEqual(FileInfo.ObjectTag(VT_FDESC.rawValue), .fdesc)
        XCTAssertEqual(FileInfo.ObjectTag(VT_PORTAL.rawValue), .portal)
        XCTAssertEqual(FileInfo.ObjectTag(VT_NULL.rawValue), .null)
        XCTAssertEqual(FileInfo.ObjectTag(VT_UMAP.rawValue), .umap)
        XCTAssertEqual(FileInfo.ObjectTag(VT_KERNFS.rawValue), .kernfs)
        XCTAssertEqual(FileInfo.ObjectTag(VT_PROCFS.rawValue), .procfs)
        XCTAssertEqual(FileInfo.ObjectTag(VT_AFS.rawValue), .afs)
        XCTAssertEqual(FileInfo.ObjectTag(VT_ISOFS.rawValue), .isofs)
        XCTAssertEqual(FileInfo.ObjectTag(VT_MOCKFS.rawValue), .mockfs)
        XCTAssertEqual(FileInfo.ObjectTag(VT_HFS.rawValue), .hfs)
        XCTAssertEqual(FileInfo.ObjectTag(VT_ZFS.rawValue), .zfs)
        XCTAssertEqual(FileInfo.ObjectTag(VT_DEVFS.rawValue), .devfs)
        XCTAssertEqual(FileInfo.ObjectTag(VT_WEBDAV.rawValue), .webdav)
        XCTAssertEqual(FileInfo.ObjectTag(VT_UDF.rawValue), .udf)
        XCTAssertEqual(FileInfo.ObjectTag(VT_AFP.rawValue), .afp)
        XCTAssertEqual(FileInfo.ObjectTag(VT_CDDA.rawValue), .cdda)
        XCTAssertEqual(FileInfo.ObjectTag(VT_CIFS.rawValue), .cifs)
        XCTAssertEqual(FileInfo.ObjectTag(VT_OTHER.rawValue), .other)
        XCTAssertEqual(FileInfo.ObjectTag(VT_APFS.rawValue), .apfs)
        XCTAssertEqual(FileInfo.ObjectTag(VT_LOCKERFS.rawValue), .lockerfs)
        XCTAssertEqual(FileInfo.ObjectTag(VT_BINDFS.rawValue), .bindfs)
        XCTAssertEqual(FileInfo.ObjectTag(0x12345678), .unknown(0x12345678))
    }
}
