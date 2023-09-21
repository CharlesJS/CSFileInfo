//
//  Internal.swift
//  
//
//  Created by Charles Srstka on 3/12/23.
//

import CSDataProtocol_Foundation
import CSErrors_Foundation
import DataParser_Foundation
import Foundation

extension Date {
    internal init(timespec aTimespec: timespec) {
        self = Date(timeIntervalSince1970: TimeInterval(aTimespec.tv_sec) + TimeInterval(aTimespec.tv_nsec) / TimeInterval(NSEC_PER_SEC))
    }

    internal var timespec: timespec {
        var iPart = 0.0
        let fPart = modf(self.timeIntervalSince1970, &iPart)

        return Darwin.timespec(tv_sec: __darwin_time_t(lrint(iPart)), tv_nsec: lrint(fPart * Double(NSEC_PER_SEC)))
    }
}

