//
//  ContentView.swift
//  MacSMSGateway
//
//  Created by Papp Zoltán on 2026. 07. 16..
//

import SwiftUI

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()
    
    @State private var selectedTab = 3
    @State private var recipientNumber: String = ""
    @State private var smsBody: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Fejléc / Állapot
            HStack {
                Button(bleManager.isConnected ? "Lecsatlakozás" : "Kapcsolódás") {
                        if bleManager.isConnected {
                            bleManager.disconnect()
                            bleManager.isSyncing = false
                        } else {
                            bleManager.startScanning()
                        }
                    }
                    .buttonStyle(.bordered)
                    .padding(.leading, 8)
                Circle()
                    .fill(bleManager.isConnected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(bleManager.statusMessage)
                    .font(.subheadline)
                Spacer()
                if bleManager.isConnected {
                    if bleManager.isSyncing {
                        ProgressView()
                            .controlSize(.small)
                        
                        Text("Szinkronizálás...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Button("Szinkronizálás") {
                            bleManager.requestSyncContacts()
                            selectedTab = 0
                        }
                    }
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()

            // Aktív hívás banner (ha van folyamatban lévő hívás)
            if bleManager.currentCallStatus != .idle {
                HStack {
                    VStack(alignment: .leading) {
                        Text("HÍVÁS: \(bleManager.currentCallStatus.rawValue)")
                            .font(.caption).bold()
                        Text(bleManager.currentCallNumber ?? "Ismeretlen szám")
                            .font(.title3)
                        Text(bleManager.contactName(for: bleManager.currentCallNumber ?? "") ?? "")
                    }
                    Spacer()
                    if bleManager.currentCallStatus == .ringing {
                        Button("Fogadás") {
                            bleManager.answerCall()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                    Button("Elutasítás / Bontás") {
                        bleManager.rejectOrHangupCall()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding()
                .background(Color.orange.opacity(0.2))
            }

            // Tab Nézet
            TabView(selection: $selectedTab) {
                // MARK: Kontaktok Tab
                VStack {
                    List(bleManager.contacts, id: \.id) { contact in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(contact.name).font(.headline)
                                
                                if contact.numbers.isEmpty {
                                    Text("Nincs megadott telefonszám")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    ForEach(contact.numbers, id: \.self) { number in
                                        HStack {
                                            Image(systemName: "phone")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text(number)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                            Spacer()
                                            Button(action: {
                                                recipientNumber = number
                                                bleManager.makeCall(to: number)
                                            }) {
                                                Image(systemName: "phone.fill")
                                            }
                                            Button(action: {
                                                recipientNumber = number
                                                selectedTab = 1
                                            }) {
                                                Image(systemName: "message.fill")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .tabItem {
                    Label("Kontaktok", systemImage: "person.crop.circle")
                }
                .tag(0)

                // MARK: SMS Küldés Tab
                VStack(spacing: 15) {
                    TextField("Címzett telefonszáma", text: $recipientNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextEditor(text: $smsBody)
                        .border(Color.gray.opacity(0.3))
                        .frame(maxHeight: .infinity)
                    
                    HStack {
                        Spacer()
                        Button("SMS Küldése") {
                            bleManager.sendSMS(to: recipientNumber, body: smsBody)
                            smsBody = ""
                        }
                        .disabled(!bleManager.isConnected || recipientNumber.isEmpty || smsBody.isEmpty)
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .tabItem {
                    Label("SMS Küldés", systemImage: "paperplane")
                }
                .tag(1)

                // MARK: Bejövő SMS-ek Tab
                VStack {
                    List(bleManager.incomingSmsList, id: \.id) { sms in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(sms.from).bold()
                                Text(sms.name ?? "").bold()
                                Spacer()
                                Text(Date(), style: .time)
                                    .font(.caption).foregroundColor(.gray)
                            }
                            Text(sms.text)
                        }
                    }
                }
                .tabItem {
                    Label("Bejövő SMS", systemImage: "tray")
                }
                .tag(2)

                // MARK: Beállítások (Settings) Tab
                VStack(spacing: 16) {
                    Spacer()
                    
                    Button("Új jelszó generálása") {
                        bleManager.keypass = BLEManager.generateKeypass(length: 40)
                    }
                    .buttonStyle(.borderedProminent)

                    Text("Passkey: \(bleManager.keypass)")
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)

                    QRCodeView(qrText: bleManager.keypass)
                    
                    Spacer()
                }
                .padding()
                .tabItem {
                    Label("Beállítások", systemImage: "gearshape")
                }
                .tag(3)
            }
            .padding(5)
        }
        .frame(minWidth: 500, minHeight: 450)
        .alert("Szinkronizálási hiba", isPresented: $bleManager.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(bleManager.errorMessage ?? "Ismeretlen hiba történt a letöltés során.")
        }
        .alert("Beérkezett SMS", isPresented: $bleManager.isSmsReceived) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("SMS-ed érkezett...")
        }
    }
}
