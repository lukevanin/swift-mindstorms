//
//  MotorPWM.swift
//  Mindstorms
//
//  Created by Luke Van In on 2021/04/10.
//

import Foundation

public struct MotorPWM: IRequest {
    public static let name = "scratch.motor_pwm"
    public var port: MotorPort
    public var power: Int
    public var stall: Bool
    public init(port: MotorPort, power: Int, stall: Bool) {
        self.port = port
        self.power = power
        self.stall = stall
    }
}
