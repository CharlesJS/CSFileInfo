//
//  FileInfo+Foundation.swift
//
//
//  Created by Charles Srstka on 9/12/23.
//

import CSFileInfo
import Foundation

extension FileInfo {
    public var creationDate: Date? {
        get { self.creationTime.map { Date(timespec: $0) } }
        set { self.creationTime = newValue?.timespec }
    }

    public var modificationDate: Date? {
        get { self.modificationTime.map { Date(timespec: $0) } }
        set { self.modificationTime = newValue?.timespec }
    }

    public var attributeModificationDate: Date? { self.attributeModificationTime.map { Date(timespec: $0) } }

    public var accessDate: Date? {
        get { self.accessTime.map { Date(timespec: $0) } }
        set { self.accessTime = newValue?.timespec }
    }

    public var backupDate: Date? {
        get { self.backupTime.map { Date(timespec: $0) } }
        set { self.backupTime = newValue?.timespec }
    }

    public var addedDate: Date? {
        get { self.addedTime.map { Date(timespec: $0) } }
        set { self.addedTime = newValue?.timespec }
    }
}
