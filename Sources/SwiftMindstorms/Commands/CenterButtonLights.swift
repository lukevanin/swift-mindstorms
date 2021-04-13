//
//  CenterButtonLights.swift
//  Robot
//
//  Created by Luke Van In on 2021/01/11.
//

import Foundation

public struct CenterButtonLights: IRequest {
    public static let name = "scratch.center_button_lights"
    public var color: Hue
    public init(color: Hue) {
        self.color = color
    }
}
