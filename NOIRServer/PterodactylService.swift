import Foundation
import SwiftUI

@MainActor
class ServerStore: ObservableObject {
    @Published var servers: [GameServer] = []
    @Published var isArabic: Bool = true
    @Published var isDemoMode: Bool = true
    @Published var panelURL: String = UserDefaults.standard.string(forKey: "panelURL") ?? ""
    @Published var apiKey: String = UserDefaults.standard.string(forKey: "apiKey") ?? ""
    @Published var isLoading: Bool = false
    @Published var toastMessage: String? = nil
    
    init() {
        loadDemoServers()
    }
    
    func saveCredentials(url: String, key: String, demo: Bool) {
        self.panelURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        self.apiKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isDemoMode = demo
        UserDefaults.standard.set(self.panelURL, forKey: "panelURL")
        UserDefaults.standard.set(self.apiKey, forKey: "apiKey")
        
        if demo {
            loadDemoServers()
        } else {
            Task { await fetchServersFromAPI() }
        }
    }
    
    func loadDemoServers() {
        servers = [
            GameServer(
                id: "ark-01",
                name: "NOIR ARK Ascended x5",
                game: .arkAscended,
                ipAddress: "144.24.180.52",
                port: 7777,
                status: .running,
                cpuUsage: 42.5,
                ramUsedGB: 12.8,
                ramTotalGB: 16.0,
                playersOnline: 4,
                config: NitradoStyleConfig(
                    primaryRate: 5.0,
                    secondaryRate: 10.0,
                    xpMultiplier: 3.0,
                    thirdRate: 20.0,
                    weightOrSlots: 5.0,
                    maxPlayers: 20,
                    pvpEnabled: true,
                    mods: [
                        GameMod(modId: "928793", name: "Super Cryo Storage"),
                        GameMod(modId: "929110", name: "Awesome SpyGlass!"),
                        GameMod(modId: "930170", name: "Automated Ark")
                    ]
                ),
                consoleLogs: [
                    "[NOIR Engine] ARK: Survival Ascended Server Initialized",
                    "[Mods] Loaded 3 CurseForge Mods: 928793, 929110, 930170",
                    "[Network] Listening on 0.0.0.0:7777 - Ready"
                ]
            ),
            GameServer(
                id: "mc-01",
                name: "NOIR Craft SMP",
                game: .minecraft,
                ipAddress: "144.24.180.52",
                port: 25565,
                status: .running,
                cpuUsage: 14.2,
                ramUsedGB: 3.4,
                ramTotalGB: 6.0,
                playersOnline: 2,
                config: NitradoStyleConfig(
                    primaryRate: 2.0,
                    secondaryRate: 1.0,
                    xpMultiplier: 2.0,
                    thirdRate: 1.0,
                    weightOrSlots: 10.0,
                    maxPlayers: 30,
                    pvpEnabled: true,
                    mods: [
                        GameMod(modId: "GeyserMC", name: "Bedrock Crossplay"),
                        GameMod(modId: "EssentialsX", name: "Admin Commands")
                    ]
                ),
                consoleLogs: [
                    "[PaperMC] Server started on port 25565",
                    "[GeyserMC] Bedrock players enabled"
                ]
            ),
            GameServer(
                id: "rust-01",
                name: "NOIR Rust x3",
                game: .rust,
                ipAddress: "144.24.180.52",
                port: 28015,
                status: .offline,
                cpuUsage: 0.0,
                ramUsedGB: 0.0,
                ramTotalGB: 8.0,
                playersOnline: 0,
                config: NitradoStyleConfig(
                    primaryRate: 3.0,
                    secondaryRate: 2.0,
                    xpMultiplier: 2.0,
                    thirdRate: 3.0,
                    weightOrSlots: 3.0,
                    maxPlayers: 50,
                    pvpEnabled: true,
                    mods: [
                        GameMod(modId: "GatherManager", name: "x3 Gather Rate"),
                        GameMod(modId: "StackSize", name: "High Stack Sizes")
                    ]
                ),
                consoleLogs: [
                    "[Rust] Server offline."
                ]
            )
        ]
    }
    
