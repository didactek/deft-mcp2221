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
import LibusbHIDAPI

do {
    // idVendor: DeftMCP2221.defaultIdVendor
    // idProduct: DeftMCP2221.defaultIdProduct
    let hidAPI = LibusbHIDAPI()
    let device = try! hidAPI.open(idVendor: DeftMCP2221.defaultIdVendor,
                                  idProduct: DeftMCP2221.defaultIdProduct)

    let breakout = try! DeftMCP2221(adapter: device, nodeAddress: 0x40)
}
