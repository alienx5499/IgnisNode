//
//  LocalWiFiIPv4.swift
//  IgnisNode
//
//  Created by PRABAL PATRA on 04/04/26.
//
//  Reads `getifaddrs` for a non-loopback IPv4 on Wi‑Fi (`en0` preferred) to build LAN peer URIs.
//

import Darwin
import Foundation

enum LocalWiFiIPv4 {
    static func primary() -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let current = ptr {
            let interface = current.pointee
            defer { ptr = interface.ifa_next }

            guard let ifaAddr = interface.ifa_addr else { continue }
            guard ifaAddr.pointee.sa_family == UInt8(AF_INET) else { continue }
            let name = String(cString: interface.ifa_name)
            guard name == "en0" || name.hasPrefix("en") else { continue }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let saLen = socklen_t(ifaAddr.pointee.sa_len)
            guard getnameinfo(ifaAddr, saLen, &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 else { continue }
            let ip = String(cString: hostname)
            if ip == "127.0.0.1" || ip.hasPrefix("169.254.") { continue }
            if name == "en0" { return ip }
        }

        ptr = first
        while let current = ptr {
            let interface = current.pointee
            defer { ptr = interface.ifa_next }
            guard let ifaAddr = interface.ifa_addr else { continue }
            guard ifaAddr.pointee.sa_family == UInt8(AF_INET) else { continue }
            let name = String(cString: interface.ifa_name)
            guard name == "en0" || name.hasPrefix("en") else { continue }
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let saLen = socklen_t(ifaAddr.pointee.sa_len)
            guard getnameinfo(ifaAddr, saLen, &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 else { continue }
            let ip = String(cString: hostname)
            if ip != "127.0.0.1", !ip.hasPrefix("169.254.") { return ip }
        }

        return nil
    }
}
