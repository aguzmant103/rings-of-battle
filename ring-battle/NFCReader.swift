import Foundation
import CoreNFC

@MainActor
class NFCReader: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    private var nfcSession: NFCNDEFReaderSession?
    private var onCompletion: ((Result<String, Error>) -> Void)?

    func scanNFC(completion: @escaping (Result<String, Error>) -> Void) {
        guard NFCNDEFReaderSession.readingAvailable else {
            completion(.failure(NFCError.notAvailable))
            return
        }

        onCompletion = completion
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        nfcSession?.alertMessage = "Hold your iPhone near the NFC ring."
        nfcSession?.begin()
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        if let nfcError = error as? NFCReaderError {
            switch nfcError.code {
            case .readerSessionInvalidationErrorFirstNDEFTagRead,
                 .readerSessionInvalidationErrorUserCanceled:
                // These are not actual errors, so we can ignore them
                break
            default:
                onCompletion?(.failure(error))
            }
        } else {
            onCompletion?(.failure(error))
        }
        nfcSession = nil
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard let ndefMessage = messages.first,
              let record = ndefMessage.records.first,
              let payload = String(data: record.payload, encoding: .utf8) else {
            onCompletion?(.failure(NFCError.invalidData))
            return
        }

        onCompletion?(.success(payload))
        session.invalidate()
    }
}

enum NFCError: Error {
    case notAvailable
    case invalidData
}
