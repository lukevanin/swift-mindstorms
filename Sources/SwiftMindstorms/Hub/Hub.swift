//
//  Hub.swift
//  Robot
//
//  Created by Luke Van In on 2021/01/05.
//

import Foundation
import Combine


// MARK: - Commands

public protocol IRequest: Encodable {
    static var name: String { get }
}

public struct AnyRequest: Encodable {
    public typealias Encode = (Encoder) throws -> Void
    public let name: String
    private let internalEncode: Encode
    public init<R>(_ r: R) where R: IRequest {
        self.name = R.name
        self.internalEncode = r.encode
    }
    public func encode(to encoder: Encoder) throws {
        try internalEncode(encoder)
    }
}

struct AnyCommand: CustomDebugStringConvertible {
    let name: String
    let debugDescription: String
    let data: Data
}

private var lastId = 0

func nextId() -> String {
    defer {
        lastId += 1
    }
    return String(format: "%05d", lastId)
}

public struct Command: Encodable {
    let i: String
    let m: String
    let p: AnyRequest?

    init(p: AnyRequest) {
        self.p = p
        self.i = nextId()
        self.m = p.name
    }
}

// MARK: - Events

struct EventMessage: Decodable {
    enum CodingKeys: String, CodingKey {
        case i // ID
        case e // Error
        case r // Result
        case m // Message
        case p // Parameters
    }

    let event: Event?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let m = try? container.decodeIfPresent(Int.self, forKey: .m) {
            switch m {
            case 0:
                event = .measurements(try container.decode(Event.Measurements.self, forKey: .p))
            case 2:
                event = .battery(try container.decode(Event.Battery.self, forKey: .p))
            default:
                event = nil
            }
        }
        else if let m = try? container.decodeIfPresent(String.self, forKey: .m) {
            switch m {
            case "runtime_error":
                event = .runtimeError(try container.decode(Event.RuntimeError.self, forKey: .p))
            default:
                event = nil
            }
        }
        else if let id = try container.decodeIfPresent(String.self, forKey: .i) {
            if let status = try container.decodeIfPresent(Event.Result.Status.self, forKey: .r) {
                event = .result(Event.Result(id: id, status: status))
            }
            else if let errorBase64 = try container.decodeIfPresent(String.self, forKey: .e) {
                if let errorData = Data(base64Encoded: errorBase64) {
                    if let error = try? JSONDecoder().decode(Event.InstructionError.self, from: errorData) {
                        event = .result(Event.Result(id: id, status: .error(error)))
                    }
                    else {
                        event = .result(Event.Result(id: id, status: .failed))
                    }
                }
                else {
                    event = .result(Event.Result(id: id, status: .failed))
                }
            }
            else {
                event = nil
            }
        }
        else {
            event = nil
        }
    }
}


// MARK: - Hub

public enum HubConnectionStatus {
    case notConnected
    case connecting
    case connected
}

public protocol IHubConnection {
    func connectionStatus() async -> AsyncStream<HubConnectionStatus>
    func reconnect() async
    func connect() async
    func disconnect() async
    @discardableResult func send(command: Command) async throws
    func events() async throws -> AsyncStream<Event>
}


public protocol IHub: Hub {
    func enqueue(command: Command) async throws
    func events() async throws -> AsyncStream<Event>
}

extension IHub {
    func enqueue(request: IRequest) async throws {
        let command = Command(p: AnyRequest(request))
        try await enqueue(command: command)
    }
}

///
/// Provides low level communications with the hub.
///
public final class Hub: NSObject, IHub {

    private var connectionStatusTask: Task<Void, Never>?
    private let connection: IHubConnection

    public init(connection: IHubConnection) {
        self.connection = connection
        super.init()
        observeConnectionStatus()
    }
    
    private func observeConnectionStatus() {
        connectionStatusTask = Task { [weak self] in
            guard let self else { return }
            let connectionStatus = await self.connection.connectionStatus()
            for await status in connectionStatus {
                if status == .connected {
                    try? await self.enqueue(request: ProgramMode(mode: .play))
                    try? await self.enqueue(request: CenterButtonLights(color: .black))
                }
            }
        }
    }

    @discardableResult public func enqueue(command: Command) async throws {
        try await connection.send(command: command)
    }

    public func events() async throws -> AsyncStream<Event> {
        try await connection.events()
    }

}
