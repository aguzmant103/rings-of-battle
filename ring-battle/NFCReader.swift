import Foundation
import CoreNFC

@MainActor
class NFCReader: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    private var nfcSession: NFCNDEFReaderSession?
    private var onCompletion: ((Result<String, Error>) -> Void)?
    private var messageToWrite: String?
    private var isWriteOperation: Bool = false

    func scanNFC(completion: @escaping (Result<String, Error>) -> Void) {
        guard NFCNDEFReaderSession.readingAvailable else {
            completion(.failure(NFCError.notAvailable))
            return
        }

        onCompletion = completion
        isWriteOperation = false
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        nfcSession?.alertMessage = "Hold your iPhone near the NFC ring to read."
        nfcSession?.begin()
    }

    func writeToNFC(_ message: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard NFCNDEFReaderSession.readingAvailable else {
            completion(.failure(NFCError.notAvailable))
            return
        }

        messageToWrite = message
        isWriteOperation = true
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
        guard !isWriteOperation else { return }
        
        guard let ndefMessage = messages.first,
              let record = ndefMessage.records.first else {
            onCompletion?(.failure(NFCError.invalidData))
            return
        }

        switch record.typeNameFormat {
        case .nfcWellKnown:
            if let type = String(data: record.type, encoding: .utf8), type == "T" {
                // This is a text record
                if let payload = String(data: record.payload.dropFirst(), encoding: .utf8) {
                    onCompletion?(.success(payload))
                } else {
                    onCompletion?(.failure(NFCError.invalidData))
                }
            } else {
                onCompletion?(.failure(NFCError.unsupportedFormat))
            }
        case .absoluteURI:
            if let payload = String(data: record.payload, encoding: .utf8) {
                onCompletion?(.success(payload))
            } else {
                onCompletion?(.failure(NFCError.invalidData))
            }
        default:
            onCompletion?(.failure(NFCError.unsupportedFormat))
        }
        
        session.invalidate()
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
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
                    if self.isWriteOperation {
                        session.invalidate(errorMessage: "Tag is read-only.")
                    } else {
                        self.readTag(tag, session: session)
                    }
                case .readWrite:
                    if self.isWriteOperation {
                        self.writeTag(tag, session: session)
                    } else {
                        self.readTag(tag, session: session)
                    }
                @unknown default:
                    session.invalidate(errorMessage: "Unknown tag status.")
                }
            }
        }
    }

    private func readTag(_ tag: NFCNDEFTag, session: NFCNDEFReaderSession) {
        tag.readNDEF { message, error in
            if let error = error {
                session.invalidate(errorMessage: "Read error: \(error.localizedDescription)")
            } else if let message = message {
                if message.records.isEmpty {
                    session.invalidate(errorMessage: "Tag is empty.")
                } else {
                    let payloads = message.records.compactMap { record -> String? in
                        switch record.typeNameFormat {
                        case .nfcWellKnown:
                            if let type = String(data: record.type, encoding: .utf8), type == "T" {
                                // Text record
                                let payload = record.payload
                                // The first byte is the language code length
                                let languageCodeLength = Int(payload[0])
                                // Skip language code and status byte
                                let textStartIndex = 1 + languageCodeLength
                                return String(data: payload.suffix(from: textStartIndex), encoding: .utf8)
                            } else {
                                return "Unknown well-known type: \(record.type.map { String(format: "%02hhx", $0) }.joined())"
                            }
                        case .absoluteURI:
                            return String(data: record.payload, encoding: .utf8)
                        default:
                            return "Unsupported record type: \(record.typeNameFormat)"
                        }
                    }
                    
                    if payloads.isEmpty {
                        session.invalidate(errorMessage: "No readable payloads found on tag.")
                    } else {
                        let payloadString = payloads.joined(separator: "\n")
                        self.onCompletion?(.success(payloadString))
                        session.alertMessage = "Successfully read from tag."
                        session.invalidate()
                    }
                }
            } else {
                session.invalidate(errorMessage: "No message found on tag.")
            }
        }
    }

    private func writeTag(_ tag: NFCNDEFTag, session: NFCNDEFReaderSession) {
        guard let messageToWrite = self.messageToWrite else {
            session.invalidate(errorMessage: "No message to write.")
            return
        }
        
        // Create a proper NDEF text record with "en" language code
        let languageCode = "en".data(using: .utf8)!
        var payload = Data([UInt8(languageCode.count)]) + languageCode + messageToWrite.data(using: .utf8)!
        let textRecord = NFCNDEFPayload(
            format: .nfcWellKnown,
            type: "T".data(using: .utf8)!,
            identifier: Data(),
            payload: payload
        )
        
        let message = NFCNDEFMessage(records: [textRecord])
        
        tag.writeNDEF(message) { error in
            if let error = error {
                session.invalidate(errorMessage: "Write error: \(error.localizedDescription)")
            } else {
                session.alertMessage = "Successfully wrote to tag."
                session.invalidate()
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

    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        print("NFC reader session became active")
    }
}

enum NFCError: Error {
    case notAvailable
    case invalidData
    case systemResourceUnavailable
    case unsupportedFormat
}
