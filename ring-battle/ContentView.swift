//
//  ContentView.swift
//  ring-battle
//
//  Created by Andres Guzman  on 21/10/2024.
//

import SwiftUI
import CoreNFC

struct ContentView: View {
    @StateObject private var nfcReader = NFCReader()
    @State private var nfcMessage: String = "No NFC data"

    var body: some View {
        VStack {
            Text("NFC Ring Reader")
                .font(.largeTitle)
                .padding()

            Text(nfcMessage)
                .padding()

            Button(action: {
                nfcReader.scanNFC { result in
                    switch result {
                    case .success(let message):
                        nfcMessage = message
                    case .failure(let error):
                        nfcMessage = "Error: \(error.localizedDescription)"
                    }
                }
            }) {
                Text("Scan NFC Ring")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
}

#Preview {
    ContentView()
}
