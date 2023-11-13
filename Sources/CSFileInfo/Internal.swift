//
//  Internal.swift
//  CSFileInfo
//
//  Created by Charles Srstka on 5/9/17.
//

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

#if DEBUG
private var emulatedVersion: Int = .max

func emulateOSVersion(_ version: Int, closure: () throws -> Void) rethrows {
    emulatedVersion = version
    defer { emulatedVersion = .max }

    try closure()
}

func emulateOSVersionAsync(_ version: Int, closure: () async throws -> Void) async throws {
    emulatedVersion = version
    defer { emulatedVersion = .max }

    try await closure()
}

package func versionCheck(_ version: Int) -> Bool { emulatedVersion >= version }
#else
@inline(__always) package func versionCheck(_: Int) -> Bool { true }
#endif

extension String {
    private static let specialsMacOSRomanToCharacter: [UInt8 : Character] = [
        0x80: "Ä", 0x81: "Å", 0x82: "Ç", 0x83: "É", 0x84: "Ñ", 0x85: "Ö", 0x86: "Ü", 0x87: "á", 0x88: "à", 0x89: "â",
        0x8a: "ä", 0x8b: "ã", 0x8c: "å", 0x8d: "ç", 0x8e: "é", 0x8f: "è", 0x90: "ê", 0x91: "ë", 0x92: "í", 0x93: "ì",
        0x94: "î", 0x95: "ï", 0x96: "ñ", 0x97: "ó", 0x98: "ò", 0x99: "ô", 0x9a: "ö", 0x9b: "õ", 0x9c: "ú", 0x9d: "ù",
        0x9e: "û", 0x9f: "ü", 0xa0: "†", 0xa1: "°", 0xa2: "¢", 0xa3: "£", 0xa4: "§", 0xa5: "•", 0xa6: "¶", 0xa7: "ß",
        0xa8: "®", 0xa9: "©", 0xaa: "™", 0xab: "´", 0xac: "¨", 0xad: "≠", 0xae: "Æ", 0xaf: "Ø", 0xb0: "∞", 0xb1: "±",
        0xb2: "≤", 0xb3: "≥", 0xb4: "¥", 0xb5: "µ", 0xb6: "∂", 0xb7: "∑", 0xb8: "∏", 0xb9: "π", 0xba: "∫", 0xbb: "ª",
        0xbc: "º", 0xbd: "Ω", 0xbe: "æ", 0xbf: "ø", 0xc0: "¿", 0xc1: "¡", 0xc2: "¬", 0xc3: "√", 0xc4: "ƒ", 0xc5: "≈",
        0xc6: "∆", 0xc7: "«", 0xc8: "»", 0xc9: "…", 0xca: " ", 0xcb: "À", 0xcc: "Ã", 0xcd: "Õ", 0xce: "Œ", 0xcf: "œ",
        0xd0: "–", 0xd1: "—", 0xd2: "“", 0xd3: "”", 0xd4: "‘", 0xd5: "’", 0xd6: "÷", 0xd7: "◊", 0xd8: "ÿ", 0xd9: "Ÿ",
        0xda: "⁄", 0xdb: "€", 0xdc: "‹", 0xdd: "›", 0xde: "ﬁ", 0xdf: "ﬂ", 0xe0: "‡", 0xe1: "·", 0xe2: "‚", 0xe3: "„",
        0xe4: "‰", 0xe5: "Â", 0xe6: "Ê", 0xe7: "Á", 0xe8: "Ë", 0xe9: "È", 0xea: "Í", 0xeb: "Î", 0xec: "Ï", 0xed: "Ì",
        0xee: "Ó", 0xef: "Ô", 0xf0: "", 0xf1: "Ò", 0xf2: "Ú", 0xf3: "Û", 0xf4: "Ù", 0xf5: "ı", 0xf6: "ˆ", 0xf7: "˜",
        0xf8: "¯", 0xf9: "˘", 0xfa: "˙", 0xfb: "˚", 0xfc: "¸", 0xfd: "˝", 0xfe: "˛", 0xff: "ˇ"
    ]

    private static let specialsCharacterToMacOSRoman = [Character : UInt8](
        uniqueKeysWithValues: Self.specialsMacOSRomanToCharacter.map { ($0.1, $0.0) }
    )

    private static func convertToMacOSRoman(_ byte: UInt8) -> Character {
        if byte < 0x80 {
            return Character(UnicodeScalar(byte))
        } else {
            return self.specialsMacOSRomanToCharacter[byte]!
        }
    }

    private static func convertFromMacOSRoman(_ character: Character) -> UInt8? {
        if character.unicodeScalars.count == 1, let scalar = character.unicodeScalars.first?.value, scalar < 0x80 {
            return UInt8(scalar)
        } else {
            return self.specialsCharacterToMacOSRoman[character]
        }
    }

    // HFS type codes assumed to be in big-endian format
    internal init(hfsTypeCode: UInt32) {
        var bigInt = hfsTypeCode.bigEndian

        self = withUnsafeBytes(of: &bigInt) {
            String($0[..<($0.firstIndex(of: 0) ?? $0.endIndex)].map { Self.convertToMacOSRoman($0) })
        }
    }

    internal var hfsTypeCode: UInt32? {
        if self.isEmpty { return 0 }

        guard var bytes = self.prefix(4).map({ Self.convertFromMacOSRoman($0) }) as? [UInt8] else { return nil }
        while bytes.count < 4 {
            bytes.append(0x20)
        }

        return bytes.withUnsafeBytes { UInt32(bigEndian: $0.load(as: UInt32.self)) }
    }
}

extension fsid_t: Equatable {
    public static func ==(lhs: fsid_t, rhs: fsid_t) -> Bool {
        return lhs.val.0 == rhs.val.0 && lhs.val.1 == rhs.val.1
    }
}
