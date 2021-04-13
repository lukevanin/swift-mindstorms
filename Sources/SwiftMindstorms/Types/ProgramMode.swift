//
//  ProgramMode.swift
//  Robot
//
//  Created by Luke Van In on 2021/01/11.
//

import Foundation

public struct ProgramMode: IRequest {
    public static let name = "program_modechange"
    public enum Mode: String, Encodable {
        case play
        case download
    }
    public var mode: Mode
    public init(mode: Mode) {
        self.mode = mode
    }
}
