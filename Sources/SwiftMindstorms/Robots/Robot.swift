//
//  RobotController.swift
//  Robot
//
//  Created by Luke Van In on 2021/01/07.
//

import Foundation
import Combine


public class Robot {
    
    private enum InternalError: Error {
        case commandFailed
    }
    
    public typealias Continuation = CheckedContinuation<Void, Error>
    
    public let connectionStatus = CurrentValueSubject<HubConnectionStatus, Never>(.notConnected)

    private var eventsProvider = AsyncStreamProvider<Event>()
    private var continuations = [String : Continuation]()
    private var cancellables = Set<AnyCancellable>()
    private var eventsTask: Task<Void, Never>?
    
    private let hub: Hub
    private let orientation: HubOrientation
    
    public init(orientation: HubOrientation, hub: Hub) {
        self.orientation = orientation
        self.hub = hub
        hub
            .connectionStatus
            .sink { [weak self] connectionStatus in
                guard let self = self else {
                    return
                }
                self.connectionStatus.send(connectionStatus)
                if connectionStatus == .connected {
                    self.addEventsObserver()
                } else {
                    self.removeEventsObserver()
                }
            }
            .store(in: &cancellables)
        reconnect()
    }
    
    private func addEventsObserver() {
        eventsTask = Task { [weak self] in
            guard let self else { return }
            guard let events = await self.hub.events() else { return }
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

    public func enqueue(request: IRequest) async throws {
        dispatchPrecondition(condition: .onQueue(.main))
        let id = try await hub.enqueue(request: request)
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else { return }
            self.continuations[id] = continuation
        }
    }
    
    public func connect() {
        hub.connect()
    }
    
    public func reconnect() {
        hub.reconnect()
    }
}

// MARK: Display

extension Robot {
    
    public func display(image: Bitmap) async throws {
        try await enqueue(
            request: DisplayImage(
                image: image.oriented(to: orientation)
            )
        )
    }
    
    public func centerButtonLights(
        color: Hue,
        completion: @escaping Completion
    ) {
        enqueue(
            request: CenterButtonLights(
                color: color
            ),
            completion: completion
        )
    }
    
    public func ultrasonicLights(
        port: MotorPort,
        lights: (Int, Int, Int, Int),
        completion: @escaping Completion
    ) {
        enqueue(
            request: UltrasonicLightUp(
                port: port,
                lights: [lights.0, lights.1, lights.2, lights.3]
            ),
            completion: completion
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
        stop: Int = 1,
        completion: @escaping Completion
    ) {
        enqueue(
            request: MotorGoDirectionToPosition(
                port: port,
                position: position,
                direction: direction,
                speed: speed,
                stall: stall,
                stop: stop
            ),
            completion: completion
        )
    }
    
    public func motorGoToRelativePosition(
        port: MotorPort,
        position: Int,
        speed: Int,
        stall: Bool,
        stop: Int = 1,
        completion: @escaping Completion
    ) {
        enqueue(
            request: MotorGoToRelativePosition(
                port: port,
                position: position,
                speed: speed,
                stall: stall
            ),
            completion: completion
        )
    }
    
    public func motorPWM(
        port: MotorPort,
        power: Int,
        stall: Bool,
        completion: @escaping Completion
    ) {
        enqueue(
            request: MotorPWM(
                port: port,
                power: power,
                stall: stall
            ),
            completion: completion
        )
    }
    
    public func motorRunForDegrees(
        port: MotorPort,
        degrees: Int,
        speed: Int,
        stall: Bool,
        stop: Int = 1,
        completion: @escaping Completion
    ) {
        enqueue(
            request: MotorRunForDegrees(
                port: port,
                degrees: degrees,
                speed: speed,
                stall: stall,
                stop: stop
            ),
            completion: completion
        )
    }
    
    public func motorRunTimed(
        port: MotorPort,
        time: Int,
        speed: Int,
        stall: Bool,
        stop: Int = 1,
        completion: @escaping Completion
    ) {
        enqueue(
            request: MotorRunTimed(
                port: port,
                time: time,
                speed: speed,
                stall: stall,
                stop: stop
            ),
            completion: completion
        )
    }
    
    public func motorSetPosition(
        port: MotorPort,
        offset: Int,
        completion: @escaping Completion
    ) {
        enqueue(
            request: MotorSetPosition(
                port: port,
                offset: offset
            ),
            completion: completion
        )
    }
    
    public func motorStart(
        port: MotorPort,
        speed: Int,
        stall: Bool,
        completion: @escaping Completion
    ) {
        enqueue(
            request: MotorStart(
                port: port,
                speed: speed,
                stall: stall
            ),
            completion: completion
        )
    }
    
    public func motorStop(
        port: MotorPort,
        stop: Int = 1,
        completion: @escaping Completion
    ) {
        enqueue(
            request: MotorStop(
                port: port,
                stop: stop
            ),
            completion: completion
        )
    }
}
