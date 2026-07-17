//
//  BLECodec.swift
//  MacSMSGateway
//
//  Created by Papp Zoltán on 2026. 07. 17..
//

import Foundation

class BLECodec {

    static let encoder = JSONEncoder()

    static let decoder = JSONDecoder()

    static func encode(
        _ message: BLEMessage
    ) throws -> Data {

        var data =
            try encoder.encode(message)

        data.append(0x0A)

        return data
    }

    static func decode(
        _ data: Data
    ) throws -> BLEMessage {

        return try decoder.decode(
            BLEMessage.self,
            from: data
        )
    }
}
