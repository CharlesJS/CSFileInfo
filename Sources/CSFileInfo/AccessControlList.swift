//
//  AccessControlList.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 5/28/12.
//
//  TODO: Currently, this file is #ifdef'ed to use NFSv4 ACLs on Darwin and POSIX ACLs on Linux.
//        This is nonideal; explore whether it would be possible to support both types when working with
//        contexts and/or file systems where they may be supported (example: accessing an NFS share on Linux).
//
//

#if canImport(Darwin) || os(FreeBSD)
public typealias AccessControlList = NFS4AccessControlList
#elseif canImport(Glibc)
public typealias AccessControlList = POSIXAccessControlList
#endif
