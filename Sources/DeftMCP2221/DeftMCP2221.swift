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

    let adapter: HIDDevice
    let nodeAddress: Int

    /// - parameter nodeAddress: 7-bit address.
    public init(adapter: HIDDevice, nodeAddress: Int) throws {
        self.adapter = adapter
        self.nodeAddress = nodeAddress

        // FIXME: set to I2C mode
        // Looking at 1.4.2 CHIP SETTINGS MAP: configuration of other pins,
        // but not I2C.
        // Chip settings are used for
        // - GPIO pin configuration
        // - DAC default output values (if enabled)
        // - interrupt generation
        // - altering device identification (vendor/product IDs; serial number)
        // - passcode protecting configuration

        fatalError("Unimplemented")
    }

    enum CommandCode: UInt8 {
        // FIXME: Only those presently needed are represented here

        /// 3.1.5 Start / Write / Stop
        case writeData = 0x90
        /// 3.1.7 Start / Write (no stop)
        case writeNoStop = 0x94
        /// 3.1.8 Start / Read / Stop
        case readData = 0x91
        /// 3.1.9 Repeated-start / Read / Stop
        case readDataRepeatedStart = 0x93
    }

    /// Build a command buffer, populated with command code, I2C operation length, and address
    /// Set bytes 1 and 2 to the low and high bits of a value (reserving offset zero for the command code)
    /// - parameter value: the trasfer  length to encode into the buffer
    func makeRequest(commandCode: CommandCode, length: Int, forWriting: Bool) -> Data{
        var packet = Data(count: 64)
        packet[0] = commandCode.rawValue

        let (msb, lsb) = length.quotientAndRemainder(dividingBy: 256)
        packet[1] = UInt8(lsb)
        packet[2] = UInt8(msb)

        let address = UInt8(self.nodeAddress) << 1 + (forWriting ? 0 : 1)
        packet[3] = address

        return packet
    }

    /// Internal: issue write requests until
    func write(data: Data, commandCode: CommandCode) {
        // 3.1.5 I2C WRITE DATA

        var request = makeRequest(commandCode: commandCode, length: data.count, forWriting: true)

        var bytesWritten = 0
        while bytesWritten < data.count {
            let chunkCount = max(60, data.count - bytesWritten)
            request.replaceSubrange(4...(4 + chunkCount), with: data[bytesWritten ... (bytesWritten + chunkCount)])
            try! adapter.write(packet: request)
            let response = try! adapter.read()
            let responseCode = response[1] // Table 3-2
            guard request[0] == response[0] else {
                fatalError("response does not match request")
            }
            guard responseCode == 0 else {
                fatalError("non-successful response to write (\(responseCode)")
            }
            bytesWritten += chunkCount
        }
    }

    /// I2C operation
    public func write(data: Data) {
        write(data: data, commandCode: .writeData)
    }

    /// Internal: issue repeated requests until response data fills expected count
    func read(commandCode: CommandCode, count: Int) -> Data {
        let requestPacket = makeRequest(commandCode: commandCode, length: count, forWriting: false)

        var result = Data()
        while result.count < count {
            try! adapter.write(packet: requestPacket)
            let response = try! adapter.read()
            guard requestPacket[0] == response[0] else {
                fatalError("response does not match request")
            }
            result.append(response.dropFirst(4))
        }
        return result
    }

    /// I2C operation
    public func read(count: Int) -> Data {
        return read(commandCode: .readData, count: count)
    }

    /// I2C operation
    public func writeAndRead(sendFrom: Data, receiveCount: Int) -> Data {
        write(data: sendFrom, commandCode: .writeNoStop)
        return read(commandCode: .readDataRepeatedStart, count: receiveCount)
    }

    public func supportsClockStretching() -> Bool {
        return true
    }
}
