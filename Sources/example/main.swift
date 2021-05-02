//
//  main.swift
//
//
//  Created by Kit Transue on 2021-05-02.
//  Copyright © 2021 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import DeftMCP2221
import PortableUSB

do {
    let usbBus = PortableUSB.platformBus()
    let device = try! usbBus.findDevice(idVendor: DeftMCP2221.defaultIdVendor,
                                        idProduct: DeftMCP2221.defaultIdProduct)
    let breakout = try! DeftMCP2221(adapter: device)
}
