//
//  MotorStart.swift
//  Robot
//
//  Created by Luke Van In on 2021/01/11.
//

import Foundation

public struct MotorStart: IRequest {
    public static let name = "scratch.motor_start"
    public var port: MotorPort
    public var speed: Int
    public var stall: Bool
    public init(
        port: MotorPort,
        speed: Int,
        stall: Bool
    ) {
        self.port = port
        self.speed = speed
        self.stall = stall
    }
}
