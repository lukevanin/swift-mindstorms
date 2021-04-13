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
        func send(data: Data) {
            context.outputQueue.append(data)
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
    
    private final class ConnectedState: AnyState, StreamDelegate, EAAccessoryDelegate {
        private var cancellables = Set<AnyCancellable>()
        private let session: EASession
        
        init(session: EASession) {
            self.session = session
            super.init()
            session.accessory?.delegate = self
            session.outputStream?.schedule(in: .current, forMode: .default)
            session.outputStream?.delegate = self
            session.outputStream?.open()
            session.inputStream?.schedule(in: .current, forMode: .default)
            session.inputStream?.delegate = self
            session.inputStream?.open()
        }
        
        override func enter() {
            context.status.send(.connected)
        }
        
        override func send(data: Data) {
            dispatchPrecondition(condition: .onQueue(.main))
            context.outputQueue.append(data)
            dequeueOutput()
        }
        
        private func dequeueOutput() {
            dispatchPrecondition(condition: .onQueue(.main))
            guard let outputStream = session.outputStream else {
                // Output stream not initialized.
                fatalError("Cannot execute command. Session not connected.")
                return
            }
            guard outputStream.hasSpaceAvailable else {
                // Output buffer is full. Try again later.
                return
            }
            guard context.outputQueue.count > 0 else {
                // Output queue is empty.
                return
            }
            let data = context.outputQueue.removeFirst()
//            print(command)
//            var data = command.data
//            var outputData
//            data.append(0x0d) // \r
            let description = String(data: data, encoding: .utf8) ?? "- data -"
            print(" BluetoothConnection: Sending: \(description)")
            data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> Void in
                if let bytes = buffer.bindMemory(to: UInt8.self).baseAddress {
                    outputStream.write(bytes, maxLength: buffer.count)
                }
            }
        }

        private func dequeueInput() {
            dispatchPrecondition(condition: .onQueue(.main))
            guard let inputStream = session.inputStream else {
                fatalError("Cannot read command. Session not connected.")
                return
            }
            let capacity = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
            defer {
                buffer.deallocate()
            }
            while inputStream.hasBytesAvailable == true {
                let length = inputStream.read(buffer, maxLength: capacity)
                guard length >= 0 else {
                    fatalError(inputStream.streamError!.localizedDescription)
                }
                let buffer = Data(bytes: buffer, count: length)
                context.data.send(buffer)
            }
        }
        
        func accessoryDidDisconnect(_ accessory: EAAccessory) {
            dispatchPrecondition(condition: .onQueue(.main))
            context.gotoDisconnectedState()
        }

        func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
            dispatchPrecondition(condition: .onQueue(.main))
            switch eventCode {
            case .openCompleted:
                print(aStream, ".openCompleted")
            case .hasSpaceAvailable:
                dequeueOutput()
            case .hasBytesAvailable:
                dequeueInput()
            case .endEncountered:
                print(aStream, ".endEncountered")
            case .errorOccurred:
                print(aStream, ".errorOccurred", aStream.streamError?.localizedDescription ?? "- Undefined error -")
            default:
                print(aStream, "default")
            }
        }

    }
        
    private var outputQueue = [Data]()
    private var currentState: AnyState?
    
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
    
    private func gotoState(_ state: AnyState?) {
        currentState?.exit()
        currentState = state
        currentState?.context = self
        currentState?.enter()
    }
    
    // MARK: IHubConnection
    
    public let status = CurrentValueSubject<HubConnectionStatus, Never>(.notConnected)

    public let data = PassthroughSubject<Data, Never>()

    public func reconnect() {
        currentState?.reconnect()
    }
    
    public func connect() {
        currentState?.connect()
    }
    
    public func send(data: Data) {
        currentState?.send(data: data)
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
