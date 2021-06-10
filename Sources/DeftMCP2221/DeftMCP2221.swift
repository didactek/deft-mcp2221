//
//  DeftMCP2221.swift
//
//
//  Created by Kit Transue on 2021-05-02.
//  Copyright © 2021 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//


import Foundation
import DeftLog
import LibusbHIDAPI

let logger = DeftLog.logger(label: "com.didactek.deft-mcp2221.usb")

enum MCP2221Error: Error {
    case defaultAdapterNotFound
    case responseError(String)
    case operationInvalidated
}

public class DeftMCP2221 {
    /// USBVIDH REGISTER and USBVIDL REGISTER (Register 1-6 and 1-5)
    public static let defaultIdVendor = 0x04d8
    /// USBPIDH REGISTER and USBPIDL REGISTER (Register 1-8 and 1-7)
    public static let defaultIdProduct = 0x00dd

    /// Singleton connection to the adapter, if found using default Vendor and Product IDs.
    public static var defaultAdapter: HIDDevice? = {
        let bus = LibusbHIDAPI()
        let adapter = try? bus.open(idVendor: DeftMCP2221.defaultIdVendor,
                                    idProduct: DeftMCP2221.defaultIdProduct)
        guard let found = adapter else {
            logger.debug("No MCP2221 adapter found at default address.")
            return nil
        }
        logger.debug("MCP2221 adapter ready at default address.")
        return found
    }()

    let adapter: HIDDevice
    let nodeAddress: Int

    /// - parameter nodeAddress: 7-bit address.
    public init(adapter: HIDDevice, nodeAddress: Int) throws {
        self.adapter = adapter
        self.nodeAddress = nodeAddress

        // I2C mode is always on. Clock is good at default.
        // Looking at 1.4.2 CHIP SETTINGS MAP: configuration of other pins,
        // but not I2C.
        // Chip settings are used for
        // - GPIO pin configuration
        // - DAC default output values (if enabled)
        // - interrupt generation
        // - altering device identification (vendor/product IDs; serial number)
        // - passcode protecting configuration

        logger.trace("Link set up for \(nodeAddress)")
    }

    /// Clear any pending/failed I2C operations.
    ///
    /// If any I2C operation fails, the operation needs to be cleared before the MCP2221 can perform
    /// any subsequent I2C operation.
    func resetI2C() throws {
        // FIXME: should this *not* throw? Instead check that it is successful and
        // log a very high level warning if it is not? Then callers would more easily propagate
        // the original error value
        var packet = Data(count: 64)
        packet[0] = 0x10  // 3.1.1 Status / Set parameters
        packet[2] = 0x10  // Cancel current I2C transfer

        try adapter.write(packet: packet)
        let status = try adapter.read()
        if status[2] == 0x10 {
            // The documentation says "may need a few hundred microseconds to settle", but I
            // don't think that's true. I've never seen a successful cancelation after this
            // result, despite sleeps and retries. I suspect this code actually means
            // "no pending I2C to cancel."
            logger.warning("I2C cancelation incomplete. I2C subsystem may be hung.")
            // statusTrace()
            Thread.sleep(forTimeInterval: 0.02)
        } else {
            logger.trace("I2C reset.")
        }
    }

    func statusTrace() throws {
        var packet = Data(count: 64)
        packet[0] = 0x10  // 3.1.1 Status / Set parameters

        try adapter.write(packet: packet)
        let response = try adapter.read()
        guard packet[0] == response[0] else {
            fatalError("response packet type does not match request packet type")
        }
        let responseCode = response[1] // Table 3-2
        guard responseCode == 0 else {
            throw MCP2221Error.responseError("non-successful response to Query/Set Parameter (\(responseCode))")
        }

        logger.trace("Clock divisor adjustment acknowledgement: 0x\(String(response[3], radix: 16)) (0x21: change not made; 0x20: change made)")
        logger.trace("Current clock divider is \(response[14])")
        logger.trace("Internal data buffer is \(response[13])")
        logger.trace("Reported requested transfer length: 0x\(String(response[10], radix: 16))\(String(response[9], radix: 16))")
        logger.trace("Reported already transferred: 0x\(String(response[12], radix: 16))\(String(response[11], radix: 16))")
        logger.trace("SCL level is \(String(response[22], radix: 16))")
        logger.trace("SCA level is \(String(response[23], radix: 16))")
        logger.trace("I2C read pending state is \(response[25])")
    }

