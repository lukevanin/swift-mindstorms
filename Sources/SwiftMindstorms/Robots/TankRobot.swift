//
//  File.swift
//  
//
//  Created by Luke Van In on 2021/04/13.
//

import Foundation


public class TankRobot: Robot {
    
    public struct Configuration {
        public var lhsMotorPort: MotorPort
        public var rhsMotorPort: MotorPort
        public var speed: Int
        public init(
            lhsMotorPort: MotorPort,
            rhsMotorPort: MotorPort,
            speed: Int
        ) {
            self.lhsMotorPort = lhsMotorPort
            self.rhsMotorPort = rhsMotorPort
            self.speed = speed
        }
    }
    
    private let configuration: Configuration
    
    public init(
        connection: IHubConnection,
        hub: Hub,
        orientation: HubOrientation,
        configuration: Configuration
    ) {
        self.configuration = configuration
        super.init(connection: connection, hub: hub, orientation: orientation)
    }

    public func moveStartSpeeds(
        lhsSpeed: Int,
        rhsSpeed: Int
    ) async throws {
        try await execute(
            request: MoveStartSpeeds(
                lspeed: configuration.speed * lhsSpeed,
                rspeed: configuration.speed * rhsSpeed,
                lmotor: configuration.lhsMotorPort,
                rmotor: configuration.rhsMotorPort
            )
        )
    }

    public func moveUnits(
        units: Int, // 1 unit = approx. 100mm
        lhsSpeed: Int,
        rhsSpeed: Int,
        stop: Int = 1
    ) async throws {
        try await execute(
            request: MoveTankDegrees(
                degrees: 207 * units,
                lspeed: configuration.speed * lhsSpeed,
                rspeed: configuration.speed * rhsSpeed,
                lmotor: configuration.lhsMotorPort,
                rmotor: configuration.rhsMotorPort,
                stop: stop
            )
        )
    }

    public func moveTankDegrees(
        degrees: Int,
        lhsSpeed: Int,
        rhsSpeed: Int,
        stop: Int = 1
    ) async throws {
        try await execute(
            request: MoveTankDegrees(
                degrees: degrees,
                lspeed: configuration.speed * lhsSpeed,
                rspeed: configuration.speed * rhsSpeed,
                lmotor: configuration.lhsMotorPort,
                rmotor: configuration.rhsMotorPort,
                stop: stop
            )
        )
    }

    public func moveTankTime(
        time: Int,
        lhsSpeed: Int,
        rhsSpeed: Int,
        stop: Int = 1
    ) async throws {
        try await execute(
            request: MoveTankTime(
                time: time,
                lspeed: lhsSpeed,
                rspeed: rhsSpeed,
                lmotor: configuration.lhsMotorPort,
                rmotor: configuration.rhsMotorPort,
                stop: stop
            )
        )
    }
}
