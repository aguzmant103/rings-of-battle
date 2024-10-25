import SwiftUI
import CoreNFC
import AVFoundation

struct DuelView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var nfcReader = NFCReader()
    @State private var player1: String = ""
    @State private var player2: String = ""
    @State private var currentPlayer: Int = 1
    @State private var showingResults: Bool = false
    @State private var errorMessage: String = ""
    @State private var showingError: Bool = false
    @State private var isScanning: Bool = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var winner: String = ""

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
                    Text("Winner: \(winner)")
                        .font(.custom("Papyrus", size: 24))
                        .foregroundColor(.yellow)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .padding()
                } else if isScanning {
                    Text("Summoning warrior...")
                        .font(.custom("Papyrus", size: 24))
                        .foregroundColor(.white)
                        .padding()
                        .scaleEffect(1 + 0.1 * sin(Double(Date().timeIntervalSince1970) * 5))
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: Date().timeIntervalSince1970)
                } else {
                    Button(action: {
                        startScan()
                    }) {
                        Text(currentPlayer == 1 ? "Start Battle" : "Summon Player 2")
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
        .onAppear {
            setupAudioPlayer()
        }
    }

    private func startScan() {
        isScanning = true
        playSound()
        let alertMessage = currentPlayer == 1 ? "Player 1, present your warrior's ring" : "Player 2, present your warrior's ring"
        nfcReader.scanNFC(alertMessage: alertMessage) { result in
            isScanning = false
            switch result {
            case .success(let message):
                if currentPlayer == 1 {
                    player1 = message
                    currentPlayer = 2
                } else {
                    player2 = message
                    determineWinner()
                    showingResults = true
                }
                playSound(success: true)
            case .failure(let error):
                handleNFCError(error)
            }
        }
    }

    private func determineWinner() {
        switch (player1, player2) {
        case ("Mage", "Warrior"), ("Warrior", "Archer"), ("Archer", "Mage"):
            winner = "Player 1"
        case ("Warrior", "Mage"), ("Archer", "Warrior"), ("Mage", "Archer"):
            winner = "Player 2"
        case (let p1, let p2) where p1 == p2:
            winner = "It's a draw!"
        default:
            winner = "Invalid match-up"
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

    private func setupAudioPlayer() {
        guard let sound = Bundle.main.path(forResource: "scan_sound", ofType: "mp3") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound))
        } catch {
            print("Could not setup audio player: \(error)")
        }
    }

    private func playSound(success: Bool = false) {
        audioPlayer?.play()
    }
}

struct DuelView_Previews: PreviewProvider {
    static var previews: some View {
        DuelView()
    }
}