    public convenience init(nodeAddress: Int) throws {
        guard let adapter = Self.defaultAdapter else {
            throw MCP2221Error.defaultAdapterNotFound
        }
        try self.init(adapter: adapter, nodeAddress: nodeAddress)
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
    func makeRequest(commandCode: CommandCode, length: Int, forWriting: Bool) -> Data {
        var packet = Data(count: 64)
        packet[0] = commandCode.rawValue

        let (msb, lsb) = length.quotientAndRemainder(dividingBy: 256)
        packet[1] = UInt8(lsb)
        packet[2] = UInt8(msb)

        let address = UInt8(self.nodeAddress) << 1 + (forWriting ? 0 : 1)
        packet[3] = address

        logger.trace("Command packet for node 0x\(String(nodeAddress, radix: 16)); command is \(commandCode)")
        return packet
    }

    /// Internal: issue write requests in buffer segments until data is exhausted
    func bufferedWrite(data: Data, commandCode: CommandCode) throws {
        // 3.1.5 I2C WRITE DATA
        logger.trace("Buffered write of \(data.count) bytes to node \(nodeAddress) using command \(commandCode).")

        var request = makeRequest(commandCode: commandCode, length: data.count, forWriting: true)

        var bytesWritten = 0
        while bytesWritten < data.count {
            let chunkCount = min(60, data.count - bytesWritten)
            request.replaceSubrange(4...(4 + chunkCount), with: data[bytesWritten ..< (bytesWritten + chunkCount)])
            try adapter.write(packet: request)
            let response = try adapter.read()
            guard request[0] == response[0] else {
                fatalError("response does not match request")
            }
            let responseCode = response[1] // Table 3-2
            guard responseCode == 0 else {
                throw MCP2221Error.responseError("non-successful response to write (\(responseCode))")
            }
            bytesWritten += chunkCount
            logger.trace("(chunk success: \(bytesWritten) bytes cumulatively written)")
        }
        logger.trace("Buffered write of \(data.count) done.")
    }

    /// I2C operation.
    /// - Throws on error (usually unexpected NACK). Resets I2C bus to IDLE and adapter to ready.
    public func write(data: Data) throws {
        do {
            try bufferedWrite(data: data, commandCode: .writeData)
        } catch let error {
            try resetI2C()
            throw error
        }
    }

    /// Internal: issue repeated requests until response data fills expected count
    func bufferedRead(commandCode: CommandCode, count: Int) throws -> Data {
        logger.trace("Starting buffered read of \(count) bytes from node \(nodeAddress).")
        let requestPacket = makeRequest(commandCode: commandCode, length: count, forWriting: false)

        try adapter.write(packet: requestPacket)
        let response = try adapter.read()
        guard requestPacket[0] == response[0] else {
            fatalError("response does not match request")
        }
        guard response[1] == 0 else {
            logger.trace("Read result \(response[1]) indicates non-success")
            throw MCP2221Error.responseError("Result code \(response[1]): device busy?")
        }

        var result = Data()
        let requestData = Data([CommandCode.getData.rawValue]) + Data(count: 63)

        while result.count < count {
            try adapter.write(packet: requestData)
            let response = try adapter.read()
            guard requestData[0] == response[0] else {
                fatalError("response does not match request")
            }
            guard response[1] == 0 else {
                logger.trace("Read result \(requestPacket[1]) indicates non-success")
                throw MCP2221Error.responseError("read")
            }
            let readCount = Int(response[3])
            guard readCount <= 60 else {
                logger.trace("Read count \(readCount) indicates non-success")
                throw MCP2221Error.operationInvalidated
            }
            result.append(response.dropFirst(4).prefix(readCount))
        }
        logger.trace("Buffered read returning \(result.count) bytes")
        return result
    }

    /// I2C operation
    /// - Throws on I2C error (usually an unexpected NACK). Resets I2C bus to IDLE and adatper to ready.
    public func read(count: Int) throws -> Data {
        do {
            return try bufferedRead(commandCode: .readData, count: count)
        } catch let error {
            logger.debug("Failed read.")
            try resetI2C()
            throw error
        }
    }

    /// I2C operation
    /// - Throws on I2C error (usually an unexpected NACK). Resets I2C bus to IDLE and adatper to ready.
    public func writeAndRead(sendFrom: Data, receiveCount: Int) throws -> Data {
        do {
            try bufferedWrite(data: sendFrom, commandCode: .writeNoStop)
            return try bufferedRead(commandCode: .readDataRepeatedStart, count: receiveCount)
        } catch let error {
            logger.debug("Failed write+read.")
            try resetI2C()
            throw error
        }
    }

    public func supportsClockStretching() -> Bool {
        return true
    }
}
