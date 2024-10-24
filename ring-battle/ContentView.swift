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
    @State private var inputText: String = ""

    var body: some View {
        VStack {
            Text("NFC Ring Reader/Writer")
                .font(.largeTitle)
                .padding()

            Text(nfcMessage)
                .padding()

            Button(action: {
                nfcReader.scanNFC { result in
                    switch result {
                    case .success(let message):
                        nfcMessage = "Read from NFC: \(message)"
                    case .failure(let error):
                        handleNFCError(error)
                    }
                }
            }) {
                Text("Scan NFC Ring")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            TextField("Enter text to write", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                nfcReader.writeToNFC(inputText) { result in
                    switch result {
                    case .success:
                        nfcMessage = "Successfully wrote to NFC tag"
                    case .failure(let error):
                        handleNFCError(error)
                    }
                }
            }) {
                Text("Write to NFC Ring")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }

    private func handleNFCError(_ error: Error) {
        if let nfcError = error as? NFCReaderError {
            switch nfcError.code {
            case .readerSessionInvalidationErrorSystemIsBusy:
                nfcMessage = "NFC is busy. Please try again in a moment."
            default:
                nfcMessage = "Error: \(nfcError.localizedDescription)"
            }
        } else if (error as NSError).domain == "NFCError" && (error as NSError).code == 203 {
            nfcMessage = "NFC is not available. Please check your device settings."
        } else {
            nfcMessage = "Error: \(error.localizedDescription)"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
