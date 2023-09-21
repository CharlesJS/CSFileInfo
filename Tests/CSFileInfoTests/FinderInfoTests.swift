//
//  FinderInfoTests.swift
//  
//
//  Created by Charles Srstka on 4/1/23.
//

@testable import CSFileInfo
import DataParser
import XCTest

class FinderInfoTests: XCTestCase {
    func testRectSerialization() {
        let rect = FileInfo.FinderInfo.Rect(top: 0x1234, left: 0x5678, bottom: 0x2345, right: 0x6789)
        let data = rect.data

        XCTAssertEqual(Data(data), Data([0x12, 0x34, 0x56, 0x78, 0x23, 0x45, 0x67, 0x89]))

        var parser = DataParser(data)
        XCTAssertEqual(try FileInfo.FinderInfo.Rect(parser: &parser), rect)
    }

    func testPointSerialization() {
        let point = FileInfo.FinderInfo.Point(v: 0x1234, h: 0x5678)
        let data = point.data

        XCTAssertEqual(Data(data), Data([0x12, 0x34, 0x56, 0x78]))

        var parser = DataParser(data)
        XCTAssertEqual(try FileInfo.FinderInfo.Point(parser: &parser), point)
    }

    func testLabelColor() {
        XCTAssertEqual(FileInfo.FinderInfo.FinderFlags(rawValue: 0xfff1).labelColor, .none)
        XCTAssertEqual(FileInfo.FinderInfo.FinderFlags(rawValue: 0xfff3).labelColor, .grey)
        XCTAssertEqual(FileInfo.FinderInfo.FinderFlags(rawValue: 0xfff5).labelColor, .green)
        XCTAssertEqual(FileInfo.FinderInfo.FinderFlags(rawValue: 0xfff7).labelColor, .purple)
        XCTAssertEqual(FileInfo.FinderInfo.FinderFlags(rawValue: 0xfff9).labelColor, .blue)
        XCTAssertEqual(FileInfo.FinderInfo.FinderFlags(rawValue: 0xfffb).labelColor, .yellow)
        XCTAssertEqual(FileInfo.FinderInfo.FinderFlags(rawValue: 0xfffd).labelColor, .red)
        XCTAssertEqual(FileInfo.FinderInfo.FinderFlags(rawValue: 0xffff).labelColor, .orange)
        XCTAssertEqual(FileInfo.FinderInfo.FinderFlags(rawValue: 0x0000).labelColor, .none)
        XCTAssertEqual(FileInfo.FinderInfo.FinderFlags(rawValue: 0x0002).labelColor, .grey)
        XCTAssertEqual(FileInfo.FinderInfo.FinderFlags(rawValue: 0x0004).labelColor, .green)
        XCTAssertEqual(FileInfo.FinderInfo.FinderFlags(rawValue: 0x0006).labelColor, .purple)
        XCTAssertEqual(FileInfo.FinderInfo.FinderFlags(rawValue: 0x0008).labelColor, .blue)
        XCTAssertEqual(FileInfo.FinderInfo.FinderFlags(rawValue: 0x000a).labelColor, .yellow)
        XCTAssertEqual(FileInfo.FinderInfo.FinderFlags(rawValue: 0x000c).labelColor, .red)
        XCTAssertEqual(FileInfo.FinderInfo.FinderFlags(rawValue: 0x000e).labelColor, .orange)

        var info = FileInfo.FinderInfo.FinderFlags(rawValue: 0xffff)

        info.labelColor = .none
        XCTAssertEqual(info.rawValue, 0xfff1)

        info.labelColor = .grey
        XCTAssertEqual(info.rawValue, 0xfff3)

        info.labelColor = .green
        XCTAssertEqual(info.rawValue, 0xfff5)

        info.labelColor = .purple
        XCTAssertEqual(info.rawValue, 0xfff7)

        info.labelColor = .blue
        XCTAssertEqual(info.rawValue, 0xfff9)

        info.labelColor = .yellow
        XCTAssertEqual(info.rawValue, 0xfffb)

        info.labelColor = .red
        XCTAssertEqual(info.rawValue, 0xfffd)

        info.labelColor = .orange
        XCTAssertEqual(info.rawValue, 0xffff)

        info = []
        info.labelColor = .none
        XCTAssertEqual(info.rawValue, 0)

        info.labelColor = .grey
        XCTAssertEqual(info.rawValue, 2)

        info.labelColor = .green
        XCTAssertEqual(info.rawValue, 4)

        info.labelColor = .purple
        XCTAssertEqual(info.rawValue, 6)

        info.labelColor = .blue
        XCTAssertEqual(info.rawValue, 8)

        info.labelColor = .yellow
        XCTAssertEqual(info.rawValue, 10)

        info.labelColor = .red
        XCTAssertEqual(info.rawValue, 12)

        info.labelColor = .orange
        XCTAssertEqual(info.rawValue, 14)
    }

