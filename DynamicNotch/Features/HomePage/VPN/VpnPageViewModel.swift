//
//  VpnPageViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 6/19/26.
//

import Foundation
import Combine
import SwiftUI

struct VPNConfiguration: Identifiable, Hashable {
    let id: String
    let name: String
    let isConnected: Bool
    let type: String
    let bundleID: String?
}

@MainActor
final class VpnPageViewModel: ObservableObject {
    @Published var vpns: [VPNConfiguration] = []
    @Published var isLoading: Bool = false
    @Published var connectionError: String? = nil
    @Published var connectedAt: Date? = nil
    
    private var refreshTimer: Timer?
    
    func startMonitoring() {
        refresh()
        // Refresh every 3 seconds to update statuses dynamically
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.refresh()
            }
        }
    }
    
    func stopMonitoring() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    func refresh() {
        isLoading = true
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            let list = self.fetchVPNs()
            await MainActor.run {
                self.vpns = list
                self.isLoading = false
                
                // Track connection start date
                let selectedID = UserDefaults.standard.string(forKey: "settings.vpn.selectedID") ?? ""
                if let selectedVpn = list.first(where: { $0.id == selectedID }) {
                    if selectedVpn.isConnected {
                        if self.connectedAt == nil {
                            self.connectedAt = Date()
                        }
                    } else {
                        self.connectedAt = nil
                    }
                } else if let activeVpn = list.first(where: { $0.isConnected }) {
                    // Fallback to active VPN
                    if self.connectedAt == nil {
                        self.connectedAt = Date()
                    }
                } else {
                    self.connectedAt = nil
                }
            }
        }
    }
    
    nonisolated private func fetchVPNs() -> [VPNConfiguration] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/scutil")
        process.arguments = ["--nc", "list"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            
            if let output = String(data: data, encoding: .utf8) {
                return self.parseVPNList(from: output)
            }
        } catch {
            print("Failed to run scutil --nc list: \(error)")
        }
        return []
    }
    
    nonisolated private func parseVPNList(from output: String) -> [VPNConfiguration] {
        var vpns: [VPNConfiguration] = []
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            guard let uuidRange = line.range(of: "\\b[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\\b", options: .regularExpression) else {
                continue
            }
            let uuid = String(line[uuidRange])
            let isConnected = line.contains("(Connected)")
            
            var name = ""
            if let firstQuote = line.firstIndex(of: "\""),
               let lastQuote = line.lastIndex(of: "\""),
               firstQuote < lastQuote {
                let nextIndex = line.index(after: firstQuote)
                name = String(line[nextIndex..<lastQuote])
            } else {
                name = uuid
            }
            
            var type = "VPN"
            if let firstQuote = line.firstIndex(of: "\""), uuidRange.upperBound < firstQuote {
                let typeStr = line[uuidRange.upperBound..<firstQuote].trimmingCharacters(in: .whitespacesAndNewlines)
                if !typeStr.isEmpty {
                    type = typeStr
                }
            }
            
            // Extract bundle ID if present (e.g. inside parentheses in the type after UUID)
            var bundleID: String? = nil
            let substringAfterUUID = String(line[uuidRange.upperBound...])
            if let openParen = substringAfterUUID.firstIndex(of: "("),
               let closeParen = substringAfterUUID.firstIndex(of: ")"),
               openParen < closeParen {
                let content = String(substringAfterUUID[substringAfterUUID.index(after: openParen)..<closeParen]).trimmingCharacters(in: .whitespacesAndNewlines)
                if content.contains(".") {
                    bundleID = content
                }
            }
            
            vpns.append(VPNConfiguration(id: uuid, name: name, isConnected: isConnected, type: type, bundleID: bundleID))
        }
        return vpns
    }
    
    func toggleVPN(_ vpn: VPNConfiguration) {
        let action = vpn.isConnected ? "stop" : "start"
        let uuid = vpn.id
        
        isLoading = true
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/scutil")
            process.arguments = ["--nc", action, uuid]
            
            let errorPipe = Pipe()
            process.standardError = errorPipe
            process.standardOutput = Pipe()
            
            do {
                try process.run()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                
                let errorStr = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                
                await MainActor.run {
                    if let err = errorStr, !err.isEmpty {
                        self.connectionError = err
                    } else {
                        self.connectionError = nil
                    }
                    self.refresh()
                }
            } catch {
                await MainActor.run {
                    self.connectionError = error.localizedDescription
                    self.refresh()
                }
            }
        }
    }
}
