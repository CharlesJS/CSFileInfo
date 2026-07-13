//
//  FinderInfoTests.swift
//  
//
//  Created by Charles Srstka on 4/1/23.
//

@testable import CSFileInfo
import DataParser
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@Suite
struct FinderInfoTests {
    @Test
    func testRectSerialization() throws {
        let rect = FileInfo.FinderInfo.Rect(top: 0x1234, left: 0x5678, bottom: 0x2345, right: 0x6789)
        let data = rect.data

        #expect(Data(data) == Data([0x12, 0x34, 0x56, 0x78, 0x23, 0x45, 0x67, 0x89]))

        var parser = DataParser(data)
        #expect(try FileInfo.FinderInfo.Rect(parser: &parser) == rect)
    }

    @Test
    func testPointSerialization() throws {
        let point = FileInfo.FinderInfo.Point(v: 0x1234, h: 0x5678)
        let data = point.data

        #expect(Data(data) == Data([0x12, 0x34, 0x56, 0x78]))

        var parser = DataParser(data)
        #expect(try FileInfo.FinderInfo.Point(parser: &parser) == point)
    }

    @Test
    func testLabelColor() {
        #expect(FileInfo.FinderInfo.FinderFlags(rawValue: 0xfff1).labelColor == .none)
        #expect(FileInfo.FinderInfo.FinderFlags(rawValue: 0xfff3).labelColor == .grey)
        #expect(FileInfo.FinderInfo.FinderFlags(rawValue: 0xfff5).labelColor == .green)
        #expect(FileInfo.FinderInfo.FinderFlags(rawValue: 0xfff7).labelColor == .purple)
        #expect(FileInfo.FinderInfo.FinderFlags(rawValue: 0xfff9).labelColor == .blue)
        #expect(FileInfo.FinderInfo.FinderFlags(rawValue: 0xfffb).labelColor == .yellow)
        #expect(FileInfo.FinderInfo.FinderFlags(rawValue: 0xfffd).labelColor == .red)
        #expect(FileInfo.FinderInfo.FinderFlags(rawValue: 0xffff).labelColor == .orange)
        #expect(FileInfo.FinderInfo.FinderFlags(rawValue: 0x0000).labelColor == .none)
        #expect(FileInfo.FinderInfo.FinderFlags(rawValue: 0x0002).labelColor == .grey)
        #expect(FileInfo.FinderInfo.FinderFlags(rawValue: 0x0004).labelColor == .green)
        #expect(FileInfo.FinderInfo.FinderFlags(rawValue: 0x0006).labelColor == .purple)
        #expect(FileInfo.FinderInfo.FinderFlags(rawValue: 0x0008).labelColor == .blue)
        #expect(FileInfo.FinderInfo.FinderFlags(rawValue: 0x000a).labelColor == .yellow)
        #expect(FileInfo.FinderInfo.FinderFlags(rawValue: 0x000c).labelColor == .red)
        #expect(FileInfo.FinderInfo.FinderFlags(rawValue: 0x000e).labelColor == .orange)

        var info = FileInfo.FinderInfo.FinderFlags(rawValue: 0xffff)

        info.labelColor = .none
        #expect(info.rawValue == 0xfff1)

        info.labelColor = .grey
        #expect(info.rawValue == 0xfff3)

        info.labelColor = .green
        #expect(info.rawValue == 0xfff5)

        info.labelColor = .purple
        #expect(info.rawValue == 0xfff7)

        info.labelColor = .blue
        #expect(info.rawValue == 0xfff9)

        info.labelColor = .yellow
        #expect(info.rawValue == 0xfffb)

        info.labelColor = .red
        #expect(info.rawValue == 0xfffd)

        info.labelColor = .orange
        #expect(info.rawValue == 0xffff)

        info = []
        info.labelColor = .none
        #expect(info.rawValue == 0)

        info.labelColor = .grey
        #expect(info.rawValue == 2)

        info.labelColor = .green
        #expect(info.rawValue == 4)

        info.labelColor = .purple
        #expect(info.rawValue == 6)

        info.labelColor = .blue
        #expect(info.rawValue == 8)

        info.labelColor = .yellow
        #expect(info.rawValue == 10)

        info.labelColor = .red
        #expect(info.rawValue == 12)

        info.labelColor = .orange
        #expect(info.rawValue == 14)
    }

