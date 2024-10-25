import SwiftUI
import CoreNFC

struct DuelView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var nfcReader = NFCReader()
    @State private var player1: String = ""
    @State private var player2: String = ""
    @State private var currentPlayer: Int = 1
    @State private var showingResults: Bool = false
    @State private var errorMessage: String = ""
    @State private var showingError: Bool = false

    var body: some View {
        ZStack {
            // Background Image
            Image("battleground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)
            
            // Semi-transparent overlay to improve text readability
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Duel Mode")
                    .font(.custom("Papyrus", size: 36))
                    .foregroundColor(.white)
                    .padding()

                if showingResults {
                    Text("Player 1: \(player1)")
                        .foregroundColor(.white)
                        .padding()
                    Text("Player 2: \(player2)")
                        .foregroundColor(.white)
                        .padding()
                } else {
                    Button(action: {
                        startScan()
                    }) {
                        Text(currentPlayer == 1 ? "Start" : "Scan Player 2")
                    }
                    .buttonStyle(CustomDarkFantasyButtonStyle())
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: CustomBackButton(action: { presentationMode.wrappedValue.dismiss() }))
        .navigationBarTitle("", displayMode: .inline)
        .alert(isPresented: $showingError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func startScan() {
        let alertMessage = currentPlayer == 1 ? "Player 1, present your warrior" : "Player 2, present your warrior"
        nfcReader.scanNFC(alertMessage: alertMessage) { result in
            switch result {
            case .success(let message):
                if currentPlayer == 1 {
                    player1 = message
                    currentPlayer = 2
                } else {
                    player2 = message
                    showingResults = true
                }
            case .failure(let error):
                handleNFCError(error)
            }
        }
    }

    private func handleNFCError(_ error: Error) {
        if let nfcError = error as? NFCReaderError {
            switch nfcError.code {
            case .readerSessionInvalidationErrorSystemIsBusy:
                errorMessage = "NFC is busy. Please try again in a moment."
            default:
                errorMessage = "Error: \(nfcError.localizedDescription)"
            }
        } else if (error as NSError).domain == "NFCError" && (error as NSError).code == 203 {
            errorMessage = "NFC is not available. Please check your device settings."
        } else {
            errorMessage = "Error: \(error.localizedDescription)"
        }
        showingError = true
    }
}

struct DuelView_Previews: PreviewProvider {
    static var previews: some View {
        DuelView()
    }
}
