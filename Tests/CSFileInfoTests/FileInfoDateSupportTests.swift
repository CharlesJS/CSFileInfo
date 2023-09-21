//
//  FileInfoDateSupportTests.swift
//
//
//  Created by Charles Srstka on 9/12/23.
//

@testable import CSFileInfo
@testable import CSFileInfo_Foundation
import XCTest

class FileInfoDateSupportTests: XCTestCase {
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
            XCTAssertNil(info[keyPath: timeProperty])
            XCTAssertNil(info[keyPath: dateProperty])

            info[keyPath: timeProperty] = timespec(tv_sec: 1694575251, tv_nsec: 500000000)
            XCTAssertEqual(info[keyPath: dateProperty]!.timeIntervalSince1970, 1694575251.5, accuracy: 0.001)

            info[keyPath: dateProperty] = Date(timeIntervalSince1970: 12345678.9)
            XCTAssertEqual(info[keyPath: timeProperty]?.tv_sec, 12345678)
            XCTAssertLessThan((info[keyPath: timeProperty]!.tv_nsec - 900000000).magnitude, 1000)

            info[keyPath: dateProperty] = nil
            XCTAssertNil(info[keyPath: timeProperty])
        }

        XCTAssertNil(info.attributeModificationTime)
        XCTAssertNil(info.attributeModificationDate)

        info.attributeModificationTime = timespec(tv_sec: 12345678, tv_nsec: 500000000)
        XCTAssertEqual(info.attributeModificationDate!.timeIntervalSince1970, 12345678.5, accuracy: 0.001)
    }
}