    func testFinderFlagsInitialization() {
        XCTAssertEqual(FileInfo.FinderInfo.FinderFlags().rawValue, 0)

        XCTAssertEqual(
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
            ).rawValue,
            0x24c9
        )

        XCTAssertEqual(
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
            ).rawValue,
            0xd91a
        )
    }

    func testExtendedFinderFlagsInitialization() {
        XCTAssertEqual(FileInfo.FinderInfo.ExtendedFinderFlags().rawValue, 0)

        XCTAssertEqual(
            FileInfo.FinderInfo.ExtendedFinderFlags(
                extendedFlagsAreInvalid: false, hasCustomBadge: true, isBusy: true, hasRoutingInfo: false
            ).rawValue,
            0x0180
        )

        XCTAssertEqual(
            FileInfo.FinderInfo.ExtendedFinderFlags(
                extendedFlagsAreInvalid: true, hasCustomBadge: false, isBusy: false, hasRoutingInfo: true
            ).rawValue,
            0x8004
        )
    }

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

        XCTAssertFalse(info.directoryStatus.isDirectory)
        XCTAssertFalse(info.directoryStatus.isMountPoint)
        XCTAssertEqual(info.type, "abcd")
        XCTAssertEqual(info.typeCode, 0x61626364)
        XCTAssertEqual(info.creator, "ABCD")
        XCTAssertEqual(info.creatorCode, 0x41424344)
        XCTAssertEqual(info.finderFlags.rawValue, 0x1234)
        XCTAssertEqual(info.extendedFinderFlags.rawValue, 0x5678)
        XCTAssertEqual(info.iconLocation.v, 0x1234)
        XCTAssertEqual(info.iconLocation.h, 0x5678)
        XCTAssertEqual(info.putAwayFolderID, 0xabcdef01)

        XCTAssertEqual(Data(info.data), data)

        let parsedInfo = FileInfo.FinderInfo(data: data, objectType: .regular)

        XCTAssertEqual(info, parsedInfo)
        XCTAssertFalse(parsedInfo.directoryStatus.isDirectory)
        XCTAssertFalse(parsedInfo.directoryStatus.isMountPoint)
        XCTAssertEqual(parsedInfo.type, "abcd")
        XCTAssertEqual(parsedInfo.typeCode, 0x61626364)
        XCTAssertEqual(parsedInfo.creator, "ABCD")
        XCTAssertEqual(parsedInfo.creatorCode, 0x41424344)
        XCTAssertEqual(parsedInfo.finderFlags.rawValue, 0x1234)
        XCTAssertEqual(parsedInfo.extendedFinderFlags.rawValue, 0x5678)
        XCTAssertEqual(parsedInfo.iconLocation.v, 0x1234)
        XCTAssertEqual(parsedInfo.iconLocation.h, 0x5678)
        XCTAssertEqual(parsedInfo.putAwayFolderID, 0xabcdef01)
    }

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

        XCTAssertFalse(info.directoryStatus.isDirectory)
        XCTAssertFalse(info.directoryStatus.isMountPoint)
        XCTAssertEqual(info.type, "slnk")
        XCTAssertEqual(info.typeCode, 0x736c6e6b)
        XCTAssertEqual(info.creator, "rhap")
        XCTAssertEqual(info.creatorCode, 0x72686170)
        XCTAssertEqual(info.finderFlags.rawValue, 0x1234)
        XCTAssertEqual(info.extendedFinderFlags.rawValue, 0x5678)
        XCTAssertEqual(info.iconLocation.v, 0x1234)
        XCTAssertEqual(info.iconLocation.h, 0x5678)
        XCTAssertEqual(info.putAwayFolderID, 0xabcdef01)

        XCTAssertEqual(Data(info.data), data)

        let parsedInfo = FileInfo.FinderInfo(data: data, objectType: .symbolicLink)

        XCTAssertEqual(info, parsedInfo)
        XCTAssertFalse(parsedInfo.directoryStatus.isDirectory)
        XCTAssertFalse(parsedInfo.directoryStatus.isMountPoint)
        XCTAssertEqual(parsedInfo.type, "slnk")
        XCTAssertEqual(parsedInfo.typeCode, 0x736c6e6b)
        XCTAssertEqual(parsedInfo.creator, "rhap")
        XCTAssertEqual(parsedInfo.creatorCode, 0x72686170)
        XCTAssertEqual(parsedInfo.finderFlags.rawValue, 0x1234)
        XCTAssertEqual(parsedInfo.extendedFinderFlags.rawValue, 0x5678)
        XCTAssertEqual(parsedInfo.iconLocation.v, 0x1234)
        XCTAssertEqual(parsedInfo.iconLocation.h, 0x5678)
        XCTAssertEqual(parsedInfo.putAwayFolderID, 0xabcdef01)
    }

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

        XCTAssertTrue(info.directoryStatus.isDirectory)
        XCTAssertFalse(info.directoryStatus.isMountPoint)
        XCTAssertEqual(info.type, "fold")
        XCTAssertEqual(info.typeCode, 0x666f6c64)
        XCTAssertEqual(info.creator, "MACS")
        XCTAssertEqual(info.creatorCode, 0x4d414353)
        XCTAssertEqual(info.finderFlags.rawValue, 0x9876)
        XCTAssertEqual(info.extendedFinderFlags.rawValue, 0x5432)
        XCTAssertEqual(info.iconLocation, .init(v: 0x1234, h: 0x5678))
        XCTAssertEqual(info.windowBounds, .init(top: 0x0123, left: 0x1234, bottom: 0x2345, right: 0x3456))
        XCTAssertEqual(info.scrollPosition, .init(v: 0x6543, h: 0x5432))
        XCTAssertEqual(info.putAwayFolderID, 0xfedcba98)

        XCTAssertEqual(Data(info.data), data)

        let parsedInfo = FileInfo.FinderInfo(data: data, objectType: .directory, mountStatus: [])
        XCTAssertEqual(parsedInfo, info)

        XCTAssertTrue(parsedInfo.directoryStatus.isDirectory)
        XCTAssertFalse(parsedInfo.directoryStatus.isMountPoint)
        XCTAssertEqual(parsedInfo.type, "fold")
        XCTAssertEqual(parsedInfo.typeCode, 0x666f6c64)
        XCTAssertEqual(parsedInfo.creator, "MACS")
        XCTAssertEqual(parsedInfo.creatorCode, 0x4d414353)
        XCTAssertEqual(parsedInfo.finderFlags.rawValue, 0x9876)
        XCTAssertEqual(parsedInfo.extendedFinderFlags.rawValue, 0x5432)
        XCTAssertEqual(parsedInfo.iconLocation, .init(v: 0x1234, h: 0x5678))
        XCTAssertEqual(parsedInfo.windowBounds, .init(top: 0x0123, left: 0x1234, bottom: 0x2345, right: 0x3456))
        XCTAssertEqual(parsedInfo.scrollPosition, .init(v: 0x6543, h: 0x5432))
        XCTAssertEqual(parsedInfo.putAwayFolderID, 0xfedcba98)
    }

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

        XCTAssertTrue(info.directoryStatus.isDirectory)
        XCTAssertTrue(info.directoryStatus.isMountPoint)
        XCTAssertEqual(info.type, "disk")
        XCTAssertEqual(info.typeCode, 0x6469736b)
        XCTAssertEqual(info.creator, "MACS")
        XCTAssertEqual(info.creatorCode, 0x4d414353)
        XCTAssertEqual(info.finderFlags.rawValue, 0x9876)
        XCTAssertEqual(info.extendedFinderFlags.rawValue, 0x5432)
        XCTAssertEqual(info.iconLocation, .init(v: 0x1234, h: 0x5678))
        XCTAssertEqual(info.windowBounds, .init(top: 0x0123, left: 0x1234, bottom: 0x2345, right: 0x3456))
        XCTAssertEqual(info.scrollPosition, .init(v: 0x6543, h: 0x5432))
        XCTAssertEqual(info.putAwayFolderID, 0xfedcba98)

        XCTAssertEqual(Data(info.data), data)

        let parsedInfo = FileInfo.FinderInfo(data: data, objectType: .directory, mountStatus: .isMountPoint)
        XCTAssertEqual(parsedInfo, info)

        XCTAssertTrue(parsedInfo.directoryStatus.isDirectory)
        XCTAssertTrue(parsedInfo.directoryStatus.isMountPoint)
        XCTAssertEqual(parsedInfo.type, "disk")
        XCTAssertEqual(parsedInfo.typeCode, 0x6469736b)
        XCTAssertEqual(parsedInfo.creator, "MACS")
        XCTAssertEqual(parsedInfo.creatorCode, 0x4d414353)
        XCTAssertEqual(parsedInfo.finderFlags.rawValue, 0x9876)
        XCTAssertEqual(parsedInfo.extendedFinderFlags.rawValue, 0x5432)
        XCTAssertEqual(parsedInfo.iconLocation, .init(v: 0x1234, h: 0x5678))
        XCTAssertEqual(parsedInfo.windowBounds, .init(top: 0x0123, left: 0x1234, bottom: 0x2345, right: 0x3456))
        XCTAssertEqual(parsedInfo.scrollPosition, .init(v: 0x6543, h: 0x5432))
        XCTAssertEqual(parsedInfo.putAwayFolderID, 0xfedcba98)
    }

    func testPropertySetters() {
        var fileInfo = FileInfo.FinderInfo(objectType: .regular)
        var dirInfo = FileInfo.FinderInfo(objectType: .directory)
        var linkInfo = FileInfo.FinderInfo(objectType: .symbolicLink)

        fileInfo.type = "höla"
        XCTAssertEqual(fileInfo.type, "höla")
        XCTAssertEqual(fileInfo.typeCode, 0x689a6c61)

        fileInfo.type = ""
        XCTAssertEqual(fileInfo.type, "")
        XCTAssertEqual(fileInfo.typeCode, 0)

        fileInfo.typeCode = 0x779b7721
        XCTAssertEqual(fileInfo.type, "wõw!")
        XCTAssertEqual(fileInfo.typeCode, 0x779b7721)

        fileInfo.type = "👎🙅🤦💩" // obviously invalid type code
        XCTAssertEqual(fileInfo.type, "")
        XCTAssertEqual(fileInfo.typeCode, 0)

        fileInfo.creator = "wøøt"
        XCTAssertEqual(fileInfo.creator, "wøøt")
        XCTAssertEqual(fileInfo.creatorCode, 0x77bfbf74)

        fileInfo.creator = ""
        XCTAssertEqual(fileInfo.creator, "")
        XCTAssertEqual(fileInfo.creatorCode, 0)

        fileInfo.creatorCode = 0xf0c6a9aa
        XCTAssertEqual(fileInfo.creator, "∆©™")
        XCTAssertEqual(fileInfo.creatorCode, 0xf0c6a9aa)

        fileInfo.creator = "🥸😜😳😱" // obviously invalid creator code
        XCTAssertEqual(fileInfo.creator, "")
        XCTAssertEqual(fileInfo.creatorCode, 0)

        XCTAssertEqual(dirInfo.type, "fold")
        XCTAssertEqual(dirInfo.creator, "MACS")
        XCTAssertEqual(dirInfo.typeCode, 0x666f6c64)
        XCTAssertEqual(dirInfo.creatorCode, 0x4d414353)
        dirInfo.type = "nope"
        dirInfo.creator = "whif"
        XCTAssertEqual(dirInfo.type, "fold")
        XCTAssertEqual(dirInfo.creator, "MACS")
        XCTAssertEqual(dirInfo.typeCode, 0x666f6c64)
        XCTAssertEqual(dirInfo.creatorCode, 0x4d414353)
        dirInfo.typeCode = 0x12345678
        dirInfo.creatorCode = 0x87654321
        XCTAssertEqual(dirInfo.type, "fold")
        XCTAssertEqual(dirInfo.creator, "MACS")
        XCTAssertEqual(dirInfo.typeCode, 0x666f6c64)
        XCTAssertEqual(dirInfo.creatorCode, 0x4d414353)

        XCTAssertEqual(linkInfo.type, "slnk")
        XCTAssertEqual(linkInfo.creator, "rhap")
        XCTAssertEqual(linkInfo.typeCode, 0x736c6e6b)
        XCTAssertEqual(linkInfo.creatorCode, 0x72686170)
        linkInfo.type = "sory"
        linkInfo.creator = "nada"
        XCTAssertEqual(linkInfo.type, "slnk")
        XCTAssertEqual(linkInfo.creator, "rhap")
        XCTAssertEqual(linkInfo.typeCode, 0x736c6e6b)
        XCTAssertEqual(linkInfo.creatorCode, 0x72686170)
        dirInfo.typeCode = 0x23456789
        dirInfo.creatorCode = 0x98765432
        XCTAssertEqual(linkInfo.type, "slnk")
        XCTAssertEqual(linkInfo.creator, "rhap")
        XCTAssertEqual(linkInfo.typeCode, 0x736c6e6b)
        XCTAssertEqual(linkInfo.creatorCode, 0x72686170)

        fileInfo.windowBounds = .init(top: 0x1234, left: 0x2345, bottom: 0x3456, right: 0x4567)
        fileInfo.scrollPosition = .init(v: 0x1234, h: 0x2345)
        XCTAssertEqual(fileInfo.windowBounds, .zero)
        XCTAssertEqual(fileInfo.scrollPosition, .zero)

        dirInfo.windowBounds = .init(top: 0x4321, left: 0x3210, bottom: 0x210f, right: 0x10fe)
        dirInfo.scrollPosition = .init(v: 0x2345, h: 0x3456)
        XCTAssertEqual(dirInfo.windowBounds, .init(top: 0x4321, left: 0x3210, bottom: 0x210f, right: 0x10fe))
        XCTAssertEqual(dirInfo.scrollPosition, .init(v: 0x2345, h: 0x3456))
    }

    func testUpdate() throws {
        let info1 = FileInfo.FinderInfo(data: [
            0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x12, 0x34, 0x12, 0x34, 0x56, 0x78, 0x00, 0x00,
            0x01, 0x02, 0x03, 0x04, 0x00, 0x00, 0x00, 0x00, 0x56, 0x78, 0x00, 0x00, 0xab, 0xcd, 0xef, 0x01
        ], objectType: .regular)

        var info2 = FileInfo.FinderInfo(data: repeatElement(0, count: 32), objectType: .regular)

        XCTAssertNotEqual(info1, info2)
        info2.update(from: info1, objectType: .regular, mountStatus: [])
        XCTAssertEqual(info1, info2)

        info2.update(from: info1, objectType: .directory, mountStatus: [])
        XCTAssertEqual(Data(info1.data), Data(info2.data))
        XCTAssertNotEqual(info1, info2)
        XCTAssertEqual(info1.type, "abcd")
        XCTAssertEqual(info2.type, "fold")
        XCTAssertEqual(info1.creator, "efgh")
        XCTAssertEqual(info2.creator, "MACS")
        XCTAssertEqual(info2.windowBounds, .init(top: 0x6162, left: 0x6364, bottom: 0x6566, right: 0x6768))
        XCTAssertEqual(info2.scrollPosition, .init(v: 0x0102, h: 0x0304))

        var info3 = FileInfo.FinderInfo(data: repeatElement(0, count: 32), objectType: .regular)

        XCTAssertNotEqual(info1, info3)
        info3.update(from: info2, objectType: .regular, mountStatus: [])
        XCTAssertEqual(info1, info3)
    }
}
