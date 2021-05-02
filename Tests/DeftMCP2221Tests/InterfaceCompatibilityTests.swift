import XCTest
@testable import DeftMCP2221

/// Abbreviated protocol from deft-devices, to which we want to conform without extension:
private protocol LinkI2C {
    func write(data: Data)
    func read(count: Int) -> Data
    func writeAndRead(sendFrom: Data, receiveCount: Int) -> Data
    func supportsClockStretching() -> Bool
}

extension DeftMCP2221 : LinkI2C {
    // no extension work required
}

final class InterfaceCompatibilityTests: XCTestCase {
    func testExample() {
        // Just having compiled assures compatibility.
    }
}
