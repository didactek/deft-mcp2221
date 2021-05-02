# deft-mcp2221-i2c-gpio

A Swift library for using the Microchip MCP2221A USB breakout adapter in I2C applications. and GPIO applications. Uses the deft-simple-usb library for pure-Swift usermode USB support on macOS
or the libusb system library bridged to Swift on Linux.


## Overview

This library provides
- support for a USB-connected MCP2221A device communicating in its HID mode
- deft-devices compatible implementation of I2C read/write/read-and-write, with clock stretching support provided by the adapter
- uses deft-simple-usb for usermode access to the device


## Requirements

- Swift Package Manager
- Swift 5.3+
- macOS or Linux

Mac requirements
- macOS 10.15 (Catalina) or higher

SPM Dependencies
- swift-log
- deft-simple-usb (transitively)

Linux dependencies
- libusb


## Implementation

Based on the [datasheet](https://ww1.microchip.com/downloads/en/DeviceDoc/MCP2221A-Data-Sheet-DS20005565D.pdf).

For non-UART mode, the basic pattern is to send a 64-byte request and get a 64-byte reply.

Formats of the request and response are well-documented in the datasheet. Operations cover
pin and protocol configuration, queries for ADC and GPIO, and high-level I2C operations.

Presumably, request/response is made using USB bulk transfer operations. The datasheet
suggests the device offers two configurations: one for UART and the other presents as HID.
The details of accessing the HID mode are TBD.



## Installation Notes

### Linux device permissions

On Linux, users will not have access to a hot-plugged USB device by default. 
The cleanest way to systematically grant permissions to the device is to set up a udev
rule that adjusts permissions whenever the device is connected.

The paths and group in the template below assume:
- Configuration files are under /etc/udev/rules.d
- The group 'plugdev' exists and includes the user wanting to use the device

Under /etc/udev/rules.d/, create a file (suggested name: "70-gpio-microchip-mcp2221a.rules") with the contents:

    # Microchip MCP2221A USB -> I2C + UART Combo Adapter
    # 2021-05-02 support working with the MCP2221A using Swift deft-mcp221-i2c-gpio library
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="04d8", ATTRS{idProduct}=="00dd", MODE="660", GROUP="plugdev"

eLinux.org has a useful wiki entry on [accessing devices without sudo](https://elinux.org/Accessing_Devices_without_Sudo).
