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

            let app = NSRunningApplication(
                processIdentifier: pid
            )

            activeApps.append(
                MicApp(
                    pid: pid,
                    appName: app?.localizedName ?? "Unknown",
                    bundleID: app?.bundleIdentifier ?? "Unknown"
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
