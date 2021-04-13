//
//  MoveStartSpeeds.swift
//  Robot
//
//  Created by Luke Van In on 2021/01/11.
//

import Foundation

public struct MoveStartSpeeds: IRequest {
    public static let name = "scratch.move_start_speeds"
    public var lspeed: Int
    public var rspeed: Int
    public var lmotor: MotorPort
    public var rmotor: MotorPort
    public init(
        lspeed: Int,
        rspeed: Int,
        lmotor: MotorPort,
        rmotor: MotorPort
    ) {
        self.lspeed = lspeed
        self.rspeed = rspeed
        self.lmotor = lmotor
        self.rmotor = rmotor
    }
}
