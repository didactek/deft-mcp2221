//
//  main.swift
//
//
//  Created by Kit Transue on 2021-05-02.
//  Copyright © 2021 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import DeftLog
import DeftMCP2221
import LibusbHIDAPI

do {
    DeftLog.settings = [ ("com.didactek", .trace) ]
    let hidAPI = LibusbHIDAPI()
    let device = try! hidAPI.open(idVendor: DeftMCP2221.defaultIdVendor,
                                  idProduct: DeftMCP2221.defaultIdProduct)

    let breakout = try! DeftMCP2221(adapter: device, nodeAddress: 0x18) //0x60 == TEA5767; 0x18 == MCP9808
    print(try! breakout.read(count: 1))
}
