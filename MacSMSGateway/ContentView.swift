//
//  ContentView.swift
//  MacSMSGateway
//
//  Created by Papp Zoltán on 2026. 07. 16..
//

import SwiftUI

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()

    // 🎯 Fókusz állapot a saját keresőmezőnkhoz
    @FocusState private var isSearchFocused: Bool
    
    @State private var selectedTab = 3
    @State private var recipientNumber: String = ""
    @State private var smsBody: String = ""
    @State private var searchText = ""

    // 💡 Számított tulajdonság a szűrt kontaktokhoz
    var filteredContacts: [Contact] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return bleManager.contacts
        } else {
            return bleManager.contacts.filter { contact in
                contact.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Fejléc / Állapot
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
                .focusable(false) // Megakadályozza, hogy a billentyűzet véletlenül lenyomja
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

            // MARK: Aktív hívás banner
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

            // MARK: Tab Nézet
            TabView(selection: $selectedTab) {
                // MARK: Kontaktok Tab
                NavigationStack {
                    VStack(spacing: 0) {
                        // 🔍 SAJÁT STABIL KERESŐMEZŐ
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Keresés név alapján...", text: $searchText)
                                .textFieldStyle(.plain)
                                .focused($isSearchFocused) // 👈 Ez a fókusz most már sziklaszilárd!
                            
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .padding([.horizontal, .top], 8)
                        .padding(.bottom, 4)

                        // Kontakt Lista
                        List(filteredContacts, id: \.id) { contact in
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
                        .overlay {
                            if !searchText.isEmpty && filteredContacts.isEmpty {
                                ContentUnavailableView(
                                    "Nincs találat",
                                    systemImage: "person.slash",
                                    description: Text("Nincs \"\(searchText)\" nevű kontakt a listában.")
                                )
                            }
                        }
                    }
                    .navigationTitle("Kontaktok")
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
        
        // ⌨️ TISZTA ÉS MŰKÖDŐ CMD + F KEZELÉS:
        .background(
            Button("SearchShortcut") {
                selectedTab = 0
                // Egy apró késleltetéssel átadjuk a fókuszt a saját TextField-ünknek:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isSearchFocused = true
                }
            }
            .keyboardShortcut("f", modifiers: .command)
            .hidden()
        )
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
