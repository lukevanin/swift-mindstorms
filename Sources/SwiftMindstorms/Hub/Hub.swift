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

struct Command: Encodable {
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
    var status: CurrentValueSubject<HubConnectionStatus, Never> { get }
    var data: PassthroughSubject<Data, Never> { get }
    func reconnect()
    func connect()
    func send(data: Data)
}

///
/// Provides low level communications with the hub.
///
public final class Hub: NSObject {

    public let connectionStatus = CurrentValueSubject<HubConnectionStatus, Never>(.notConnected)
    public let events = PassthroughSubject<Event, Never>()

    private var inputBuffer = Data()
    private var cancellables = Set<AnyCancellable>()
    private let connection: IHubConnection

    public init(connection: IHubConnection) {
        self.connection = connection
        super.init()
        connection.status
            .sink { [weak self] status in
                guard let self = self else {
                    return
                }
                switch status {
                case .connected:
                    self.enqueue(request: ProgramMode(mode: .play))
                    self.enqueue(request: CenterButtonLights(color: .black))
                default:
                    break
                }
                self.connectionStatus.send(status)
            }
            .store(in: &cancellables)
        connection.data
            .sink { [weak self] data in
                guard let self = self else {
                    return
                }
                self.inputBuffer.append(data)
                self.parseInput()
            }
            .store(in: &cancellables)
    }
    
    public func reconnect() {
        print("Reconnecting...")
        connection.reconnect()
    }
    
    public func connect() {
        print("Connecting...")
        connection.connect()
    }

    @discardableResult public func enqueue<Program>(request: Program) -> String where Program: IRequest {
        enqueue(request: AnyRequest(request))
    }

    @discardableResult public func enqueue(request: AnyRequest) -> String {
        dispatchPrecondition(condition: .onQueue(.main))
        let encoder = JSONEncoder()
        let command = Command(p: request)
        var data = try! encoder.encode(command)
        data.append(0x0d) // \r
        connection.send(data: data)
        return command.i
    }
    
    private func parseInput() {
        dispatchPrecondition(condition: .onQueue(.main))
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
            let decoder = JSONDecoder()
            let container = try decoder.decode(EventMessage.self, from: data)
            if let event = container.event {
                switch event {
                case .battery(_), .result(_), .runtimeError(_):
                    print(message)
                default:
                    break
                }
                events.send(event)
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
