//
//  MotorStop.swift
//  Mindstorms
//
//  Created by Luke Van In on 2021/04/11.
//

import Foundation

public struct MotorStop: IRequest {
    public static let name = "scratch.motor_stop"
    public var port: MotorPort
    public var stop: Int
    public init(
        port: MotorPort,
        stop: Int = 1
    ) {
        self.port = port
        self.stop = stop
    }
}
