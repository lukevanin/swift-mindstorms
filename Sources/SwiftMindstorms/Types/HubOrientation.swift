//
//  File.swift
//  
//
//  Created by Luke Van In on 2021/04/13.
//

import Foundation


extension Bitmap {
    func oriented(to orientation: HubOrientation) -> Bitmap {
        var output = Bitmap()
        for y in 0 ..< dimensions.y {
            for x in 0 ..< dimensions.x {
                let c0 = Coordinate(x: x, y: y)
                let c1 = orient(
                    coordinate: c0,
                    orientation: orientation
                )
                output[c1] = self[c0]
            }
        }
        return output
    }
    
    private func orient(coordinate: Coordinate, orientation: HubOrientation) -> Coordinate {
        switch orientation {
        case .up:
            return coordinate
        case .left:
            return Coordinate(
                x: coordinate.y,
                y: 4 - coordinate.x
            )
        }
    }
}


public enum HubOrientation {
    case up // Main button at bottom
    case left // Main button on left
}
