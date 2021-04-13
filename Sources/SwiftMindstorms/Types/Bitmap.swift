//
//  Image.swift
//  Robot
//
//  Created by Luke Van In on 2021/01/11.
//

import Foundation

public struct Bitmap {
    public let dimensions = Coordinate(x: 5, y: 5)
    public let count = 5 * 5
    
    private var values = [UInt8]()
    
    public init(_ values: [UInt8]) {
        precondition(values.count == count)
        self.values = values
    }
    
    public init() {
        self.values = Array(repeating: 9, count: count)
    }
    
    public subscript(coordinate: Coordinate) -> UInt8 {
        get {
            values[index(for: coordinate)]
        }
        set {
            precondition(newValue >= 0)
            precondition(newValue <= 9)
            values[index(for: coordinate)] = newValue
        }
    }
    
    private func index(for coordinate: Coordinate) -> Int {
        return (coordinate.y * dimensions.x) + coordinate.x
    }
}

extension Bitmap: Encodable {
    public func encode(to encoder: Encoder) throws {
        let base = Character("0").asciiValue!
        var rows = [String]()
        for y in 0 ..< dimensions.y {
            var row = ""
            for x in 0 ..< dimensions.x {
                let p = Coordinate(x: x, y: y)
                let d = self[p]
                let a = d + base // Convert to ASCII code
                let c = Character(UnicodeScalar(a))
                row.append(c)
            }
            rows.append(row)
        }
        let value = rows.joined(separator: ":")
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

extension Bitmap: Decodable {
    public init(from decoder: Decoder) throws {
        let base = Character("0").asciiValue!
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        let rows = value.split(separator: ":")
        guard rows.count == dimensions.y else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected \(dimensions.y) rows but got \(rows.count)"
            )
        }
        var values = [UInt8]()
        for y in 0 ..< dimensions.y {
            let columns = rows[y]
            guard columns.count == dimensions.x else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Expected \(dimensions.x) columns in row \(y) but got \(columns.count)"
                )
            }
            for x in 0 ..< dimensions.x {
                let c = columns[columns.index(columns.startIndex, offsetBy: x)]
                guard let a = c.asciiValue else {
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Expected ascii character at column \(x) in row \(y) but got \(c)"
                    )
                }
                let d = a - base
                values.append(d)
            }
        }
        self.values = values
    }
}
