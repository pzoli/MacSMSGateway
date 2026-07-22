//
//  BLECodec.swift
//  MacSMSGateway
//
//  Created by Papp Zoltán on 2026. 07. 17..
//

import Foundation

class BLECodec {

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.withoutEscapingSlashes]
        return e
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    /// Bármilyen T payload-dal rendelkező BLEMessage-et tud enklódolni
    static func encode<T: Encodable>(
        _ message: BLEMessage<T>
    ) throws -> Data {

        var data = try encoder.encode(message)
        data.append(0x0A) // Line Feed (LF) lezáró karakter
        return data
    }

    /// Decode incoming messages into a specific Decodable type
    static func decode<T: Decodable>(
        _ data: Data,
        as type: T.Type
    ) throws -> T {
        try decoder.decode(type, from: data)
    }

    /// Convenience to decode a BLEMessage with raw Data payload
    /// Useful when the inner payload type is not known at compile-time.
    static func decodeMessage(_ data: Data) throws -> BLEMessage<Data> {
        try decoder.decode(BLEMessage<Data>.self, from: data)
    }

    /// Strips a single trailing LF (0x0A) if present. Useful before decoding.
    static func stripTrailingLF(_ data: Data) -> Data {
        guard let last = data.last, last == 0x0A else { return data }
        return data.dropLast()
    }
}
