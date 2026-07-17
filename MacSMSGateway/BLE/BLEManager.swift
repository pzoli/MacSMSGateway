//
//  BLEManager.swift
//  MacSMSGateway
//
//  Created by Papp Zoltán on 2026. 07. 16..
//

import Foundation
import CoreBluetooth
internal import Combine


class BLEManager:
NSObject,
ObservableObject {

    private let framer = BLEFramer()
    
    private var central:
    CBCentralManager!


    private var phone:
    CBPeripheral?


    private var command:
    CBCharacteristic?


    private var event:
    CBCharacteristic?



    @Published var status =
    "Nincs kapcsolat"


    @Published var messages:
    [BLEMessage] = []



    override init(){

        super.init()

        central =
        CBCentralManager(
            delegate:self,
            queue:nil
        )
    }



    func connect(){

        print("Connect pressed")

            print("State = \(central.state.rawValue)")

            guard central.state == .poweredOn else {
                status = "Bluetooth nem áll készen"
                return
            }

            status = "Keresés..."
        //*
            central.scanForPeripherals(
                withServices: [BLEUUID.service],
                options: [
                    CBCentralManagerScanOptionAllowDuplicatesKey: false
                ]
            )
        //*/
        /*
        central.scanForPeripherals(
            withServices: nil,
            options: nil
        )
         */
    }



    func sendSMS(
        phone:String,
        text:String
    ){

        guard let command else {
            return
        }
        let message =
            BLEProtocol.sendSMS(

                id: nextId(),

                phone: phone,

                text: text
            )
        
        do {
            let data = try BLECodec.encode(message)
            self.phone?.writeValue(
                data,
                for: command,
                type: .withResponse
            )
        } catch {
            print("Failed to encode BLE message: \(error)")
            status = "Üzenet kódolási hiba"
            return
        }
    }
    
    private var requestId = 0

    private func nextId() -> Int {

        requestId += 1

        return requestId
    }
}

extension BLEManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {

        print("Bluetooth state: \(central.state.rawValue)")

        switch central.state {

        case .poweredOn:
            status = "Bluetooth OK"

        case .poweredOff:
            status = "Bluetooth kikapcsolva"

        case .unauthorized:
            status = "Nincs Bluetooth jogosultság"

        case .unsupported:
            status = "Bluetooth nem támogatott"

        default:
            status = "Bluetooth inicializálás..."
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {

        print("Found: \(peripheral.name ?? "Unknown")")

        phone = peripheral

        phone?.delegate = self

        central.stopScan()

        status = "Csatlakozás..."

        central.connect(peripheral)
    }

    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {

        status = "Kapcsolódva"

        peripheral.discoverServices([
            BLEUUID.service
        ])
    }
}

extension BLEManager: CBPeripheralDelegate {

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {

        guard let service = peripheral.services?.first else {
            return
        }

        peripheral.discoverCharacteristics(
            nil,
            for: service
        )
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {

        for characteristic in service.characteristics ?? [] {

            if characteristic.uuid == BLEUUID.command {
                command = characteristic
            }

            if characteristic.uuid == BLEUUID.event {

                event = characteristic

                peripheral.setNotifyValue(
                    true,
                    for: characteristic
                )
            }
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard let data = characteristic.value else {
                return
            }

            let packets = framer.append(data)

            for packet in packets {

                do {

                    let message =
                        try BLECodec.decode(packet)

                    process(message)

                } catch {

                    print("BLE decode error: \(error)")
                }
            }
    }
    
    private func process(
        _ message: BLEMessage
    ) {

        DispatchQueue.main.async {

            switch message.type {

            case .event:

                switch message.action {

                case "sms_received":

                    self.messages.append(message)

                case "sms_sent":

                    print("SMS elküldve")

                default:

                    print("Unknown event: \(message.action ?? "")")
                }

            case .response:

                switch message.status {

                case .ok:

                    print("OK response")

                case .error:

                    print(message.error?.message ?? "Unknown error")

                case nil:

                    break
                }

            case .request:

                print("Unexpected request from Android")
            }
        }
    }
}
