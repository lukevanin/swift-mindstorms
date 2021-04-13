//
//  MotorRunTimed.swift
//  Mindstorms
//
//  Created by Luke Van In on 2021/04/10.
//

import Foundation

public struct MotorRunTimed: IRequest {
    public static let name = "scratch.motor_run_timed"
    public var port: MotorPort
    public var time: Int
    public var speed: Int
    public var stall: Bool
    public var stop: Int
    public init(
        port: MotorPort,
        time: Int,
        speed: Int,
        stall: Bool,
        stop: Int = 1
    ) {
        self.port = port
        self.time = time
        self.speed = speed
        self.stall = stall
        self.stop = stop
    }
}
