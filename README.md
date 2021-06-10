# deft-mcp2221

A Swift library for using the Microchip MCP2221A USB breakout adapter in I2C applications. Uses the
[libusb HID API](https://github.com/libusb/hidapi) system library bridged to Swift to interface with the drivers provided by the host OS.

## Overview

This library provides
- support for a USB-connected MCP2221A device communicating in its HID mode
- deft-devices compatible implementation of I2C read/write/read-and-write, with clock stretching support provided by the adapter
- uses libusb/hidapi for usermode access to the device


## Requirements

- Swift Package Manager
- Swift 5.3+
- macOS or Linux

Mac requirements
- macOS 10.15 (Catalina) or higher
- brew (for installing hidapi)
- hidapi (to link with)
- pkg-config (to notify SPM where to find the hidapi library)

SPM Dependencies
- deft-log (transitively: swift-log)

Linux dependencies
- libhidapi-dev


## Usage

### Communicating with an I2C device

### Logging

Loggers are instantiated using the [deft-log](https://github.com/didactek/deft-log.git) library
using the label prefix `com.didactek.deft-mcp2221`.


## The Device

### I2C

The device offers two configurations (a "combo adapter"): one for UART and the other
(for I2C, GPIO, and ADC/DAC) presents as HID.

The MCP2221 provides a high-level API for working with I2C on dedicated pins. Clock stretching is supported.

Built-in commands support formatting start/repeated-start/stop frames. Commands are issued via
HID read/write. For data transfer operations, 60 bytes of data is encoded in the 64 byte HID packet.

### Quirks

- It appears that putting some load on the 5V pin makes the device fail to initialize when connected
to the bus. Diagnose by asking host OS to enumerate USB devices. Taking the load off the 5V pin 
temporarily causes the device to connect to the host OS: reconnecting load works from then on.
This could be an issue with power-on current request and it might be that changing some of the
power-on defaults could fix things.

- If an I2C command returns an error code, the bus will be invalidated and subsequent operations
will fail until the bus is reset.


## Implementation

Based on the [datasheet](https://ww1.microchip.com/downloads/en/DeviceDoc/MCP2221A-Data-Sheet-DS20005565D.pdf).

For non-UART mode, the basic pattern is to send a 64-byte request and get a 64-byte reply.

Formats of the request and response are well-documented in the datasheet. Operations cover
pin and protocol configuration, queries for ADC and GPIO, and high-level I2C operations.

### HID vs IOUSBHost

On macOS, the HID side of the combo adapter is bound to a system driver (AppleUserUSBHostHIDDevice), and attempts to open
the interface as usermode USB are rebuffed with (slightly formatted):

    Error Domain=IOUSBHostErrorDomain Code=-536870203
    "Failed to create IOUSBHostObject."
    UserInfo={NSLocalizedRecoverySuggestion=Another client likely has exclusive access., 
    NSLocalizedDescription=Failed to create IOUSBHostObject., NSLocalizedFailureReason=Exclusive open of usb object failed.}

using the deft-simple-usb package, or simply:

  Access denied (insufficient permissions)

using libusb.

These errors should be interpreted as a reminder that the system makes the
device available to userspace applications through the HID API.

## libusb/hidapi

Swift doesn't yet appear to recommend a framework for accessing HID. The IOHIDManager interface seems to be the
way to access HID, and it is Objective-C and part of IOKit. (Note the documentation for IOKit suggests it has been replaced
by DriverKit, but this is only true for the kernel-mode facets of IOKit.
Usermode access to HID devices remains possible in Catalina and beyond.)

This implementation uses hidapi for its portability and its compact interface. (The macOS hidapi wraps the IOKit frameworks mentioned above.)
A future version should move to a framework based implementation, especially if an idiomatic Swift API becomes
available. A framework-based implementation would eliminate the dependence on brew and additional components, which would
simplify use of this package.


## Installation Notes

### Linux device permissions

On Linux, deft-mcp2221 uses the libusb backend for hidapi.
Users do not have access to a hot-plugged USB device by default; permission needs to be configured.
The cleanest way to systematically grant permissions to the device is to set up a udev
rule that adjusts permissions whenever the device is connected.

The paths and group in the template below assume:
- Configuration files are under /etc/udev/rules.d
- The group 'plugdev' exists and includes the user wanting to use the device

Under /etc/udev/rules.d/, create a file (suggested name: "70-gpio-microchip-mcp2221a.rules") with the contents:

    # Microchip MCP2221A USB -> I2C + UART Combo Adapter
    # 2021-05-02 support working with the MCP2221A using Swift deft-mcp221-i2c-gpio library
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04d8", ATTRS{idProduct}=="00dd", GROUP="plugdev"

eLinux.org has a useful wiki entry on [accessing devices without sudo](https://elinux.org/Accessing_Devices_without_Sudo).
