//
//  File.swift
//  SwiftMindstorms
//
//  Created by Luke Van In on 2026/03/15.
//

import Foundation
import ExternalAccessory


@MainActor final class DataQueue: NSObject, StreamDelegate {
    
    struct Command {
        let id: String
        let data: Data
        let continuation: CheckedContinuation<Void, Error>
    }
    
    private let dataStreamProvider = AsyncStreamProvider<Data>()
    
    private var queue: [Command] = []
    private var running: Bool = false
    
    private let session: EASession
    
    init(session: EASession) {
        self.session = session
        super.init()
    }
    
    deinit {
        session.inputStream?.close()
        session.inputStream?.delegate = nil
        session.outputStream?.close()
        session.outputStream?.delegate = nil
    }
    
    func data() async -> AsyncStream<Data> {
        await dataStreamProvider.stream()
    }
    
    func open() async {
        guard !running else { return }
        dispatchPrecondition(condition: .onQueue(.main))
        session.outputStream?.schedule(in: RunLoop.main, forMode: .default)
        session.outputStream?.delegate = self
        session.outputStream?.open()
        session.inputStream?.schedule(in: RunLoop.main, forMode: .default)
        session.inputStream?.delegate = self
        session.inputStream?.open()
    }
    
    func close() async {
        guard running else { return }
        dispatchPrecondition(condition: .onQueue(.main))
        session.inputStream?.remove(from: RunLoop.main, forMode: .default)
        session.inputStream?.close()
        session.inputStream?.delegate = nil
        session.outputStream?.remove(from: RunLoop.main, forMode: .default)
        session.outputStream?.close()
        session.outputStream?.delegate = nil
    }
    
    func send(data: Data) async throws {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            let command = Command(
                id: UUID().uuidString,
                data: data,
                continuation: continuation
            )
            queue.append(command)
            dequeueOutput()
        }
    }
    
    nonisolated func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            print(aStream, ".openCompleted")
        case .hasSpaceAvailable:
            Task { [weak self] in
                await self?.dequeueOutput()
            }
        case .hasBytesAvailable:
            Task { [weak self] in
                await self?.dequeueInput()
            }
        case .endEncountered:
            print(aStream, ".endEncountered")
        case .errorOccurred:
            print(aStream, ".errorOccurred", aStream.streamError?.localizedDescription ?? "- Undefined error -")
        default:
            print(aStream, "default")
        }
    }
    
    @MainActor private func dequeueOutput() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard let outputStream = session.outputStream else {
            // Output stream not initialized.
            fatalError("Cannot execute command. Session not connected.")
            return
        }
        guard outputStream.hasSpaceAvailable else {
            // Output buffer is full. Try again later.
            return
        }
        guard queue.count > 0 else {
            // Output queue is empty.
            return
        }
        let command = queue.removeFirst()
        let description = String(data: command.data, encoding: .utf8) ?? "- data -"
        print("DataQueue: Output: \(description)")
        command.data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> Void in
            if let bytes = buffer.bindMemory(to: UInt8.self).baseAddress {
                outputStream.write(bytes, maxLength: buffer.count)
            }
            command.continuation.resume()
        }
    }

    private func dequeueInput() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard let inputStream = session.inputStream else {
            fatalError("Cannot read command. Session not connected.")
            return
        }
        let capacity = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
        defer {
            buffer.deallocate()
        }
        while inputStream.hasBytesAvailable == true {
            let length = inputStream.read(buffer, maxLength: capacity)
            guard length >= 0 else {
                fatalError(inputStream.streamError!.localizedDescription)
            }
            let buffer = Data(bytes: buffer, count: length)
            let description = String(data: buffer, encoding: .utf8) ?? "- invalid data -"
//            print("DataQueue: Input: \(description)")
            dataStreamProvider.yield(buffer)
        }
    }
}
