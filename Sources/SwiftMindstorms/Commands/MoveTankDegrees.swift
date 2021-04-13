//
//  MoveTankDegrees.swift
//  Robot
//
//  Created by Luke Van In on 2021/01/11.
//

import Foundation

public struct MoveTankDegrees: IRequest {
    public static let name = "scratch.move_tank_degrees"
    public var degrees: Int
    public var lspeed: Int
    public var rspeed: Int
    public var lmotor: MotorPort
    public var rmotor: MotorPort
    public var stop: Int
    public init(
        degrees: Int,
        lspeed: Int,
        rspeed: Int,
        lmotor: MotorPort,
        rmotor: MotorPort,
        stop: Int = 1
    ) {
        self.degrees = degrees
        self.lspeed = lspeed
        self.rspeed = rspeed
        self.lmotor = lmotor
        self.rmotor = rmotor
        self.stop = stop
    }
}
