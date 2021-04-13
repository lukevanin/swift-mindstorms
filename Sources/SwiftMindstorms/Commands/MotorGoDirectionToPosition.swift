//
//  MotorGoDirectionToPosition.swift
//  Mindstorms
//
//  Created by Luke Van In on 2021/04/11.
//

import Foundation

public struct MotorGoDirectionToPosition: IRequest {
    public static let name = "scratch.motor_go_direction_to_position"
    public var port: MotorPort
    public var position: Int
    public var direction: MotorDirection
    public var speed: Int
    public var stall: Bool
    public var stop: Int
    public init(
        port: MotorPort,
        position: Int,
        direction: MotorDirection,
        speed: Int,
        stall: Bool,
        stop: Int = 1
    ) {
        self.port = port
        self.position = position
        self.direction = direction
        self.speed = speed
        self.stall = stall
        self.stop = stop
    }
}
