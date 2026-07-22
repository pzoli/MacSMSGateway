//
//  Payload.swift
//  MacSMSGateway
//
//  Created by Papp Zoltán on 2026. 07. 17..
//

import Foundation

public protocol Payload: Codable {
    
}

public struct StatusPayload: Codable, Payload {
    public let code: Int
    public let message: String
}

// MARK: - SMS
public struct SendSmsPayload: Codable, Payload {
    public let phone: String
    public let text: String

    public init(phone: String, text: String) {
        self.phone = phone
        self.text = text
    }
}
public struct SmsReceivedPayload: Codable, Payload {
    public var id: UUID = UUID()
    public let from: String
    public let text: String
    enum CodingKeys: String, CodingKey {
        case from
        case text
    }
}

// MARK: - Contacts
public struct Contact: Codable, Identifiable {
    public var id: UUID = UUID()
    public let name: String
    public let numbers:[String]
    enum CodingKeys: String, CodingKey {
            case name
            case numbers
        }
}

public struct ContactListPayload: Codable, Payload {
    public let contacts: [Contact]
}


// MARK: - Calls
public enum CallStatus: String, Codable {
    case ringing = "RINGING"
    case offhook = "OFFHOOK"
    case idle = "IDLE"
}

public enum CallAction: String, Codable {
    case dial = "DIAL"
    case answer = "ANSWER"
    case reject = "REJECT"
    case hangup = "HANGUP"
}

public struct SendCallPayload: Codable, Payload {
    public let action: CallAction
    public let phoneNumber: String?
}

public struct CallStatusPayload: Codable, Payload {
    public let status: CallStatus
    public let phoneNumber: String?
}

public struct EmptyPayload: Codable, Payload {}
