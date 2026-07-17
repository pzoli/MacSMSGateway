//
//  Payload.swift
//  MacSMSGateway
//
//  Created by Papp Zoltán on 2026. 07. 17..
//

import Foundation

struct Payload: Codable {

    var phone: String?

    var text: String?

    var from: String?

    var battery: Int?

    var network: String?

    var signal: Int?
}
