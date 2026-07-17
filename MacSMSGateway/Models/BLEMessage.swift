//
//  SMSMessage.swift
//  MacSMSGateway
//
//  Created by Papp Zoltán on 2026. 07. 16..
//

import Foundation

enum MessageType: String, Codable {
    case request
    case response
    case event
}

enum Status: String, Codable {
    case ok
    case error
}

struct BLEError: Codable {
    let code: String
    let message: String
}

struct BLEMessage: Codable, Identifiable {

    var uuid = UUID()

    let id: Int?

    let type: MessageType

    let action: String?

    let status: Status?

    let payload: Payload?

    let error: BLEError?

    enum CodingKeys: String, CodingKey {

        case id
        case type
        case action
        case status
        case payload
        case error
    }
}
