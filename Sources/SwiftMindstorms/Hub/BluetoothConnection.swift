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
    
    enum InternalError: Error {
        case notConnected
    }
    
    private class AnyState: NSObject {
        unowned var context: BluetoothConnection!
        func enter() async {
        }
        func exit() {
        }
        func connect() async {
        }
        func reconnect() async {
        }
        func disconnect() async {
        }
        func send(command: Command) async throws {
            throw InternalError.notConnected
        }
        func events() async throws -> AsyncStream<Event> {
            throw InternalError.notConnected
        }
    }
    
    private final class DisconnectedState: AnyState {
        override func enter()  async{
            context.statusProvider.yield(.notConnected)
        }
        override func reconnect() async {
            guard let session = context.getConnectedSession() else {
                return
            }
            await context.gotoConnectedState(session: session)
        }
        override func connect() async {
            await context.gotoConnectState()
        }
    }
    
    private final class ConnectState: AnyState {
        override func enter() async {
            context.statusProvider.yield(.connecting)
            context.accessoryManager.showBluetoothAccessoryPicker(
                withNameFilter: nil,
                completion: { [weak self] (error) in
                    Task { [weak self] in
                        await self?.handleAccessorySelected(error :error)
                    }
                }
            )
        }
        
        private func handleAccessorySelected(error: Error?) async {
            guard let session = self.context.getConnectedSession() else {
                if let error = error {
                    let pickerError = EABluetoothAccessoryPickerError(_nsError: error as NSError)
                    print(error)
                    print(pickerError)
                }
                await context.gotoDisconnectedState()
                return
            }
            await context.gotoConnectedState(session: session)
        }
    }
    
    private final class ConnectedState: AnyState, EAAccessoryDelegate {

        private let commandQueue: CommandQueue
        private let eventQueue: EventQueue
        private let dataQueue: DataQueue
        private let session: EASession
        
        init(session: EASession) async {
            self.session = session
            self.dataQueue = await DataQueue(session: session)
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
        
        override func enter() async {
            context.statusProvider.yield(.connected)
            await dataQueue.open()
        }
        
        override func disconnect() async {
            await dataQueue.close()
        }
        
        @discardableResult override func send(command: Command) async throws {
            try await commandQueue.enqueue(command: command)
        }
        
        override func events() async -> AsyncStream<Event> {
            await eventQueue.events()
        }
        
        func accessoryDidDisconnect(_ accessory: EAAccessory) {
            dispatchPrecondition(condition: .onQueue(.main))
            Task { [weak self] in
                await self?.context.gotoDisconnectedState()
            }
        }
    }
        
    private var currentState: AnyState!
    
    private let accessoryManager = EAAccessoryManager.shared()
    private let notificationCenter = NotificationCenter.default
    private let protocolString = "com.lego.les"

    public init() {
        currentState = DisconnectedState()
        currentState.context = self
        Task { [weak self] in
            await self?.currentState.enter()
        }
    }
    
    // MARK: State machine
    
    private func gotoDisconnectedState() async {
        gotoState(DisconnectedState())
    }
    
    private func gotoConnectState() async {
        gotoState(ConnectState())
    }
    
    private func gotoConnectedState(session: EASession) async {
        await gotoState(ConnectedState(session: session))
    }
    
    private func gotoState(_ state: AnyState) {
        currentState?.exit()
        currentState?.context = nil
        currentState = state
        currentState.context = self
        Task { [weak self] in
            await self?.currentState.enter()
        }
    }
    
    // MARK: IHubConnection

    private let statusProvider = AsyncStreamProvider<HubConnectionStatus>()
    
    public func connectionStatus() async -> AsyncStream<HubConnectionStatus> {
        await statusProvider.stream()
    }

    public func reconnect() async {
        await currentState?.reconnect()
    }
    
    public func connect() async {
        await currentState?.connect()
    }
    
    public func disconnect() async {
        await currentState.disconnect()
    }
    
    public func send(command: Command) async throws {
        try await currentState.send(command: command)
    }
    
    public func events() async throws -> AsyncStream<Event> {
        try await currentState.events()
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
