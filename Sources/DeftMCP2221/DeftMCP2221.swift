//
//  DeftMCP2221.swift
//
//
//  Created by Kit Transue on 2021-05-02.
//  Copyright © 2021 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Logging
import LibusbHIDAPI

let logger = Logger(label: "com.didactek.deft-mcp2221-i2c-gpio.usb")

public class DeftMCP2221 {
    /// USBVIDH REGISTER and USBVIDL REGISTER (Register 1-6 and 1-5)
    public static let defaultIdVendor = 0x04d8
    /// USBPIDH REGISTER and USBPIDL REGISTER (Register 1-8 and 1-7)
    public static let defaultIdProduct = 0x00dd

    public init(adapter: HIDDevice) throws {
        // FIXME: implement
        fatalError("Unimplemented")
    }

    public func write(data: Data) {
        // FIXME: implement
        fatalError("Unimplemented")
    }

    public func read(count: Int) -> Data {
        // FIXME: implement
        fatalError("Unimplemented")
    }

    public func writeAndRead(sendFrom: Data, receiveCount: Int) -> Data {
        // FIXME: implement
        fatalError("Unimplemented")
    }

    public func supportsClockStretching() -> Bool {
        // FIXME: implement
        fatalError("Unimplemented")
    }
}
