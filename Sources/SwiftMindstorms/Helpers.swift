//
//  File.swift
//  SwiftMindstorms
//
//  Created by Luke Van In on 2026/03/15.
//

import Foundation

final class AsyncStreamProvider<T> {
    
    private final class StreamProvider {
        weak var parent: AsyncStreamProvider?
        let id: UUID
        var stream: AsyncStream<T>!
        var streamContinuation: AsyncStream<T>.Continuation?

        init() async {
            id = UUID()
            await withCheckedContinuation { [weak self] continuation in
                self?.stream = AsyncStream { [weak self] streamContinuation in
                    self?.streamContinuation = streamContinuation
                    streamContinuation.onTermination = { _ in
                        Task { [weak self] in
                            self?.parent?.removeProvider(id)
                        }
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private var value: T?
    private var providers: [UUID: StreamProvider] = [:]
    
    init() {
    }
    
    func yield(_ value: T) {
        self.value = value
        for (id, provider) in providers {
            provider.streamContinuation?.yield(value)
        }
    }
    
    func stream() async -> AsyncStream<T> {
        let provider = await StreamProvider()
        provider.parent = self
        providers[provider.id] = provider
        if let value {
            provider.streamContinuation?.yield(value)
        }
        return provider.stream
    }
    
    private func removeProvider(_ id: UUID) {
        providers.removeValue(forKey: id)
    }
}
