//
//  MotorGoToRelativePosition.swift
//  Mindstorms
//
//  Created by Luke Van In on 2021/04/10.
//

import Foundation

public struct MotorGoToRelativePosition: IRequest {
    public static let name = "scratch.motor_go_to_relative_position"
    public var port: MotorPort
    public var position: Int
    public var speed: Int
    public var stall: Bool
    public var stop: Int
    public init(
        port: MotorPort,
        position: Int,
        speed: Int,
        stall: Bool,
        stop: Int = 1
    ) {
        self.port = port
        self.position = position
        self.speed = speed
        self.stall = stall
        self.stop = stop
    }
}
