//
//  HIDDevice.swift
//
//
//  Created by Kit Transue on 2021-05-03.
//  Copyright © 2021 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CHidApi

public class HIDDevice {
    let deviceHandle: OpaquePointer
    let bufferSize: Int

    /// - parameter bufferSize: Size of reads and writes. Typically needs an extra byte for the report
    /// number.
    public init(handle: OpaquePointer, bufferSize: Int = 65) throws {
        self.deviceHandle = handle
        self.bufferSize = bufferSize
    }

    /// - parameter packet: Data to be written. If packet is smaller than bufferSize, it will be zero-padded.
    public func write(packet: Data) throws {
        guard packet.count <= bufferSize else {
            fatalError("Requested outgoing packet size (\(packet.count)) is larger than device capability \(bufferSize))")
        }
        var packetCopy = packet + Data(count: bufferSize - packet.count)

        let bytesSent = packetCopy.withUnsafeMutableBytes {
            hid_write(deviceHandle, $0.bindMemory(to: UInt8.self).baseAddress, bufferSize)
        }
        guard bytesSent == bufferSize else {
            fatalError("Only \(bytesSent) of \(bufferSize) written")
        }
    }

    public func read() throws -> Data {
        var buffer = Data(count: bufferSize)
        let bytesReceived = buffer.withUnsafeMutableBytes {
            hid_read(deviceHandle, $0.bindMemory(to: UInt8.self).baseAddress, bufferSize)
        }
        guard bytesReceived == bufferSize else {
            fatalError("Only \(bytesReceived) of \(bufferSize) read")
        }
        return buffer
    }
}
