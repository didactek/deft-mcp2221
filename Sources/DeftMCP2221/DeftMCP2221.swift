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
    }

    public convenience init(nodeAddress: Int) throws {
        let bus = LibusbHIDAPI()
        let adapter = try! bus.open(idVendor: Self.defaultIdVendor, idProduct: Self.defaultIdProduct)
        try! self.init(adapter: adapter, nodeAddress: nodeAddress)
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
        /// 3.1.10 read data back from the device
        case getData = 0x40
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

    /// Internal: issue write requests in buffer segments until data is exhausted
    func bufferedWrite(data: Data, commandCode: CommandCode) {
        // 3.1.5 I2C WRITE DATA

        var request = makeRequest(commandCode: commandCode, length: data.count, forWriting: true)

        var bytesWritten = 0
        while bytesWritten < data.count {
            let chunkCount = min(60, data.count - bytesWritten)
            request.replaceSubrange(4...(4 + chunkCount), with: data[bytesWritten ..< (bytesWritten + chunkCount)])
            try! adapter.write(packet: request)
            let response = try! adapter.read()
            guard request[0] == response[0] else {
                fatalError("response does not match request")
            }
//            let responseCode = response[1] // Table 3-2
//            guard responseCode == 0 else {
//                fatalError("non-successful response to write (\(responseCode))")
//            }
            bytesWritten += chunkCount
        }
    }

    /// I2C operation
    public func write(data: Data) {
        bufferedWrite(data: data, commandCode: .writeData)
    }

    /// Internal: issue repeated requests until response data fills expected count
    func bufferedRead(commandCode: CommandCode, count: Int) -> Data {
        let requestPacket = makeRequest(commandCode: commandCode, length: count, forWriting: false)

        try! adapter.write(packet: requestPacket)
        let response = try! adapter.read()
        guard requestPacket[0] == response[0] else {
            fatalError("response does not match request")
        }
//        guard requestPacket[1] == 0 else {
//            fatalError("result code \(requestPacket[1]): device busy?")
//        }

        var result = Data()
        let requestData = Data([CommandCode.getData.rawValue]) + Data(count: 63)

        while result.count < count {
            try! adapter.write(packet: requestData)
            let response = try! adapter.read()
            guard requestData[0] == response[0] else {
                fatalError("response does not match request")
            }
            guard response[1] == 0 else {
                fatalError("getData unsuccessful")
            }
            let readCount = Int(response[3])
            guard readCount <= 60 else {
                fatalError("signal to ignore data")
            }
            result.append(response.dropFirst(4).prefix(readCount))
        }
        return result
    }

    /// I2C operation
    public func read(count: Int) -> Data {
        return bufferedRead(commandCode: .readData, count: count)
    }

    /// I2C operation
    public func writeAndRead(sendFrom: Data, receiveCount: Int) -> Data {
        bufferedWrite(data: sendFrom, commandCode: .writeNoStop)
        return bufferedRead(commandCode: .readDataRepeatedStart, count: receiveCount)
    }

    public func supportsClockStretching() -> Bool {
        return true
    }
}
