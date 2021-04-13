//
//  RobotController.swift
//  Robot
//
//  Created by Luke Van In on 2021/01/07.
//

import Foundation
import Combine


public class Robot {
    
    public typealias Completion = (_ success: Bool) -> Void
    
    public let connectionStatus = CurrentValueSubject<HubConnectionStatus, Never>(.notConnected)
    
    private var completions = [String : Completion]()
    private var cancellables = Set<AnyCancellable>()
    
    private let hub: Hub
    private let orientation: HubOrientation
    
    public init(orientation: HubOrientation, hub: Hub) {
        self.orientation = orientation
        self.hub = hub
        hub
            .events
            .sink { [weak self] event in
                guard let self = self else {
                    return
                }
                self.handleEvent(event)
            }
            .store(in: &cancellables)
        hub
            .connectionStatus
            .sink { [weak self] connectionStatus in
                guard let self = self else {
                    return
                }
                self.connectionStatus.send(connectionStatus)
            }
            .store(in: &cancellables)
        
        reconnect()
    }
    
    private func handleEvent(_ event: Event) {
        switch event {
        case .result(let result):
            if let completion = completions.removeValue(forKey: result.id) {
                switch result.status {
                case .done:
                    completion(true)
                default:
                    completion(false)
                }
            }
        default:
            break
        }
    }

    public func enqueue(request: AnyRequest, completion: @escaping Completion) {
        dispatchPrecondition(condition: .onQueue(.main))
        let id = hub.enqueue(request: request)
        completions[id] = completion
    }
    
    public func connect() {
        hub.connect()
    }
    
    public func reconnect() {
        hub.reconnect()
    }
}

// MARK: Utility

extension Robot {
    
    public func enqueue<T>(request: T, completion: @escaping Completion) where T: IRequest {
        enqueue(request: AnyRequest(request), completion: completion)
    }
}

// MARK: Display

extension Robot {
    
    public func display(image: Bitmap, completion: @escaping Completion) {
        enqueue(
            request: DisplayImage(
                image: image.oriented(to: orientation)
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
}
