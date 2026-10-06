//
//  MicMonitor.swift
//  FocusBear
//
//  Created by Manish Jain on 03/06/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//


final class micMonitor {
    func microphoneStatus() -> MicStatus {

        var processListAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyProcessObjectList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0

        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &processListAddress,
            0,
            nil,
            &dataSize
        )

        guard status == noErr else {
            return MicStatus(isMicOn: false, apps: [])
        }

        let count = Int(dataSize) / MemoryLayout<AudioObjectID>.size

        var processObjects = [AudioObjectID](repeating: 0, count: count)

        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &processListAddress,
            0,
            nil,
            &dataSize,
            &processObjects
        )

        guard status == noErr else {
            return MicStatus(isMicOn: false, apps: [])
        }

        var activeApps: [MicApp] = []

        for processObject in processObjects {

            // Is this process currently recording audio?
            var runningInput: UInt32 = 0
            var runningInputSize =
                UInt32(MemoryLayout<UInt32>.size)

            var inputAddress = AudioObjectPropertyAddress(
                mSelector: kAudioProcessPropertyIsRunningInput,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )

            status = AudioObjectGetPropertyData(
                processObject,
                &inputAddress,
                0,
                nil,
                &runningInputSize,
                &runningInput
            )

            guard status == noErr, runningInput != 0 else {
                continue
            }

            // Get PID
            var pid: pid_t = 0
            var pidSize = UInt32(MemoryLayout<pid_t>.size)

            var pidAddress = AudioObjectPropertyAddress(
                mSelector: kAudioProcessPropertyPID,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )

            status = AudioObjectGetPropertyData(
                processObject,
                &pidAddress,
                0,
                nil,
                &pidSize,
                &pid
            )

            guard status == noErr else {
                continue
            }

            // The capturing process is often a helper (Chrome captures in "Google Chrome Helper"),
            // which NSRunningApplication alone reported as "Unknown" — report 2026-10-06_13-30-40.
            let coreAudioBundleID = stringProperty(processObject, kAudioProcessPropertyBundleID).flatMap { $0.isEmpty ? nil : $0 }
            let owner = MicOwnerResolver.owningApplication(of: pid, coreAudioBundleID: coreAudioBundleID)

            activeApps.append(
                MicApp(
                    pid: pid,
                    appName: owner?.localizedName ?? MicApp.unknownName,
                    bundleID: owner?.bundleIdentifier ?? coreAudioBundleID ?? MicApp.unknownName
                )
            )
        }

        return MicStatus(
            isMicOn: !activeApps.isEmpty,
            apps: activeApps
        )
    }
}
struct MicApp {
    let pid: pid_t
    let appName: String
    let bundleID: String
}

struct MicStatus {
    let isMicOn: Bool
    let apps: [MicApp]
}

extension micMonitor {
    /// Diagnostic only: the current default input device as "name (transport)", e.g.
    /// "WH-CH720N (Bluetooth)" or "MacBook Air Microphone (Built-in)". Used to correlate
    /// meeting-detection misses with the active input route — per-process mic attribution
    /// (`microphoneStatus`) has been observed to miss apps on some Bluetooth inputs.
    func defaultInputDeviceInfo() -> String {
        var deviceID = AudioObjectID(0)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var defaultAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                         &defaultAddress, 0, nil, &size, &deviceID) == noErr else {
            return "unknown-input"
        }
        let name = stringProperty(deviceID, kAudioObjectPropertyName) ?? "unknown"
        return "\(name) (\(transportTypeString(deviceID)))"
    }

    private func stringProperty(_ deviceID: AudioObjectID, _ selector: AudioObjectPropertySelector) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &value) == noErr else { return nil }
        return value as String
    }

    private func transportTypeString(_ deviceID: AudioObjectID) -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var transport = UInt32(0)
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &transport) == noErr else { return "unknown" }
        switch transport {
        case kAudioDeviceTransportTypeBluetooth, kAudioDeviceTransportTypeBluetoothLE: return "Bluetooth"
        case kAudioDeviceTransportTypeBuiltIn: return "Built-in"
        case kAudioDeviceTransportTypeUSB: return "USB"
        case kAudioDeviceTransportTypeVirtual: return "Virtual"
        case kAudioDeviceTransportTypeAggregate: return "Aggregate"
        default: return "other(\(transport))"
        }
    }
}