    func fetchServersFromAPI() async {
        guard !panelURL.isEmpty, !apiKey.isEmpty,
              let url = URL(string: "\(panelURL)/api/client") else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let list = json["data"] as? [[String: Any]] {
                var fetched: [GameServer] = []
                for item in list {
                    if let attr = item["attributes"] as? [String: Any],
                       let id = attr["identifier"] as? String,
                       let name = attr["name"] as? String {
                        let limits = attr["limits"] as? [String: Any]
                        let memMB = limits?["memory"] as? Double ?? 8192
                        let detectedGame: GameType = GameType.allCases.first {
                            name.lowercased().contains($0.rawValue.prefix(4).lowercased())
                        } ?? .arkAscended
                        fetched.append(GameServer(
                            id: id,
                            name: name,
                            game: detectedGame,
                            ipAddress: URL(string: panelURL)?.host ?? "0.0.0.0",
                            port: detectedGame.defaultPort,
                            status: .running,
                            cpuUsage: 15.0,
                            ramUsedGB: 4.2,
                            ramTotalGB: memMB / 1024.0,
                            playersOnline: 0,
                            config: NitradoStyleConfig(),
                            consoleLogs: ["[API] Connected to Pterodactyl Node: \(id)"]
                        ))
                    }
                }
                if !fetched.isEmpty { self.servers = fetched }
            }
        } catch {
            showToast(isArabic ? "تعذر الاتصال بالسيرفر" : "Connection failed")
        }
    }
    
    func sendPowerAction(serverId: String, action: String) {
        guard let idx = servers.firstIndex(where: { $0.id == serverId }) else { return }
        
        if isDemoMode {
            if action == "start" {
                servers[idx].status = .running
                servers[idx].cpuUsage = 36.0
                servers[idx].ramUsedGB = servers[idx].ramTotalGB * 0.72
                servers[idx].consoleLogs.append("[NOIR] Server started with updated settings.")
            } else if action == "stop" {
                servers[idx].status = .offline
                servers[idx].cpuUsage = 0
                servers[idx].ramUsedGB = 0
                servers[idx].playersOnline = 0
                servers[idx].consoleLogs.append("[NOIR] Server stopped.")
            } else if action == "restart" {
                servers[idx].status = .starting
                servers[idx].consoleLogs.append("[NOIR] Restarting & applying mods...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    self.servers[idx].status = .running
                    self.servers[idx].consoleLogs.append("[NOIR] Server Online!")
                }
            }
            showToast(isArabic ? "تم تنفيذ: \(action)" : "Executed: \(action)")
            return
        }
        
        Task {
            guard let url = URL(string: "\(panelURL)/api/client/servers/\(serverId)/power") else { return }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try? JSONSerialization.data(withJSONObject: ["signal": action])
            _ = try? await URLSession.shared.data(for: req)
            showToast(isArabic ? "تم إرسال أمر \(action)" : "Sent \(action)")
        }
    }
    
    func sendCommand(serverId: String, command: String) {
        guard !command.isEmpty,
              let idx = servers.firstIndex(where: { $0.id == serverId }) else { return }
        servers[idx].consoleLogs.append("> \(command)")
        
        if isDemoMode {
            servers[idx].consoleLogs.append("[Server] Executed: \(command)")
            return
        }
        
        Task {
            guard let url = URL(string: "\(panelURL)/api/client/servers/\(serverId)/command") else { return }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try? JSONSerialization.data(withJSONObject: ["command": command])
            _ = try? await URLSession.shared.data(for: req)
        }
    }
    
    func applyNitradoConfig(serverId: String, config: NitradoStyleConfig) {
        guard let idx = servers.firstIndex(where: { $0.id == serverId }) else { return }
        servers[idx].config = config
        
        let modIds = config.mods.filter { $0.isEnabled }.map { $0.modId }.joined(separator: ",")
        let configPayload = """
        [ServerSettings]
        PrimaryRateMultiplier=\(String(format: "%.1f", config.primaryRate))
        SecondaryRateMultiplier=\(String(format: "%.1f", config.secondaryRate))
        XPMultiplier=\(String(format: "%.1f", config.xpMultiplier))
        ThirdRateMultiplier=\(String(format: "%.1f", config.thirdRate))
        WeightOrStackMultiplier=\(String(format: "%.1f", config.weightOrSlots))
        MaxPlayers=\(config.maxPlayers)
        ServerPVE=\(!config.pvpEnabled)
        ServerPassword=\(config.serverPassword)
        ActiveMods=\(modIds)
        """
        
        servers[idx].consoleLogs.append("[Nitrado Config] Applied rates (x\(Int(config.primaryRate))) & \(config.mods.filter{$0.isEnabled}.count) mods.")
        
        if !isDemoMode {
            let targetFile = servers[idx].game == .arkAscended
                ? "%2FShooterGame%2FSaved%2FConfig%2FLinuxServer%2FGameUserSettings.ini"
                : "%2Fserver.properties"
            Task {
                guard let url = URL(string: "\(panelURL)/api/client/servers/\(serverId)/files/write?file=\(targetFile)") else { return }
                var req = URLRequest(url: url)
                req.httpMethod = "POST"
                req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                req.setValue("text/plain", forHTTPHeaderField: "Content-Type")
                req.httpBody = configPayload.data(using: .utf8)
                _ = try? await URLSession.shared.data(for: req)
            }
        }
        
        showToast(isArabic ? "تم حفظ الإعدادات والمودات بنجاح!" : "Settings & Mods Saved!")
    }
    
    func createNewServer(name: String, game: GameType, ramGB: Double) {
        let newServer = GameServer(
            id: "srv-\(Int.random(in: 100...999))",
            name: name,
            game: game,
            ipAddress: "144.24.180.52",
            port: game.defaultPort + Int.random(in: 0...15),
            status: .running,
            cpuUsage: 18.0,
            ramUsedGB: ramGB * 0.45,
            ramTotalGB: ramGB,
            playersOnline: 0,
            config: NitradoStyleConfig(),
            consoleLogs: ["[NOIR] Deployed \(game.rawValue) server with \(Int(ramGB))GB RAM."]
        )
        servers.append(newServer)
        showToast(isArabic ? "تم إنشاء سيرفر \(game.rawValue)" : "Created \(game.rawValue)")
    }
    
    func deleteServer(serverId: String) {
        servers.removeAll { $0.id == serverId }
        showToast(isArabic ? "تم حذف السيرفر" : "Server deleted")
    }
    
    func showToast(_ msg: String) {
        toastMessage = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if self.toastMessage == msg { self.toastMessage = nil }
        }
    }
}
