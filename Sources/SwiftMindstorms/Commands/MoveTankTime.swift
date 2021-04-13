//
//  MotorTankTime.swift
//  Robot
//
//  Created by Luke Van In on 2021/01/11.
//

import Foundation

public struct MoveTankTime: IRequest {
    public static let name = "scratch.move_tank_time"
    public var time: Int
    public var lspeed: Int
    public var rspeed: Int
    public var lmotor: MotorPort
    public var rmotor: MotorPort
    public var stop: Int
    public init(
        time: Int,
        lspeed: Int,
        rspeed: Int,
        lmotor: MotorPort,
        rmotor: MotorPort,
        stop: Int = 1
    ) {
        self.time = time
        self.lspeed = lspeed
        self.rspeed = rspeed
        self.lmotor = lmotor
        self.rmotor = rmotor
        self.stop = stop
    }
}
