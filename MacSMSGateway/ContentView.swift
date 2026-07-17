//
//  ContentView.swift
//  MacSMSGateway
//
//  Created by Papp Zoltán on 2026. 07. 16..
//

import SwiftUI


struct ContentView:
View {


    @StateObject
    var ble =
    BLEManager()



    @State var phone = ""

    @State var text = ""



    var body: some View {


        VStack(
            spacing:20
        ){


            Text(
                ble.status
            )
            .font(.headline)



            Button(
                "Android keresése"
            ){

                ble.connect()

            }



            Divider()



            TextField(
                "Telefonszám",
                text:$phone
            )



            TextField(
                "Üzenet",
                text:$text
            )



            Button(
                "SMS küldése"
            ){

                ble.sendSMS(
                    phone:phone,
                    text:text
                )

            }



            Divider()


            List(ble.messages, id: \.id) { message in

                VStack(alignment: .leading) {

                    Text(message.payload?.from ?? "")

                    Text(message.payload?.text ?? "")
                }
            }
        }
        .padding()
        .frame(
            width:400,
            height:500
        )
    }
}
