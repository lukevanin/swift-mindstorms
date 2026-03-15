//
//  File.swift
//  SwiftMindstorms
//
//  Created by Luke Van In on 2026/03/15.
//

import Foundation


final class EventQueue {

    private var eventsProvider = AsyncStreamProvider<Event>()
    private var inputBuffer = Data()
    private var inputBufferTask: Task<Void, Never>?
    
    private let queue: DataQueue
    private let decoder: JSONDecoder
    
    init(queue: DataQueue, decoder: JSONDecoder = JSONDecoder()) {
        self.queue = queue
        self.decoder = decoder
        observeData()
    }
    
    func events() async -> AsyncStream<Event> {
        await eventsProvider.stream()
    }
    
    private func observeData() {
        inputBufferTask = Task { [weak self] in
            guard let self else { return }
            let stream = await queue.data()
            for await data in stream {
                self.inputBuffer.append(contentsOf: data)
                self.parseInput()
            }
        }
    }
    
    private func parseInput() {
        guard inputBuffer.count > 0 else {
            return
        }
        while let index = inputBuffer.firstIndex(of: 0x0d) {
            let endIndex = index + 1
            let fragment = inputBuffer[inputBuffer.startIndex ..< endIndex]
            let message = String(data: fragment, encoding: .utf8)!
            parseMessage(message)
            inputBuffer.removeFirst(fragment.count)
        }
    }
    
    private func parseMessage(_ message: String) {
        let data = message.data(using: .utf8)!
        do {
            let container = try decoder.decode(EventMessage.self, from: data)
            if let event = container.event {
                switch event {
                case .battery(_), .result(_), .runtimeError(_):
                    print(message)
                default:
                    break
                }
                eventsProvider.yield(event)
            }
            else {
                print("No event", message)
            }
        }
        catch {
            print(error.localizedDescription)
            print(message)
        }
    }
}
