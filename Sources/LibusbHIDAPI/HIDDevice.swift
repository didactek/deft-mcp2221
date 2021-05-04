//
//  HIDDevice.swift
//
//
//  Created by Kit Transue on 2021-05-03.
//  Copyright © 2021 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

public class HIDDevice {
    public init(handle: OpaquePointer) throws {
    }

    public func write(packet: Data) throws {
    }

    public func read() throws -> Data {
        // FIXME: implement
        fatalError("unimplemented")
    }
}
