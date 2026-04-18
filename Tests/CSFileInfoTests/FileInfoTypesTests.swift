//
//  FileInfoTypesTests.swift
//
//
//  Created by Charles Srstka on 9/12/23.
//

@testable import CSFileInfo
import Testing

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

@Suite
struct FileInfoTypesTests {
    @Test
    func testObjectTypeInitialization() {
#if canImport(Darwin)
        #expect(FileInfo.ObjectType(VNON.rawValue) == .noType)
        #expect(FileInfo.ObjectType(VREG.rawValue) == .regular)
        #expect(FileInfo.ObjectType(VDIR.rawValue) == .directory)
        #expect(FileInfo.ObjectType(VLNK.rawValue) == .symbolicLink)
        #expect(FileInfo.ObjectType(VBLK.rawValue) == .blockSpecial)
        #expect(FileInfo.ObjectType(VCHR.rawValue) == .characterSpecial)
        #expect(FileInfo.ObjectType(VSOCK.rawValue) == .socket)
        #expect(FileInfo.ObjectType(VFIFO.rawValue) == .fifo)
        #expect(FileInfo.ObjectType(0x12345678) == .unknown(0x12345678))
#else
        #expect(FileInfo.ObjectType(0) == .noType)
        #expect(FileInfo.ObjectType(mode_t(S_IFREG)) == .regular)
        #expect(FileInfo.ObjectType(mode_t(S_IFDIR)) == .directory)
        #expect(FileInfo.ObjectType(mode_t(S_IFLNK)) == .symbolicLink)
        #expect(FileInfo.ObjectType(mode_t(S_IFBLK)) == .blockSpecial)
        #expect(FileInfo.ObjectType(mode_t(S_IFCHR)) == .characterSpecial)
        #expect(FileInfo.ObjectType(mode_t(S_IFSOCK)) == .socket)
        #expect(FileInfo.ObjectType(mode_t(S_IFIFO)) == .fifo)
        #expect(FileInfo.ObjectType(mode_t.max) == .unknown(mode_t(S_IFMT)))
#endif
    }

    @Test
    func testObjectTagInitialization() {
#if canImport(Darwin)
        #expect(FileInfo.ObjectTag(VT_NON.rawValue) == .none)
        #expect(FileInfo.ObjectTag(VT_UFS.rawValue) == .ufs)
        #expect(FileInfo.ObjectTag(VT_NFS.rawValue) == .nfs)
        #expect(FileInfo.ObjectTag(VT_MFS.rawValue) == .mfs)
        #expect(FileInfo.ObjectTag(VT_MSDOSFS.rawValue) == .msdosfs)
        #expect(FileInfo.ObjectTag(VT_LFS.rawValue) == .lfs)
        #expect(FileInfo.ObjectTag(VT_LOFS.rawValue) == .lofs)
        #expect(FileInfo.ObjectTag(VT_FDESC.rawValue) == .fdesc)
        #expect(FileInfo.ObjectTag(VT_PORTAL.rawValue) == .portal)
        #expect(FileInfo.ObjectTag(VT_NULL.rawValue) == .null)
        #expect(FileInfo.ObjectTag(VT_UMAP.rawValue) == .umap)
        #expect(FileInfo.ObjectTag(VT_KERNFS.rawValue) == .kernfs)
        #expect(FileInfo.ObjectTag(VT_PROCFS.rawValue) == .procfs)
        #expect(FileInfo.ObjectTag(VT_AFS.rawValue) == .afs)
        #expect(FileInfo.ObjectTag(VT_ISOFS.rawValue) == .isofs)
        #expect(FileInfo.ObjectTag(VT_MOCKFS.rawValue) == .mockfs)
        #expect(FileInfo.ObjectTag(VT_HFS.rawValue) == .hfs)
        #expect(FileInfo.ObjectTag(VT_ZFS.rawValue) == .zfs)
        #expect(FileInfo.ObjectTag(VT_DEVFS.rawValue) == .devfs)
        #expect(FileInfo.ObjectTag(VT_WEBDAV.rawValue) == .webdav)
        #expect(FileInfo.ObjectTag(VT_UDF.rawValue) == .udf)
        #expect(FileInfo.ObjectTag(VT_AFP.rawValue) == .afp)
        #expect(FileInfo.ObjectTag(VT_CDDA.rawValue) == .cdda)
        #expect(FileInfo.ObjectTag(VT_CIFS.rawValue) == .cifs)
        #expect(FileInfo.ObjectTag(VT_OTHER.rawValue) == .other)
#endif
    }
}
