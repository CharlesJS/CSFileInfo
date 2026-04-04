//
//  FileInfoDateSupportTests.swift
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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@Suite
struct FileInfoDateSupportTests {
#if Foundation
    @Test
    func testDates() {
        let dateProperties: [(WritableKeyPath<FileInfo, timespec?>, WritableKeyPath<FileInfo, Date?>)] = [
            (\.creationTime, \.creationDate),
            (\.modificationTime, \.modificationDate),
            (\.accessTime, \.accessDate),
            (\.backupTime, \.backupDate),
            (\.addedTime, \.addedDate)
        ]
        
        var info = FileInfo()

        for (timeProperty, dateProperty) in dateProperties {
            #expect(info[keyPath: timeProperty] == nil)
            #expect(info[keyPath: dateProperty] == nil)

            info[keyPath: timeProperty] = timespec(tv_sec: 1694575251, tv_nsec: 500000000)
            #expect((info[keyPath: dateProperty]!.timeIntervalSince1970 - 1694575251.5).magnitude < 0.001)

            info[keyPath: dateProperty] = Date(timeIntervalSince1970: 12345678.9)
            #expect(info[keyPath: timeProperty]?.tv_sec == 12345678)
            #expect((info[keyPath: timeProperty]!.tv_nsec - 900000000).magnitude < 1000)

            info[keyPath: dateProperty] = nil
            #expect(info[keyPath: timeProperty] == nil)
        }

        #expect(info.attributeModificationTime == nil)
        #expect(info.attributeModificationDate == nil)

        info.attributeModificationTime = timespec(tv_sec: 12345678, tv_nsec: 500000000)
        #expect((info.attributeModificationDate!.timeIntervalSince1970 - 12345678.5).magnitude < 0.001)
    }
#endif
}
