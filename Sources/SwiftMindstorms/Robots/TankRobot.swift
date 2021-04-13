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
        hub: Hub,
        orientation: HubOrientation,
        configuration: Configuration
    ) {
        self.configuration = configuration
        super.init(orientation: orientation, hub: hub)
    }

    public func moveStartSpeeds(
        lhsSpeed: Int,
        rhsSpeed: Int,
        completion: @escaping Completion
    ) {
        enqueue(
            request: MoveStartSpeeds(
                lspeed: configuration.speed * lhsSpeed,
                rspeed: configuration.speed * rhsSpeed,
                lmotor: configuration.lhsMotorPort,
                rmotor: configuration.rhsMotorPort
            ),
            completion: completion
        )
    }

    public func moveUnits(
        units: Int, // 1 unit = approx. 100mm
        lhsSpeed: Int,
        rhsSpeed: Int,
        stop: Int = 1,
        completion: @escaping Completion
    ) {
        enqueue(
            request: MoveTankDegrees(
                degrees: 207 * units,
                lspeed: configuration.speed * lhsSpeed,
                rspeed: configuration.speed * rhsSpeed,
                lmotor: configuration.lhsMotorPort,
                rmotor: configuration.rhsMotorPort,
                stop: stop
            ),
            completion: completion
        )
    }

    public func moveTankDegrees(
        degrees: Int,
        lhsSpeed: Int,
        rhsSpeed: Int,
        stop: Int = 1,
        completion: @escaping Completion
    ) {
        enqueue(
            request: MoveTankDegrees(
                degrees: degrees,
                lspeed: configuration.speed * lhsSpeed,
                rspeed: configuration.speed * rhsSpeed,
                lmotor: configuration.lhsMotorPort,
                rmotor: configuration.rhsMotorPort,
                stop: stop
            ),
            completion: completion
        )
    }

    public func moveTankTime(
        time: Int,
        lhsSpeed: Int,
        rhsSpeed: Int,
        stop: Int = 1,
        completion: @escaping Completion
    ) {
        enqueue(
            request: MoveTankTime(
                time: time,
                lspeed: lhsSpeed,
                rspeed: rhsSpeed,
                lmotor: configuration.lhsMotorPort,
                rmotor: configuration.rhsMotorPort,
                stop: stop
            ),
            completion: completion
        )
    }
}
