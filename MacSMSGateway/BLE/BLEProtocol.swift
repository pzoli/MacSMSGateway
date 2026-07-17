//
//  BLEProtocol.swift
//  MacSMSGateway
//
//  Created by Papp Zoltán on 2026. 07. 17..
//

import Foundation

class BLEProtocol {

    static func sendSMS(

        id: Int,

        phone: String,

        text: String

    ) -> BLEMessage {

        BLEMessage(

            id: id,

            type: .request,

            action: "send_sms",

            status: nil,

            payload:
                Payload(
                    phone: phone,
                    text: text
                ),

            error: nil
        )
    }

    static func ok(
        id: Int
    ) -> BLEMessage {

        BLEMessage(

            id: id,

            type: .response,

            action: nil,

            status: .ok,

            payload: nil,

            error: nil
        )
    }
}
