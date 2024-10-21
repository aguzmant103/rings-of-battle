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
        nfcSession?.alertMessage = "Hold your iPhone near the NFC ring to read."
        nfcSession?.begin()
    }

    func writeToNFC(_ message: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard NFCNDEFReaderSession.readingAvailable else {
            completion(.failure(NFCError.notAvailable))
            return
        }

        onCompletion = { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }

        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        nfcSession?.alertMessage = "Hold your iPhone near the NFC ring to write."
        nfcSession?.begin()
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // This method is called when reading
        guard let ndefMessage = messages.first,
              let record = ndefMessage.records.first,
              let payload = String(data: record.payload, encoding: .utf8) else {
            onCompletion?(.failure(NFCError.invalidData))
            return
        }

        onCompletion?(.success(payload))
        session.invalidate()
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        // This method is called when writing
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No tag found.")
            return
        }

        session.connect(to: tag) { error in
            if let error = error {
                session.invalidate(errorMessage: "Connection error: \(error.localizedDescription)")
                return
            }

            tag.queryNDEFStatus { status, capacity, error in
                guard error == nil else {
                    session.invalidate(errorMessage: "Query error: \(error!.localizedDescription)")
                    return
                }

                switch status {
                case .notSupported:
                    session.invalidate(errorMessage: "Tag is not NDEF compliant.")
                case .readOnly:
                    session.invalidate(errorMessage: "Tag is read-only.")
                case .readWrite:
                    guard let message = self.onCompletion as? (Result<String, Error>) -> Void else {
                        session.invalidate(errorMessage: "Invalid completion handler.")
                        return
                    }
                    
                    let payload = NFCNDEFPayload.wellKnownTypeTextPayload(string: message, locale: Locale(identifier: "en"))!
                    let ndefMessage = NFCNDEFMessage(records: [payload])
                    
                    tag.writeNDEF(ndefMessage) { error in
                        if let error = error {
                            session.invalidate(errorMessage: "Write error: \(error.localizedDescription)")
                        } else {
                            session.alertMessage = "Successfully wrote to tag."
                            session.invalidate()
                        }
                    }
                @unknown default:
                    session.invalidate(errorMessage: "Unknown tag status.")
                }
            }
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        if let readerError = error as? NFCReaderError {
            if readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead,
               readerError.code != .readerSessionInvalidationErrorUserCanceled {
                onCompletion?(.failure(error))
            }
        } else {
            onCompletion?(.failure(error))
        }
        nfcSession = nil
    }
}

enum NFCError: Error {
    case notAvailable
    case invalidData
}
