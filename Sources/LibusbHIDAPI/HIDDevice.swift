//
//  HIDDevice.swift
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

public class HIDDevice {
    enum HIDError: Error {
        case incompleteWrite(String)
        case incompleteRead(String)
    }

    let deviceHandle: OpaquePointer
    let bufferSize: Int

    /// - parameter bufferSize: Size of reads and writes. Typically needs an extra byte for the report
    /// number.
    public init(handle: OpaquePointer, bufferSize: Int = 64) {
        self.deviceHandle = handle
        self.bufferSize = bufferSize
    }

    /// - parameter packet: Data to be written. If packet is smaller than bufferSize, it will be zero-padded.
    public func write(packet: Data) throws {
        guard packet.count <= bufferSize else {
            fatalError("Requested outgoing packet size (\(packet.count)) is larger than device capability \(bufferSize))")
        }
        var paddedPacket = packet + Data(count: bufferSize - packet.count)

        let bytesSent = paddedPacket.withUnsafeMutableBytes {
            hid_write(deviceHandle, $0.bindMemory(to: UInt8.self).baseAddress, bufferSize)
        }
        guard bytesSent == bufferSize else {
            throw HIDError.incompleteWrite("Only \(bytesSent) of \(bufferSize) written")
        }
    }

    public func read() throws -> Data {
        var buffer = Data(count: bufferSize)
        let bytesReceived = buffer.withUnsafeMutableBytes {
            hid_read(deviceHandle, $0.bindMemory(to: UInt8.self).baseAddress, bufferSize)
        }
        guard bytesReceived == bufferSize else {
            throw HIDError.incompleteRead("Only \(bytesReceived) of \(bufferSize) read")
        }
        return buffer
    }
}
