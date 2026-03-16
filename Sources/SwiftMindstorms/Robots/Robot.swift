//
//  RobotController.swift
//  Robot
//
//  Created by Luke Van In on 2021/01/07.
//

import Foundation
import Combine


public protocol IRobot {
    func execute(request: IRequest) async throws
    func events() async -> AsyncStream<Event>

    // MARK: Display

    func display(image: Bitmap) async throws
    func centerButtonLights(color: Hue) async throws
    func ultrasonicLights(port: MotorPort, lights: (Int, Int, Int, Int)) async throws

    // MARK: Motors

    func motorGoDirectionToPosition(
        port: MotorPort,
        position: Int,
        direction: MotorDirection,
        speed: Int,
        stall: Bool,
        stop: Int
    ) async throws

    func motorGoToRelativePosition(
        port: MotorPort,
        position: Int,
        speed: Int,
        stall: Bool,
        stop: Int
    ) async throws

    func motorPWM(
        port: MotorPort,
        power: Int,
        stall: Bool
    ) async throws

    func motorRunForDegrees(
        port: MotorPort,
        degrees: Int,
        speed: Int,
        stall: Bool,
        stop: Int
    ) async throws

    func motorRunTimed(
        port: MotorPort,
        time: Int,
        speed: Int,
        stall: Bool,
        stop: Int
    ) async throws

    func motorSetPosition(
        port: MotorPort,
        offset: Int
    ) async throws

    func motorStart(
        port: MotorPort,
        speed: Int,
        stall: Bool
    ) async throws

    func motorStop(
        port: MotorPort,
        stop: Int
    ) async throws
}


@MainActor public class Robot: IRobot {
    
    private enum InternalError: Error {
        case commandFailed
    }
    
    public typealias Continuation = CheckedContinuation<Void, Error>

    private var eventsProvider = AsyncStreamProvider<Event>()
    private var continuations = [String : Continuation]()
    private var eventsTask: Task<Void, Never>?
    private var connectionStatusTask: Task<Void, Never>?
    
    private let hub: IHub
    private let connection: IHubConnection
    private let orientation: HubOrientation
    
    public init(connection: IHubConnection, hub: Hub, orientation: HubOrientation) {
        self.orientation = orientation
        self.hub = hub
        self.connection = connection
        observeConnectionStatus()
        Task { [weak self] in
            await self?.connection.reconnect()
        }
    }
    
    private func observeConnectionStatus() {
        connectionStatusTask = Task { [weak self] in
            guard let self else { return }
            let connectionStatus = await self.connection.connectionStatus()
            for await status in connectionStatus {
                if status == .connected {
                    self.addEventsObserver()
                } else {
                    self.removeEventsObserver()
                }
            }
        }
    }
    
    private func addEventsObserver() {
        eventsTask = Task { [weak self] in
            guard let self else { return }
            guard let events = try? await self.hub.events() else { return }
            for await event in events {
                self.handleEvent(event)
            }
        }
    }
    
    private func removeEventsObserver() {
        eventsTask?.cancel()
    }
    
    private func handleEvent(_ event: Event) {
        switch event {
        case .result(let result):
            print("Robot > handleEvent: received result \(result.id) \(result)")
            if let continuation = continuations.removeValue(forKey: result.id) {
                switch result.status {
                case .done:
                    continuation.resume()
                default:
                    continuation.resume(throwing: InternalError.commandFailed)
                }
            }
        default:
            break
        }
        eventsProvider.yield(event)
    }

    public func execute(request: IRequest) async throws {
        let command = Command(p: AnyRequest(request))
        let id = command.i
        print("Robot > execute: enqueueing command \(id)")
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else { return }
            self.continuations[id] = continuation
            Task {
                do {
                    try await hub.enqueue(command: command)
                } catch {
                    if let continuation = self.continuations.removeValue(forKey: id) {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    public func events() async -> AsyncStream<Event> {
        await eventsProvider.stream()
    }
}

// MARK: Display

extension Robot {
    
    public func display(image: Bitmap) async throws {
        try await execute(
            request: DisplayImage(
                image: image.oriented(to: orientation)
            )
        )
    }
    
    public func centerButtonLights(color: Hue) async throws {
        try await execute(
            request: CenterButtonLights(
                color: color
            )
        )
    }
    
    public func ultrasonicLights(
        port: MotorPort,
        lights: (Int, Int, Int, Int)
    ) async throws {
        try await execute(
            request: UltrasonicLightUp(
                port: port,
                lights: [lights.0, lights.1, lights.2, lights.3]
            )
        )
    }
}

// MARK: Motos

extension Robot {
    
    public func motorGoDirectionToPosition(
        port: MotorPort,
        position: Int,
        direction: MotorDirection,
        speed: Int,
        stall: Bool,
        stop: Int = 1
    ) async throws {
        try await execute(
            request: MotorGoDirectionToPosition(
                port: port,
                position: position,
                direction: direction,
                speed: speed,
                stall: stall,
                stop: stop
            )
        )
    }
    
    public func motorGoToRelativePosition(
        port: MotorPort,
        position: Int,
        speed: Int,
        stall: Bool,
        stop: Int = 1
    ) async throws {
        try await execute(
            request: MotorGoToRelativePosition(
                port: port,
                position: position,
                speed: speed,
                stall: stall
            )
        )
    }
    
    public func motorPWM(
        port: MotorPort,
        power: Int,
        stall: Bool
    ) async throws {
        try await execute(
            request: MotorPWM(
                port: port,
                power: power,
                stall: stall
            )
        )
    }
    
    public func motorRunForDegrees(
        port: MotorPort,
        degrees: Int,
        speed: Int,
        stall: Bool,
        stop: Int = 1
    ) async throws {
        try await execute(
            request: MotorRunForDegrees(
                port: port,
                degrees: degrees,
                speed: speed,
                stall: stall,
                stop: stop
            )
        )
    }
    
    public func motorRunTimed(
        port: MotorPort,
        time: Int,
        speed: Int,
        stall: Bool,
        stop: Int = 1
    ) async throws {
        try await execute(
            request: MotorRunTimed(
                port: port,
                time: time,
                speed: speed,
                stall: stall,
                stop: stop
            )
        )
    }
    
    public func motorSetPosition(
        port: MotorPort,
        offset: Int
    ) async throws {
        try await execute(
            request: MotorSetPosition(
                port: port,
                offset: offset
            )
        )
    }
    
    public func motorStart(
        port: MotorPort,
        speed: Int,
        stall: Bool
    ) async throws {
        try await execute(
            request: MotorStart(
                port: port,
                speed: speed,
                stall: stall
            )
        )
    }
    
    public func motorStop(
        port: MotorPort,
        stop: Int = 1
    ) async throws {
        try await execute(
            request: MotorStop(
                port: port,
                stop: stop
            )
        )
    }
}
