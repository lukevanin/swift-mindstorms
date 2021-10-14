//
//  UltrasonicLightUp.swift
//  Robot
//
//  Created by Luke Van In on 2021/10/14.
//

import Foundation

public struct UltrasonicLightUp: IRequest {
    public static let name = "scratch.ultrasonic_light_up"
    public var port: MotorPort
    public var lights: [Int]
    public init(port: MotorPort, lights: [Int]) {
        self.port = port
        self.lights = lights
    }
}
