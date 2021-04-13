//
//  MotorRunForDegrees.swift
//  Mindstorms
//
//  Created by Luke Van In on 2021/04/10.
//

import Foundation

public struct MotorRunForDegrees: IRequest {
    public static let name = "scratch.motor_run_for_degrees"
    public var port: MotorPort
    public var degrees: Int
    public var speed: Int
    public var stall: Bool
    public var stop: Int
    public init(
        port: MotorPort,
        degrees: Int,
        speed: Int,
        stall: Bool,
        stop: Int
    ) {
        self.port = port
        self.degrees = degrees
        self.speed = speed
        self.stall = stall
        self.stop = stop
    }
}
