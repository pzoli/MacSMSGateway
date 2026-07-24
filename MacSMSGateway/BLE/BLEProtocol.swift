import Foundation

struct BLEProtocol {
    
    // MARK: - Factory Metódusok az Üzenetek Létrehozásához
    
    /// Hívási parancs üzenet hívás indításához (make_call)
    static func makeDialCallMessage(phoneNumber: String, keypass: String? = nil) -> BLEMessage<SendSmsPayload> {
        let payload = SendSmsPayload(phone: phoneNumber, text: "")
        return BLEMessage<SendSmsPayload>(type: .request, action: "make_call", payload: payload, keypass: keypass)
    }

    /// Hívási parancs üzenet fogadáshoz/lerakáshoz (answer_call, hang_up)
    static func makeCallControlMessage(action: CallAction, keypass: String? = nil) -> BLEMessage<EmptyPayload>? {
        switch action {
        case .answer:
            return BLEMessage<EmptyPayload>(type: .request, action: "answer_call", payload: EmptyPayload(), keypass: keypass)
        case .reject, .hangup:
            return BLEMessage<EmptyPayload>(type: .request, action: "hang_up", payload: EmptyPayload(), keypass: keypass)
        case .dial:
            // For dialing, use makeDialCallMessage(phoneNumber:) instead
            return nil
        }
    }

    static func makeSendSmsMessage(to phoneNumber: String, message: String, keypass: String? = nil) -> BLEMessage<SendSmsPayload> {
        let payload = SendSmsPayload(phone: phoneNumber, text: message)
        return BLEMessage(type: .request, action: "send_sms", payload: payload, keypass: keypass)
    }
    
    /// Kontakt szinkronizáció kérése (get_contacts)
    static func makeSyncContactsMessage(keypass: String? = nil) -> BLEMessage<EmptyPayload> {
        return BLEMessage(type: .request, action: "get_contacts", payload: EmptyPayload(), keypass: keypass)
    }

    /// Státusz válasz üzenet
    static func makeStatusMessage(code: Int, message: String) -> BLEMessage<StatusPayload>? {
        let payload = StatusPayload(code: code, message: message)
        return BLEMessage<StatusPayload>(type: .response, action: "status", payload: payload)
    }
}
