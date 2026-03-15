//
//  BluetoothConnection.swift
//  Robot
//
//  Created by Luke Van In on 2021/01/11.
//

import Foundation
import Combine
import ExternalAccessory

public final class BluetoothConnection: IHubConnection {
    
    private class AnyState: NSObject {
        unowned var context: BluetoothConnection!
        func enter() {
        }
        func exit() {
        }
        func connect() {
        }
        func reconnect() {
        }
        func disconnect() {
        }
        @discardableResult func send(request: IRequest) async throws -> String {
            fatalError("Not implemented")
        }
        func events() async -> AsyncStream<Event> {
            fatalError("Not implemented")
        }
    }
    
    private final class DisconnectedState: AnyState {
        override func enter() {
            context.status.send(.notConnected)
        }
        override func reconnect() {
            guard let session = context.getConnectedSession() else {
                return
            }
            context.gotoConnectedState(session: session)
        }
        override func connect() {
            context.gotoConnectState()
        }
    }
    
    private final class ConnectState: AnyState {
        override func enter() {
            context.status.send(.connecting)
            context.accessoryManager.showBluetoothAccessoryPicker(
                withNameFilter: nil,
                completion: { [weak self] (error) in
                    guard let self = self else {
                        return
                    }
                    guard let session = self.context.getConnectedSession() else {
                        if let error = error {
                            let pickerError = EABluetoothAccessoryPickerError(_nsError: error as NSError)
                            print(error)
                            print(pickerError)
                        }
                        self.context.gotoDisconnectedState()
                        return
                    }
                    self.context.gotoConnectedState(session: session)
                }
            )
        }
    }
    
    private final class ConnectedState: AnyState, EAAccessoryDelegate {

        private let commandQueue: CommandQueue
        private let eventQueue: EventQueue
        private let dataQueue: DataQueue
        private let session: EASession
        
        init(session: EASession) {
            self.session = session
            self.dataQueue = DataQueue(session: session)
            self.commandQueue = CommandQueue(queue: dataQueue)
            self.eventQueue = EventQueue(queue: dataQueue)
            super.init()
            session.accessory?.delegate = self
        }
        
        deinit {
            Task { [weak dataQueue] in
                await dataQueue?.close()
            }
            session.accessory?.delegate = nil
        }
        
        override func enter() {
            context.status.send(.connected)
            Task { [weak dataQueue] in
                await dataQueue?.open()
            }
        }
        
        override func disconnect() {
            Task { [weak dataQueue] in
                await dataQueue?.close()
            }
        }
        
        @discardableResult override func send(request: IRequest) async throws -> String {
            try await commandQueue.enqueue(request: AnyRequest(request))
        }
        
        func accessoryDidDisconnect(_ accessory: EAAccessory) {
            dispatchPrecondition(condition: .onQueue(.main))
            context.gotoDisconnectedState()
        }
    }
        
    private var currentState: AnyState!
    
    private let accessoryManager = EAAccessoryManager.shared()
    private let notificationCenter = NotificationCenter.default
    private let protocolString = "com.lego.les"

    public init() {
        gotoDisconnectedState()
    }
    
    // MARK: State machine
    
    private func gotoDisconnectedState() {
        gotoState(DisconnectedState())
    }
    
    private func gotoConnectState() {
        gotoState(ConnectState())
    }
    
    private func gotoConnectedState(session: EASession) {
        gotoState(ConnectedState(session: session))
    }
    
    private func gotoState(_ state: AnyState) {
        currentState?.exit()
        currentState?.context = nil
        currentState = state
        currentState.context = self
        currentState.enter()
    }
    
    // MARK: IHubConnection
    
    public let status = CurrentValueSubject<HubConnectionStatus, Never>(.notConnected)

    public func reconnect() {
        currentState?.reconnect()
    }
    
    public func connect() {
        currentState?.connect()
    }
    
    public func disconnect() {
        currentState.disconnect()
    }
    
    public func send(request: any IRequest) async throws -> String {
        try await currentState.send(request: request)
    }
    
    public func events() async -> AsyncStream<Event>? {
        await currentState.events()
    }
    
    // MARK: EAAccessoryManager
    
    private func getConnectedSession() -> EASession? {
        guard let accessory = accessoryManager.connectedAccessories.first(where: { $0.protocolStrings.contains(protocolString) } ) else {
            print("No accessory found matching protocol.")
            return nil
        }
        guard let session = EASession(accessory: accessory, forProtocol: protocolString) else {
            print("Cannot instantiate session for accessory.")
            return nil
        }
        return session
    }
}
