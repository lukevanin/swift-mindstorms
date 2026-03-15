//
//  File.swift
//  SwiftMindstorms
//
//  Created by Luke Van In on 2026/03/15.
//

import Foundation


final class CommandQueue {
    
    private let queue: DataQueue
    private let encoder: JSONEncoder

    init(queue: DataQueue, encoder: JSONEncoder = JSONEncoder()) {
        self.queue = queue
        self.encoder = encoder
    }
    
    @discardableResult public func enqueue(request: AnyRequest) async throws -> String {
        let command = Command(p: request)
        var data = try encoder.encode(command)
        data.append(0x0d) // \r
        try await queue.send(data: data)
        return command.i
    }
}
