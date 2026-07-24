import Foundation
import CoreBluetooth
import Combine

public class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published public var isConnected = false
    @Published public var statusMessage = "Lecsatlakozva"

    private var isUserInitiatedDisconnect = false
    
    // UI Adatmodellek
    @Published public var contacts: [Contact] = []
    @Published public var currentCallStatus: CallStatus = .idle
    @Published public var currentCallNumber: String? = nil
    @Published public var incomingSmsList: [SmsReceivedPayload] = []
    
    @Published public var keypass: String = ""
    
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var rxCharacteristic: CBCharacteristic?
    private var txCharacteristic: CBCharacteristic?
    
    private var framer = BLEFramer()
    
    override public init() {
        self.keypass = ""
        super.init()
        let generated = BLEManager.generateKeypass(length: 40)
        self.keypass = generated
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    public func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        isUserInitiatedDisconnect = false
        statusMessage = "Keresés..."
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    public func disconnect(manually: Bool = true) {
        isUserInitiatedDisconnect = manually
        centralManager.stopScan()
        
        if let peripheral = peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        } else {
            isConnected = false
            statusMessage = "Lecsatlakozva"
        }
        
    }
    
    // MARK: - Parancsküldő Funkciók (Swing-client kompatibilis)
    
    /// Kontaktok letöltésének kérése BLE-n keresztül
    public func requestSyncContacts() {
        do {
            let rawMessage = BLEProtocol.makeSyncContactsMessage(keypass: self.keypass)
            let bleMessage = BLEMessage<EmptyPayload>(type: rawMessage.type,action: rawMessage.action, payload: rawMessage.payload, keypass: rawMessage.keypass)
            let encodedData = try BLECodec.encode(bleMessage)
            send(data: encodedData)
        } catch {
            print("Hiba a csomag kódolása/küldése során: \(error)")
        }
    }

    // SMS küldése
    public func sendSMS(to number: String, body: String) {
        do {
            let rawMessage = BLEProtocol.makeSendSmsMessage(to: number, message: body, keypass: self.keypass)
            let bleMessage = BLEMessage<SendSmsPayload>(type: rawMessage.type, action: rawMessage.action, payload: rawMessage.payload, keypass: rawMessage.keypass)
            let encodedData = try BLECodec.encode(bleMessage)
            send(data: encodedData)
        } catch {
            print("Hiba a csomag kódolása/küldése során: \(error)")
        }
    }

    // Hívás indítása/kezelése
    public func sendCallAction(action: CallAction, phoneNumber: String) {
        do {
            let rawMessage = BLEProtocol.makeDialCallMessage(phoneNumber: phoneNumber, keypass: self.keypass)
            let bleMessage = BLEMessage<SendSmsPayload>(type: rawMessage.type,action: rawMessage.action, payload: rawMessage.payload, keypass: rawMessage.keypass)
            let encodedData = try BLECodec.encode(bleMessage)
            send(data: encodedData)
        } catch {
            print("Hiba a csomag kódolása/küldése során: \(error)")
        }
    }
    
    /// Hívás kezdeményezése
    public func makeCall(to number: String) {
        do {
            let rawMessage = BLEProtocol.makeDialCallMessage(phoneNumber: number, keypass: self.keypass)
            let bleMessage = BLEMessage<SendSmsPayload>(type: rawMessage.type, action: rawMessage.action, payload: rawMessage.payload, keypass: rawMessage.keypass)
            let encodedData = try BLECodec.encode(bleMessage)
            send(data: encodedData)
        } catch {
            print("Hiba a csomag kódolása/küldése során: \(error)")
        }
    }
    
    /// Bejövő hívás fogadása
    public func answerCall() {
        do {
            guard let rawMessage = BLEProtocol.makeCallControlMessage(action: .answer, keypass: self.keypass) else { return }
            let bleMessage = BLEMessage<EmptyPayload>(type: rawMessage.type,action: rawMessage.action, payload: rawMessage.payload, keypass: rawMessage.keypass)
            let encodedData = try BLECodec.encode(bleMessage)
            send(data: encodedData)
        } catch {
            print("Hiba a csomag kódolása/küldése során: \(error)")
        }
    }
    
    /// Hívás elutasítása / Bontása
    public func rejectOrHangupCall() {
        do {
            guard let rawMessage = BLEProtocol.makeCallControlMessage(action: .reject, keypass: self.keypass) else { return }
            let bleMessage = BLEMessage<EmptyPayload>(type: rawMessage.type, action: rawMessage.action, payload: rawMessage.payload, keypass: rawMessage.keypass)
            let encodedData = try BLECodec.encode(bleMessage)
            send(data: encodedData)
        } catch {
            print("Hiba a csomag kódolása/küldése során: \(error)")
        }
    }
    
    
    private func send(data: Data) {
        guard isConnected, let tx = txCharacteristic, let peripheral = peripheral else { return }
        let frames = framer.frame(data)
        let writeType: CBCharacteristicWriteType = tx.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
        for frame in frames {
            peripheral.writeValue(frame, for: tx, type: writeType)
        }
    }
    
    public static func generateKeypass(length: Int) -> String {
        let charset = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        var result = String()
        result.reserveCapacity(length)
        for _ in 0..<length {
            if let random = charset.randomElement() {
                result.append(random)
            }
        }
        return result
    }
    
    // MARK: - CBCentralManagerDelegate
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            //startScanning()
        } else {
            statusMessage = "Bluetooth kikapcsolva"
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Csak a releváns nevű eszközökre csatlakozzunk (pl. Android Gateway, vagy tesztelje név szűrés nélkül)
        if let name = peripheral.name, name.contains("SMS") || name.contains("Gateway") || name.contains("Android") {
            self.peripheral = peripheral
            self.peripheral?.delegate = self
            centralManager.stopScan()
            statusMessage = "Csatlakozás: \(name)..."
            centralManager.connect(peripheral, options: nil)
        } else if peripheral.name != nil {
            // Vagy ha tesztelni szeretné szűrés nélkül az első talált névvel rendelkező eszközre:
            print("Talált eszköz: \(peripheral.name ?? "Névtelen") (\(peripheral.identifier))")
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        statusMessage = "Szolgáltatások feltérképezése..."
        peripheral.discoverServices([BLEUUID.serviceUUID])
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = false
            if self.isUserInitiatedDisconnect {
                self.statusMessage = "Lecsatlakozva"
            } else {
                self.statusMessage = "Lecsatlakozva. Újracsatlakozás..."
                self.startScanning()
            }
        }
    }
    
    // MARK: - CBPeripheralDelegate
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == BLEUUID.serviceUUID {
            peripheral.discoverCharacteristics([BLEUUID.rxUUID, BLEUUID.txUUID], for: service)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == BLEUUID.rxUUID {
                self.rxCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            } else if characteristic.uuid == BLEUUID.txUUID {
                self.txCharacteristic = characteristic
            }
        }
        
        DispatchQueue.main.async {
            self.isConnected = true
            self.statusMessage = "Csatlakoztatva: \(peripheral.name ?? "Ezköz")"
            //self.requestSyncContacts()
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        
        let completedMessages = framer.append(data)
        for messageData in completedMessages {
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: messageData, options: [])
                guard let dict = jsonObject as? [String: Any] else {
                    print("Fallback: nem dictionary az üzenet gyökere")
                    continue
                }
                guard let action = dict["action"] as? String else {
                    print("Fallback: hiányzik az action mező vagy nem String")
                    print("Status: \(dict["status"] ?? "")")
                    print("Error: \(dict["error"] ?? "")")
                    continue
                }
                let type = dict["type"] as? String
                var payloadData = Data()
                if let payloadObject = dict["payload"] {
                    if JSONSerialization.isValidJSONObject(payloadObject) {
                        payloadData = try JSONSerialization.data(withJSONObject: payloadObject, options: [])
                    } else if let payloadString = payloadObject as? String, let data = payloadString.data(using: .utf8) {
                        payloadData = data
                    } else {
                        print("Fallback: payload nem konvertálható Data-vá")
                        continue
                    }
                }
                // Építsünk egy BLEMessage<Data>-t kézzel
                let resolvedType: MessageType = {
                    if let typeStr = type, let mt = MessageType(rawValue: typeStr) {
                        return mt
                    } else {
                        // Ha a type hiányzik vagy ismeretlen, essen vissza egy alapértelmezett értékre
                        return .response
                    }
                }()
                let reconstructed = BLEMessage<Data>(type: resolvedType, action: action, payload: payloadData)
                handleIncomingMessage(reconstructed)
            } catch {
                print("Fallback feldolgozás is hibázott: \(error)")
            }
            
        }
    }
    
    // MARK: - Érkező üzenetek feldolgozása
    private func handleIncomingMessage(_ message: BLEMessage<Data>) {
        let action = message.action
        DispatchQueue.main.async {
            switch action {
            case "contacts_list":
                if let payload = try? JSONDecoder().decode(ContactListPayload.self, from: message.payload) {
                    self.contacts = payload.contacts
                }
                
            case "make_call", "call_status":
                if let payload = try? JSONDecoder().decode(CallStatusPayload.self, from: message.payload) {
                    self.currentCallStatus = payload.status
                    self.currentCallNumber = payload.phoneNumber
                }
                
            case "send_sms", "sms_received":
                if let payload = try? JSONDecoder().decode(SmsReceivedPayload.self, from: message.payload) {
                    self.incomingSmsList.insert(payload, at: 0)
                }
                
            case "STATUS":
                print("Status feedback: \(message.payload)")
                
            case "ERROR":
                print("Error feedback: \(message.payload)")
            case "server_stopping":
                self.disconnect(manually: false)
            default:
                break
            }
        }
    }
}
