import Foundation

struct BLEProtocol {
    
    // MARK: - Factory Metódusok az Üzenetek Létrehozásához
    
    /// Hívási parancs üzenet hívás indításához (make_call)
    static func makeDialCallMessage(phoneNumber: String) -> BLEMessage<SendSmsPayload> {
        let payload = SendSmsPayload(phone: phoneNumber, text: "")
        return BLEMessage<SendSmsPayload>(type: .request, action: "make_call", payload: payload)
    }

    /// Hívási parancs üzenet fogadáshoz/lerakáshoz (answer_call, hang_up)
    static func makeCallControlMessage(action: CallAction) -> BLEMessage<EmptyPayload>? {
        switch action {
        case .answer:
            return BLEMessage<EmptyPayload>(type: .request, action: "answer_call", payload: EmptyPayload())
        case .reject, .hangup:
            return BLEMessage<EmptyPayload>(type: .request, action: "hang_up", payload: EmptyPayload())
        case .dial:
            // For dialing, use makeDialCallMessage(phoneNumber:) instead
            return nil
        }
    }

    static func makeSendSmsMessage(to phoneNumber: String, message: String) -> BLEMessage<SendSmsPayload> {
            let payload = SendSmsPayload(phone: phoneNumber, text: message)
            return BLEMessage(type: .request, action: "send_sms", payload: payload)
        }
        
        /// Kontakt szinkronizáció kérése (get_contacts)
        static func makeSyncContactsMessage() -> BLEMessage<EmptyPayload> {
            return BLEMessage(type: .request, action: "get_contacts", payload: EmptyPayload())
        }
    
    /// Státusz válasz üzenet
    static func makeStatusMessage(code: Int, message: String) -> BLEMessage<StatusPayload>? {
        let payload = StatusPayload(code: code, message: message)
        return BLEMessage<StatusPayload>(type: .response, action: "status", payload: payload)
    }
}
