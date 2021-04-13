import XCTest
@testable import SwiftMindstorms

final class SwiftMindstormsTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SwiftMindstorms().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
