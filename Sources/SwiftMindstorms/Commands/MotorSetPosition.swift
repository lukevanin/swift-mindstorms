//
//  MotorSetPosition.swift
//  Mindstorms
//
//  Created by Luke Van In on 2021/04/11.
//

import Foundation

public struct MotorSetPosition: IRequest {
    public static let name = "scratch.motor_set_position"
    public var port: MotorPort
    public var offset: Int
    public init(
        port: MotorPort,
        offset: Int
    ) {
        self.port = port
        self.offset = offset
    }
}
