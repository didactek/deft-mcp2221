//
//  LibusbHIDAPI.swift
//
//
//  Created by Kit Transue on 2021-05-03.
//  Copyright © 2021 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//


import Foundation
import CHidApi

public class LibusbHIDAPI {
    public func open(idVendor: Int, idProduct: Int) throws -> HIDDevice {
        let deviceHandlePtr = hid_open(UInt16(idVendor), UInt16(idProduct), nil)
        guard let deviceHandle = deviceHandlePtr else {
            // FIXME: throw
            fatalError("device not opened")
        }
        return try HIDDevice(handle: deviceHandle)
    }

    public init() {
    }
}