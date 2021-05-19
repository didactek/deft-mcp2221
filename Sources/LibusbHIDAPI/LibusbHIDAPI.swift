//
//  LibusbHIDAPI.swift
//
//
//  Created by Kit Transue on 2021-05-03.
//  Copyright © 2021 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//


import Foundation
#if canImport(CHidApi)
import CHidApi
#endif
#if canImport(CHidApiLinux)
import CHidApiLinux
#endif


public class LibusbHIDAPI {
    enum HidError: Error {
        case deviceNotOpened
    }
    public func open(idVendor: Int, idProduct: Int) throws -> HIDDevice {
        let deviceHandlePtr = hid_open(UInt16(idVendor), UInt16(idProduct), nil)
        guard let deviceHandle = deviceHandlePtr else {
            throw HidError.deviceNotOpened
        }
        return HIDDevice(handle: deviceHandle)
    }

    public init() {
        // FIXME: (long-term) make this a singleton; add calls to hid_init and hid_exit
    }
}
