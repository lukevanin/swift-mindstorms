//
//  MoveStop.swift
//  Mindstorms
//
//  Created by Luke Van In on 2021/04/13.
//

import Foundation

public struct MoveStop: IRequest {
    public static let name = "scratch.move_stop"
    public var lmotor: MotorPort
    public var rmotor: MotorPort
    public var stop: Int
    public init(
        lmotor: MotorPort,
        rmotor: MotorPort,
        stop: Int = 1
    ) {
        self.lmotor = lmotor
        self.rmotor = rmotor
        self.stop = stop
    }
}
