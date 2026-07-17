//
//  SMSMessage.swift
//  MacSMSGateway
//
//  Created by Papp Zoltán on 2026. 07. 16..
//

import Foundation

struct BLEMessage: Codable {

    let id: Int?
    let type: String
    let action: String?
    let status: String?
    let payload: Payload?
    let error: BLEError?
}

struct Payload: Codable {

    let phone: String?
    let text: String?
    let from: String?
}

struct BLEError: Codable {

    let code: String
    let message: String
}

struct SMSMessage:
    Identifiable {

    let id = UUID()

    var sender:String
    var text:String
}
