//
//  BLEUUID.swift
//  MacSMSGateway
//
//  Created by Papp Zoltán on 2026. 07. 16..
//

import Foundation
import CoreBluetooth

struct BLEUUID {

    static let service =
    CBUUID(
        string:
        "7A100000-1234-5678-1234-000000000001"
    )

    static let command =
    CBUUID(
        string:
        "7A100001-1234-5678-1234-000000000001"
    )

    static let event =
    CBUUID(
        string:
        "7A100002-1234-5678-1234-000000000001"
    )
}