    @Test
    func testFinderFlagsInitialization() {
        #expect(FileInfo.FinderInfo.FinderFlags().rawValue == 0)

        #expect(
            FileInfo.FinderInfo.FinderFlags(
                isOnDesktop: true,
                labelColor: .blue,
                isExtensionHidden: false,
                isShared: true,
                hasNoINITs: true,
                hasBeenInited: false,
                hasCustomIcon: true,
                isStationery: false,
                isNameLocked: false,
                hasBundle: true,
                isInvisible: false,
                isAlias: false
            ).rawValue == 0x24c9
        )

        #expect(
            FileInfo.FinderInfo.FinderFlags(
                isOnDesktop: false,
                labelColor: .yellow,
                isExtensionHidden: true,
                isShared: false,
                hasNoINITs: false,
                hasBeenInited: true,
                hasCustomIcon: false,
                isStationery: true,
                isNameLocked: true,
                hasBundle: false,
                isInvisible: true,
                isAlias: true
            ).rawValue == 0xd91a
        )
    }

    @Test
    func testExtendedFinderFlagsInitialization() {
        #expect(FileInfo.FinderInfo.ExtendedFinderFlags().rawValue == 0)

        #expect(
            FileInfo.FinderInfo.ExtendedFinderFlags(
                extendedFlagsAreInvalid: false, hasCustomBadge: true, isBusy: true, hasRoutingInfo: false
            ).rawValue == 0x0180
        )

        #expect(
            FileInfo.FinderInfo.ExtendedFinderFlags(
                extendedFlagsAreInvalid: true, hasCustomBadge: false, isBusy: false, hasRoutingInfo: true
            ).rawValue == 0x8004
        )
    }

    @Test
    func testRegularFileSerialization() {
        let data = Data([
            0x61, 0x62, 0x63, 0x64, 0x41, 0x42, 0x43, 0x44, 0x12, 0x34, 0x12, 0x34, 0x56, 0x78, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x56, 0x78, 0x00, 0x00, 0xab, 0xcd, 0xef, 0x01
        ])

        let info = FileInfo.FinderInfo(
            isDirectory: false,
            isSymbolicLink: false,
            typeCode: 0x61626364,
            creatorCode: 0x41424344,
            finderFlags: .init(rawValue: 0x1234),
            extendedFinderFlags: .init(rawValue: 0x5678),
            iconLocation: .init(v: 0x1234, h: 0x5678),
            putAwayFolderID: 0xabcdef01
        )

        #expect(!info.directoryStatus.isDirectory)
        #expect(!info.directoryStatus.isMountPoint)
        #expect(info.type == "abcd")
        #expect(info.typeCode == 0x61626364)
        #expect(info.creator == "ABCD")
        #expect(info.creatorCode == 0x41424344)
        #expect(info.finderFlags.rawValue == 0x1234)
        #expect(info.extendedFinderFlags.rawValue == 0x5678)
        #expect(info.iconLocation.v == 0x1234)
        #expect(info.iconLocation.h == 0x5678)
        #expect(info.putAwayFolderID == 0xabcdef01)

        #expect(Data(info.data) == data)

        let parsedInfo = FileInfo.FinderInfo(data: data, objectType: .regular)

        #expect(info == parsedInfo)
        #expect(!parsedInfo.directoryStatus.isDirectory)
        #expect(!parsedInfo.directoryStatus.isMountPoint)
        #expect(parsedInfo.type == "abcd")
        #expect(parsedInfo.typeCode == 0x61626364)
        #expect(parsedInfo.creator == "ABCD")
        #expect(parsedInfo.creatorCode == 0x41424344)
        #expect(parsedInfo.finderFlags.rawValue == 0x1234)
        #expect(parsedInfo.extendedFinderFlags.rawValue == 0x5678)
        #expect(parsedInfo.iconLocation.v == 0x1234)
        #expect(parsedInfo.iconLocation.h == 0x5678)
        #expect(parsedInfo.putAwayFolderID == 0xabcdef01)
    }

    @Test
    func testSymbolicLinkSerialization() {
        let data = Data([
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x12, 0x34, 0x12, 0x34, 0x56, 0x78, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x56, 0x78, 0x00, 0x00, 0xab, 0xcd, 0xef, 0x01
        ])

        let info = FileInfo.FinderInfo(
            isDirectory: false,
            isSymbolicLink: true,
            typeCode: 0x61626364,
            creatorCode: 0x41424344,
            finderFlags: .init(rawValue: 0x1234),
            extendedFinderFlags: .init(rawValue: 0x5678),
            iconLocation: .init(v: 0x1234, h: 0x5678),
            putAwayFolderID: 0xabcdef01
        )

        #expect(!info.directoryStatus.isDirectory)
        #expect(!info.directoryStatus.isMountPoint)
        #expect(info.type == "slnk")
        #expect(info.typeCode == 0x736c6e6b)
        #expect(info.creator == "rhap")
        #expect(info.creatorCode == 0x72686170)
        #expect(info.finderFlags.rawValue == 0x1234)
        #expect(info.extendedFinderFlags.rawValue == 0x5678)
        #expect(info.iconLocation.v == 0x1234)
        #expect(info.iconLocation.h == 0x5678)
        #expect(info.putAwayFolderID == 0xabcdef01)

        #expect(Data(info.data) == data)

        let parsedInfo = FileInfo.FinderInfo(data: data, objectType: .symbolicLink)

        #expect(info == parsedInfo)
        #expect(!parsedInfo.directoryStatus.isDirectory)
        #expect(!parsedInfo.directoryStatus.isMountPoint)
        #expect(parsedInfo.type == "slnk")
        #expect(parsedInfo.typeCode == 0x736c6e6b)
        #expect(parsedInfo.creator == "rhap")
        #expect(parsedInfo.creatorCode == 0x72686170)
        #expect(parsedInfo.finderFlags.rawValue == 0x1234)
        #expect(parsedInfo.extendedFinderFlags.rawValue == 0x5678)
        #expect(parsedInfo.iconLocation.v == 0x1234)
        #expect(parsedInfo.iconLocation.h == 0x5678)
        #expect(parsedInfo.putAwayFolderID == 0xabcdef01)
    }

    @Test
    func testDirectorySerialization() {
        let data = Data([
            0x01, 0x23, 0x12, 0x34, 0x23, 0x45, 0x34, 0x56, 0x98, 0x76, 0x12, 0x34, 0x56, 0x78, 0x00, 0x00,
            0x65, 0x43, 0x54, 0x32, 0x00, 0x00, 0x00, 0x00, 0x54, 0x32, 0x00, 0x00, 0xfe, 0xdc, 0xba, 0x98
        ])

        let info = FileInfo.FinderInfo(
            isDirectory: true,
            isMountPoint: false,
            finderFlags: .init(rawValue: 0x9876),
            extendedFinderFlags: .init(rawValue: 0x5432),
            iconLocation: .init(v: 0x1234, h: 0x5678),
            windowBounds: .init(top: 0x0123, left: 0x1234, bottom: 0x2345, right: 0x3456),
            scrollPosition: .init(v: 0x6543, h: 0x5432),
            putAwayFolderID: 0xfedcba98
        )

        #expect(info.directoryStatus.isDirectory)
        #expect(!info.directoryStatus.isMountPoint)
        #expect(info.type == "fold")
        #expect(info.typeCode == 0x666f6c64)
        #expect(info.creator == "MACS")
        #expect(info.creatorCode == 0x4d414353)
        #expect(info.finderFlags.rawValue == 0x9876)
        #expect(info.extendedFinderFlags.rawValue == 0x5432)
        #expect(info.iconLocation == .init(v: 0x1234, h: 0x5678))
        #expect(info.windowBounds == .init(top: 0x0123, left: 0x1234, bottom: 0x2345, right: 0x3456))
        #expect(info.scrollPosition == .init(v: 0x6543, h: 0x5432))
        #expect(info.putAwayFolderID == 0xfedcba98)

        #expect(Data(info.data) == data)

        let parsedInfo = FileInfo.FinderInfo(data: data, objectType: .directory, mountStatus: [])
        #expect(parsedInfo == info)

        #expect(parsedInfo.directoryStatus.isDirectory)
        #expect(!parsedInfo.directoryStatus.isMountPoint)
        #expect(parsedInfo.type == "fold")
        #expect(parsedInfo.typeCode == 0x666f6c64)
        #expect(parsedInfo.creator == "MACS")
        #expect(parsedInfo.creatorCode == 0x4d414353)
        #expect(parsedInfo.finderFlags.rawValue == 0x9876)
        #expect(parsedInfo.extendedFinderFlags.rawValue == 0x5432)
        #expect(parsedInfo.iconLocation == .init(v: 0x1234, h: 0x5678))
        #expect(parsedInfo.windowBounds == .init(top: 0x0123, left: 0x1234, bottom: 0x2345, right: 0x3456))
        #expect(parsedInfo.scrollPosition == .init(v: 0x6543, h: 0x5432))
        #expect(parsedInfo.putAwayFolderID == 0xfedcba98)
    }

    @Test
    func testMountPointSerialization() {
        let data = Data([
            0x01, 0x23, 0x12, 0x34, 0x23, 0x45, 0x34, 0x56, 0x98, 0x76, 0x12, 0x34, 0x56, 0x78, 0x00, 0x00,
            0x65, 0x43, 0x54, 0x32, 0x00, 0x00, 0x00, 0x00, 0x54, 0x32, 0x00, 0x00, 0xfe, 0xdc, 0xba, 0x98
        ])

        let info = FileInfo.FinderInfo(
            isDirectory: true,
            isMountPoint: true,
            finderFlags: .init(rawValue: 0x9876),
            extendedFinderFlags: .init(rawValue: 0x5432),
            iconLocation: .init(v: 0x1234, h: 0x5678),
            windowBounds: .init(top: 0x0123, left: 0x1234, bottom: 0x2345, right: 0x3456),
            scrollPosition: .init(v: 0x6543, h: 0x5432),
            putAwayFolderID: 0xfedcba98
        )

        #expect(info.directoryStatus.isDirectory)
        #expect(info.directoryStatus.isMountPoint)
        #expect(info.type == "disk")
        #expect(info.typeCode == 0x6469736b)
        #expect(info.creator == "MACS")
        #expect(info.creatorCode == 0x4d414353)
        #expect(info.finderFlags.rawValue == 0x9876)
        #expect(info.extendedFinderFlags.rawValue == 0x5432)
        #expect(info.iconLocation == .init(v: 0x1234, h: 0x5678))
        #expect(info.windowBounds == .init(top: 0x0123, left: 0x1234, bottom: 0x2345, right: 0x3456))
        #expect(info.scrollPosition == .init(v: 0x6543, h: 0x5432))
        #expect(info.putAwayFolderID == 0xfedcba98)

        #expect(Data(info.data) == data)

        let parsedInfo = FileInfo.FinderInfo(data: data, objectType: .directory, mountStatus: .isMountPoint)
        #expect(parsedInfo == info)

        #expect(parsedInfo.directoryStatus.isDirectory)
        #expect(parsedInfo.directoryStatus.isMountPoint)
        #expect(parsedInfo.type == "disk")
        #expect(parsedInfo.typeCode == 0x6469736b)
        #expect(parsedInfo.creator == "MACS")
        #expect(parsedInfo.creatorCode == 0x4d414353)
        #expect(parsedInfo.finderFlags.rawValue == 0x9876)
        #expect(parsedInfo.extendedFinderFlags.rawValue == 0x5432)
        #expect(parsedInfo.iconLocation == .init(v: 0x1234, h: 0x5678))
        #expect(parsedInfo.windowBounds == .init(top: 0x0123, left: 0x1234, bottom: 0x2345, right: 0x3456))
        #expect(parsedInfo.scrollPosition == .init(v: 0x6543, h: 0x5432))
        #expect(parsedInfo.putAwayFolderID == 0xfedcba98)
    }

    @Test
    func testPropertySetters() {
        var fileInfo = FileInfo.FinderInfo(objectType: .regular)
        var dirInfo = FileInfo.FinderInfo(objectType: .directory)
        var linkInfo = FileInfo.FinderInfo(objectType: .symbolicLink)

        fileInfo.type = "höla"
        #expect(fileInfo.type == "höla")
        #expect(fileInfo.typeCode == 0x689a6c61)

        fileInfo.type = ""
        #expect(fileInfo.type == "")
        #expect(fileInfo.typeCode == 0)

        fileInfo.typeCode = 0x779b7721
        #expect(fileInfo.type == "wõw!")
        #expect(fileInfo.typeCode == 0x779b7721)

        fileInfo.type = "👎🙅🤦💩" // obviously invalid type code
        #expect(fileInfo.type == "")
        #expect(fileInfo.typeCode == 0)

        fileInfo.creator = "wøøt"
        #expect(fileInfo.creator == "wøøt")
        #expect(fileInfo.creatorCode == 0x77bfbf74)

        fileInfo.creator = ""
        #expect(fileInfo.creator == "")
        #expect(fileInfo.creatorCode == 0)

        fileInfo.creatorCode = 0xf0c6a9aa
        #expect(fileInfo.creator == "∆©™")
        #expect(fileInfo.creatorCode == 0xf0c6a9aa)

        fileInfo.creator = "🥸😜😳😱" // obviously invalid creator code
        #expect(fileInfo.creator == "")
        #expect(fileInfo.creatorCode == 0)

        #expect(dirInfo.type == "fold")
        #expect(dirInfo.creator == "MACS")
        #expect(dirInfo.typeCode == 0x666f6c64)
        #expect(dirInfo.creatorCode == 0x4d414353)
        dirInfo.type = "nope"
        dirInfo.creator = "whif"
        #expect(dirInfo.type == "fold")
        #expect(dirInfo.creator == "MACS")
        #expect(dirInfo.typeCode == 0x666f6c64)
        #expect(dirInfo.creatorCode == 0x4d414353)
        dirInfo.typeCode = 0x12345678
        dirInfo.creatorCode = 0x87654321
        #expect(dirInfo.type == "fold")
        #expect(dirInfo.creator == "MACS")
        #expect(dirInfo.typeCode == 0x666f6c64)
        #expect(dirInfo.creatorCode == 0x4d414353)

        #expect(linkInfo.type == "slnk")
        #expect(linkInfo.creator == "rhap")
        #expect(linkInfo.typeCode == 0x736c6e6b)
        #expect(linkInfo.creatorCode == 0x72686170)
        linkInfo.type = "sory"
        linkInfo.creator = "nada"
        #expect(linkInfo.type == "slnk")
        #expect(linkInfo.creator == "rhap")
        #expect(linkInfo.typeCode == 0x736c6e6b)
        #expect(linkInfo.creatorCode == 0x72686170)
        dirInfo.typeCode = 0x23456789
        dirInfo.creatorCode = 0x98765432
        #expect(linkInfo.type == "slnk")
        #expect(linkInfo.creator == "rhap")
        #expect(linkInfo.typeCode == 0x736c6e6b)
        #expect(linkInfo.creatorCode == 0x72686170)

        fileInfo.windowBounds = .init(top: 0x1234, left: 0x2345, bottom: 0x3456, right: 0x4567)
        fileInfo.scrollPosition = .init(v: 0x1234, h: 0x2345)
        #expect(fileInfo.windowBounds == .zero)
        #expect(fileInfo.scrollPosition == .zero)

        dirInfo.windowBounds = .init(top: 0x4321, left: 0x3210, bottom: 0x210f, right: 0x10fe)
        dirInfo.scrollPosition = .init(v: 0x2345, h: 0x3456)
        #expect(dirInfo.windowBounds == .init(top: 0x4321, left: 0x3210, bottom: 0x210f, right: 0x10fe))
        #expect(dirInfo.scrollPosition == .init(v: 0x2345, h: 0x3456))
    }

    @Test
    func testUpdate() throws {
        let info1 = FileInfo.FinderInfo(data: [
            0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x12, 0x34, 0x12, 0x34, 0x56, 0x78, 0x00, 0x00,
            0x01, 0x02, 0x03, 0x04, 0x00, 0x00, 0x00, 0x00, 0x56, 0x78, 0x00, 0x00, 0xab, 0xcd, 0xef, 0x01
        ], objectType: .regular)

        var info2 = FileInfo.FinderInfo(data: repeatElement(0, count: 32), objectType: .regular)

        #expect(info1 != info2)
        info2.update(from: info1, objectType: .regular, mountStatus: [])
        #expect(info1 == info2)

        info2.update(from: info1, objectType: .directory, mountStatus: [])
        #expect(Data(info1.data) == Data(info2.data))
        #expect(info1 != info2)
        #expect(info1.type == "abcd")
        #expect(info2.type == "fold")
        #expect(info1.creator == "efgh")
        #expect(info2.creator == "MACS")
        #expect(info2.windowBounds == .init(top: 0x6162, left: 0x6364, bottom: 0x6566, right: 0x6768))
        #expect(info2.scrollPosition == .init(v: 0x0102, h: 0x0304))

        var info3 = FileInfo.FinderInfo(data: repeatElement(0, count: 32), objectType: .regular)

        #expect(info1 != info3)
        info3.update(from: info2, objectType: .regular, mountStatus: [])
        #expect(info1 == info3)
    }
}
