//
//  BLEFramer.swift
//  MacSMSGateway
//
//  Created by Papp Zoltán on 2026. 07. 17..
//

import Foundation

class BLEFramer {

    private var buffer = Data()

    func append(
        _ data: Data
    ) -> [Data] {

        buffer.append(data)

        var result: [Data] = []

        while let index =
            buffer.firstIndex(of: 0x0A) {

            let packet =
                buffer.prefix(upTo: index)

            result.append(
                Data(packet)
            )

            buffer.removeSubrange(
                ...index
            )
        }

        return result
    }
}
