//
//  Event.swift
//  Robot
//
//  Created by Luke Van In on 2021/01/11.
//

import Foundation

public enum Event {
    
    public struct RuntimeError: Error, Decodable {
        public let version: String
        public let localizedDescription: String
        public init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            let _ = try container.decode([Int].self)
            let _ = try container.decode(String.self)
            self.version = try container.decode(String.self)
            let encodedDescription = try container.decode(String.self)
            let descriptionData = Data(base64Encoded: encodedDescription)
            let description = descriptionData.flatMap{ String(data: $0, encoding: .utf8) }
            self.localizedDescription = description ?? encodedDescription
        }
    }
    
    public struct Measurements: Decodable {
        public struct Motor {
            public enum Kind {
                case medium
            }
            public let kind: Kind
            public let speed: Int
            public let angle: Int
            public let uangle: Int
            public let power: Int
        }
        public struct ColorSensor {
            public let reflected: Int
            public let name: Hue?
            public let rgb: RGB
        }
        public struct UltrasonicSensor {
            public let distance: Int?
        }
        public enum PortInput {
            case motor(Motor)
            case color(ColorSensor)
            case ultrasonic(UltrasonicSensor)
        }
        struct Field: Decodable {
            public enum Kind: Int, Decodable {
                case notConnected = 0
                case color = 61
                case ultrasonic = 62
                case mediumMotor = 75
            }
            let kind: Kind
            let values: [Int?]
            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                self.kind = try container.decode(Kind.self)
                self.values = try container.decode([Int?].self)
            }
        }
        public let ports: [MotorPort : PortInput]
        public let orientation: XYZ
        public let acceleration: XYZ
        public let position: XYZ
        public init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            var ports = [MotorPort : PortInput]()
            for port in MotorPort.allCases {
                let field = try container.decode(Field.self)
                switch field.kind {
                case .mediumMotor:
                    if field.values.count == 4 {
                        ports[port] = .motor(
                            Motor(
                                kind: .medium,
                                speed: field.values[0] ?? 0,
                                angle: field.values[1] ?? 0,
                                uangle: field.values[2] ?? 0,
                                power: field.values[3] ?? 0
                            )
                        )
                    }
                    else {
                        ports[port] = .motor(
                            Motor(
                                kind: .medium,
                                speed: 0,
                                angle: 0,
                                uangle: 0,
                                power: 0
                            )
                        )
                    }
                case .color:
                    if field.values.count == 5 {
                        ports[port] = .color(
                            ColorSensor(
                                reflected: field.values[0] ?? 0,
                                name: field.values[1].flatMap { Hue(rawValue: $0) },
                                rgb: RGB(
                                    r: field.values[2] ?? 0,
                                    g: field.values[3] ?? 0,
                                    b: field.values[4] ?? 0
                                )
                            )
                        )
                    }
                    else {
                        ports[port] = .color(
                            ColorSensor(reflected: 0, name: nil, rgb: RGB(r: 0, g: 0, b: 0))
                        )
                    }
                case .ultrasonic:
                    ports[port] = .ultrasonic(
                        UltrasonicSensor(
                            distance: field.values[0]
                        )
                    )
                case .notConnected:
                    break
                    #warning("TODO: Decode other port inputs types")
                }
            }
            precondition(container.currentIndex == 6)
            let orientation = try container.decode([Int].self)
            precondition(container.currentIndex == 7)
            let acceleration = try container.decode([Int].self)
            precondition(container.currentIndex == 8)
            let position = try container.decode([Int].self)
            self.ports = ports
            self.orientation = XYZ(
                x: orientation[0],
                y: orientation[1],
                z: orientation[2]
            )
            self.acceleration = XYZ(
                x: acceleration[0],
                y: acceleration[1],
                z: acceleration[2]
            )
            self.position = XYZ(
                x: position[0],
                y: position[1],
                z: position[2]
            )
        }
    }

    public struct Battery: Decodable {
        let reserved0: Float
        public let percent: Int
        let reserved1: Bool
        public init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            self.reserved0 = try container.decode(Float.self)
            self.percent = try container.decode(Int.self)
            self.reserved1 = try container.decode(Bool.self)
        }
    }
    
    public struct InstructionError: Error, Decodable {
        public let message: String?
        public let type: String?
    }

    public struct Result: Decodable {

        public enum Status: Decodable {
            case failed
            case done
            case stalled
            case error(InstructionError)
            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                do {
                    let n = try container.decode(Int.self)
                    switch n {
                    case 0:
                        self = .done
                    case 1:
                        self = .done // ?
                    case 2:
                        self = .stalled
                    default:
                        self = .failed
                    }
                }
                catch {
                    let s = try container.decode(String.self)
                    switch s {
                    case "done":
                        self = .done
                    case "stalled":
                        self = .stalled
                    default:
                        self = .failed
                    }
                }
            }
        }
        public let id: String
        public let status: Status?
    }
    
    case runtimeError(RuntimeError)
    case measurements(Measurements)
    case battery(Battery)
    case result(Result)
}
