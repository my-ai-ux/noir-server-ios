import Foundation
import SwiftUI

@MainActor
class ServerStore: ObservableObject {
    @Published var isAuthenticated: Bool = UserDefaults.standard.bool(forKey: "isAuthenticated")
    @Published var currentRole: UserRole = UserRole(rawValue: UserDefaults.standard.string(forKey: "currentRole") ?? "owner") ?? .owner
    @Published var currentUserName: String = UserDefaults.standard.string(forKey: "currentUserName") ?? "المالك"
    @Published var activePermissions: AccessCode? = nil
    
    @Published var ownerPin: String = UserDefaults.standard.string(forKey: "ownerPin") ?? "0000"
    @Published var friendCodes: [AccessCode] = []
    @Published var servers: [GameServer] = []
    @Published var activityLogs: [ActivityLogItem] = []
    
    @Published var restartingServerId: String? = nil
    @Published var restartCountdown: Int = 0
    private var restartTimer: Timer? = nil
    
    @Published var isArabic: Bool = true
    @Published var isDemoMode: Bool = UserDefaults.standard.object(forKey: "isDemoMode") as? Bool ?? true
    @Published var panelURL: String = UserDefaults.standard.string(forKey: "panelURL") ?? ""
    @Published var apiKey: String = UserDefaults.standard.string(forKey: "apiKey") ?? ""
    @Published var toastMessage: String? = nil
    
    init() {
        loadAllPersistedData()
    }
    
    private func loadAllPersistedData() {
        if let data = UserDefaults.standard.data(forKey: "savedActivePermissions"),
           let decoded = try? JSONDecoder().decode(AccessCode.self, from: data) {
            activePermissions = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: "friendCodes"),
           let decoded = try? JSONDecoder().decode([AccessCode].self, from: data) {
            friendCodes = decoded
        } else {
            friendCodes = [
                AccessCode(id: "f1", friendName: "أخوياي (تعديل وتشغيل)", code: "1122",
                           canPowerControl: true, canEditSettings: true, canManageMods: true, canUseConsole: false)
            ]
        }
        
        if UserDefaults.standard.object(forKey: "hasInitializedServers") != nil {
            if let data = UserDefaults.standard.data(forKey: "savedServersV4"),
               let decoded = try? JSONDecoder().decode([GameServer].self, from: data) {
                servers = decoded
            }
        } else {
            loadDefaultServers()
            UserDefaults.standard.set(true, forKey: "hasInitializedServers")
        }
        
        if let data = UserDefaults.standard.data(forKey: "savedActivityLogs"),
           let decoded = try? JSONDecoder().decode([ActivityLogItem].self, from: data) {
            activityLogs = decoded
        } else {
            logActivity(serverName: "NOIR ARK Ascended x5", action: "تم تهيئة السيرفر وتفعيل Crossplay PC + Console", category: "create")
        }
    }
    
    func persistServers() {
        if let encoded = try? JSONEncoder().encode(servers) {
            UserDefaults.standard.set(encoded, forKey: "savedServersV4")
            UserDefaults.standard.set(true, forKey: "hasInitializedServers")
            UserDefaults.standard.synchronize()
        }
    }
    
    func persistLogs() {
        if let encoded = try? JSONEncoder().encode(activityLogs) {
            UserDefaults.standard.set(encoded, forKey: "savedActivityLogs")
            UserDefaults.standard.synchronize()
        }
    }
    
    func logActivity(serverName: String, action: String, category: String) {
        let item = ActivityLogItem(
            id: UUID().uuidString,
            userName: currentUserName,
            serverName: serverName,
            actionDescription: action,
            timestamp: Date(),
            category: category
        )
        activityLogs.insert(item, at: 0)
        if activityLogs.count > 50 { activityLogs.removeLast() }
        persistLogs()
    }
    
    func login(with code: String) -> Bool {
        let clean = code.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean == ownerPin {
            currentRole = .owner
            currentUserName = isArabic ? "المالك" : "Owner"
            activePermissions = nil
            isAuthenticated = true
            saveSession()
            return true
        }
        
        if let friend = friendCodes.first(where: { $0.code == clean }) {
            currentRole = .friend
            currentUserName = friend.friendName
            activePermissions = friend
            isAuthenticated = true
            saveSession()
            return true
        }
        return false
    }
    
    private func saveSession() {
        UserDefaults.standard.set(isAuthenticated, forKey: "isAuthenticated")
        UserDefaults.standard.set(currentRole.rawValue, forKey: "currentRole")
        UserDefaults.standard.set(currentUserName, forKey: "currentUserName")
        if let perm = activePermissions, let encoded = try? JSONEncoder().encode(perm) {
            UserDefaults.standard.set(encoded, forKey: "savedActivePermissions")
        } else {
            UserDefaults.standard.removeObject(forKey: "savedActivePermissions")
        }
        UserDefaults.standard.synchronize()
    }
    
    func logout() {
        isAuthenticated = false
        activePermissions = nil
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "savedActivePermissions")
        UserDefaults.standard.synchronize()
    }
    
    func updateOwnerPin(newPin: String) {
        guard newPin.count >= 4 else { return }
        ownerPin = newPin
        UserDefaults.standard.set(newPin, forKey: "ownerPin")
        UserDefaults.standard.synchronize()
        showToast(isArabic ? "تم حفظ رمز المالك الجديد" : "Owner PIN Saved")
    }
    
    func addFriendCode(_ access: AccessCode) {
        friendCodes.append(access)
        if let encoded = try? JSONEncoder().encode(friendCodes) {
            UserDefaults.standard.set(encoded, forKey: "friendCodes")
            UserDefaults.standard.synchronize()
        }
        showToast(isArabic ? "تم حفظ رمز \(access.friendName)" : "Code Saved")
    }
    
    func removeFriendCode(id: String) {
        friendCodes.removeAll { $0.id == id }
        if let encoded = try? JSONEncoder().encode(friendCodes) {
            UserDefaults.standard.set(encoded, forKey: "friendCodes")
            UserDefaults.standard.synchronize()
        }
    }
    
    var isOwner: Bool { currentRole == .owner }
    var canPower: Bool { isOwner || (activePermissions?.canPowerControl ?? false) }
    var canEdit: Bool { isOwner || (activePermissions?.canEditSettings ?? false) }
    var canMods: Bool { isOwner || (activePermissions?.canManageMods ?? false) }
    var canConsole: Bool { isOwner || (activePermissions?.canUseConsole ?? false) }
    
    func saveCredentials(url: String, key: String, demo: Bool) {
        self.panelURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        self.apiKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isDemoMode = demo
        UserDefaults.standard.set(self.panelURL, forKey: "panelURL")
        UserDefaults.standard.set(self.apiKey, forKey: "apiKey")
        UserDefaults.standard.set(self.isDemoMode, forKey: "isDemoMode")
        UserDefaults.standard.synchronize()
        
        if !demo {
            Task { await fetchServersFromAPI() }
        }
        showToast(isArabic ? "تم حفظ إعدادات الربط" : "Connection Saved")
    }
    
    func loadDefaultServers() {
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
                config: FullServerConfig(
                    maxPlayers: 20,
                    crossplayEnabled: true,
                    mapName: "TheIsland_WP",
                    mods: [
                        GameMod(modId: "928793", name: "Super Cryo Storage (SCS)",
                                arabicDescription: "كرات تخزين متطورة لحفظ الديناصورات مع ثلاجة تفريخ البيض تلقائياً.",
                                imageURL: "https://media.forgecdn.net/avatars/thumbnails/906/404/256/256/638356649746936221.png"),
                        GameMod(modId: "929110", name: "Awesome SpyGlass!",
                                arabicDescription: "منظار ذكي يعرض نقاط القوة للديناصور قبل ترويضه.",
                                imageURL: "https://media.forgecdn.net/avatars/thumbnails/906/939/256/256/638357627423346032.png")
                    ]
                ),
                consoleLogs: [
                    "[NOIR Engine] ARK: Survival Ascended Server Initialized",
                    "[Crossplay] PC + PS5 + Xbox enabled"
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
                config: FullServerConfig(
                    maxPlayers: 30,
                    crossplayEnabled: true,
                    mapName: "world",
                    mods: [
                        GameMod(modId: "GeyserMC", name: "GeyserMC + Floodgate",
                                arabicDescription: "يسمح للاعبي الجوال والبلايستيشن بالدخول مع لاعبي الكمبيوتر.",
                                imageURL: "https://cdn.modrinth.com/data/wKKOqHrH/icon.png")
                    ]
                ),
                consoleLogs: [
                    "[PaperMC] Server started on port 25565"
                ]
            )
        ]
        persistServers()
    }
    
    func fetchServersFromAPI() async {
        guard !panelURL.isEmpty, !apiKey.isEmpty,
              let url = URL(string: "\(panelURL)/api/client") else { return }
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
                            config: FullServerConfig(),
                            consoleLogs: ["[API] Connected to Pterodactyl Node: \(id)"]
                        ))
                    }
                }
                if !fetched.isEmpty {
                    self.servers = fetched
                    persistServers()
                }
            }
        } catch {
            showToast(isArabic ? "تعذر الاتصال بالسيرفر" : "Connection failed")
        }
    }
    
    func sendPowerAction(serverId: String, action: String) {
        guard canPower, let idx = servers.firstIndex(where: { $0.id == serverId }) else { return }
        let sName = servers[idx].name
        
        if action == "start" {
            servers[idx].status = .running
            servers[idx].cpuUsage = 36.0
            servers[idx].ramUsedGB = servers[idx].ramTotalGB * 0.72
            servers[idx].consoleLogs.append("[\(currentUserName)] Started server.")
            logActivity(serverName: sName, action: "تشغيل السيرفر", category: "power")
        } else if action == "stop" {
            servers[idx].status = .offline
            servers[idx].cpuUsage = 0
            servers[idx].ramUsedGB = 0
            servers[idx].playersOnline = 0
            servers[idx].consoleLogs.append("[\(currentUserName)] Stopped server.")
            logActivity(serverName: sName, action: "إيقاف السيرفر", category: "power")
        } else if action == "restart" {
            servers[idx].status = .starting
            servers[idx].consoleLogs.append("[\(currentUserName)] Restarting server...")
            logActivity(serverName: sName, action: "إعادة تشغيل السيرفر", category: "power")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                if let currentIdx = self.servers.firstIndex(where: { $0.id == serverId }) {
                    self.servers[currentIdx].status = .running
                    self.servers[currentIdx].consoleLogs.append("[NOIR] Server Online!")
                    self.persistServers()
                }
            }
        }
        persistServers()
        
        if !isDemoMode {
            Task {
                guard let url = URL(string: "\(panelURL)/api/client/servers/\(serverId)/power") else { return }
                var req = URLRequest(url: url)
                req.httpMethod = "POST"
                req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                req.httpBody = try? JSONSerialization.data(withJSONObject: ["signal": action])
                _ = try? await URLSession.shared.data(for: req)
            }
        }
        showToast(isArabic ? "تم تنفيذ: \(action)" : "Executed: \(action)")
    }
    
    func sendCommand(serverId: String, command: String) {
        guard canConsole, !command.isEmpty,
              let idx = servers.firstIndex(where: { $0.id == serverId }) else { return }
        servers[idx].consoleLogs.append("> \(command)")
        servers[idx].consoleLogs.append("[Server] Executed: \(command)")
        logActivity(serverName: servers[idx].name, action: "أمر كونسول: \(command)", category: "config")
        persistServers()
        
        if !isDemoMode {
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
    }
    
    func saveConfigAndScheduleRestart(serverId: String, newConfig: FullServerConfig, changesList: [String]) {
        guard let idx = servers.firstIndex(where: { $0.id == serverId }) else { return }
        servers[idx].config = newConfig
        
        let broadcastMsg = "ServerChat ⚠️ تنبيه من الإدارة: تم حفظ تعديلات جديدة! سيعاد تشغيل السيرفر تلقائياً بعد 20 ثانية..."
        servers[idx].consoleLogs.append("[\(currentUserName)] حفظ التعديلات: \(changesList.joined(separator: " | "))")
        servers[idx].consoleLogs.append("[Broadcast] ⚠️ تنبيه داخل السيرفر: بعد 20 ثانية سيسوي السيرفر إعادة تشغيل!")
        
        logActivity(serverName: servers[idx].name, action: changesList.first ?? "تحديث إعدادات السيرفر", category: "config")
        persistServers()
        
        if !isDemoMode {
            sendCommand(serverId: serverId, command: broadcastMsg)
            let fileData = generateConfigFileContent(for: servers[idx])
            Task {
                guard let url = URL(string: "\(panelURL)/api/client/servers/\(serverId)/files/write?file=\(fileData.filename)") else { return }
                var req = URLRequest(url: url)
                req.httpMethod = "POST"
                req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                req.setValue("text/plain", forHTTPHeaderField: "Content-Type")
                req.httpBody = fileData.content.data(using: .utf8)
                _ = try? await URLSession.shared.data(for: req)
            }
        }
        
        start20SecondRestartCountdown(serverId: serverId)
    }
    
    func start20SecondRestartCountdown(serverId: String) {
        restartTimer?.invalidate()
        restartingServerId = serverId
        restartCountdown = 20
        
        restartTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self else { return }
                if self.restartCountdown > 1 {
                    self.restartCountdown -= 1
                    if self.restartCountdown == 10 || self.restartCountdown == 5 {
                        if let idx = self.servers.firstIndex(where: { $0.id == serverId }) {
                            self.servers[idx].consoleLogs.append("[Broadcast] ⚠️ باقي \(self.restartCountdown) ثوانٍ على إعادة التشغيل...")
                        }
                    }
                } else {
                    timer.invalidate()
                    self.restartingServerId = nil
                    self.restartCountdown = 0
                    self.sendPowerAction(serverId: serverId, action: "restart")
                }
            }
        }
    }
    
    func generateConfigFileContent(for server: GameServer) -> (filename: String, content: String) {
        let c = server.config
        let modIds = c.mods.filter { $0.isEnabled }.map { $0.modId }.joined(separator: ",")
        
        switch server.game {
        case .arkAscended:
            let ini = """
            [ServerSettings]
            MaxPlayers=\(c.maxPlayers)
            CrossplayPlatforms=\(c.crossplayEnabled ? "PC,PS5,XSX" : "PC")
            ServerPVE=\(!c.pvpEnabled)
            HarvestAmountMultiplier=\(c.harvestMultiplier)
            TamingSpeedMultiplier=\(c.tamingSpeed)
            XPMultiplier=\(c.xpMultiplier)
            SupplyCrateLootQualityMultiplier=\(c.lootQuality)
            ItemStackSizeMultiplier=\(c.stackSizeMultiplier)
            EggHatchSpeedMultiplier=\(c.eggHatchSpeed)
            BabyMatureSpeedMultiplier=\(c.babyMatureSpeed)
            BabyImprintAmountMultiplier=\(c.babyImprintMultiplier)
            PerLevelStatsMultiplier_Player[7]=\(c.playerWeight)
            PerLevelStatsMultiplier_DinoTamed[7]=\(c.dinoWeight)
            PerLevelStatsMultiplier_DinoTamed[8]=\(c.dinoDamage)
            ForceAllowCaveFlyers=\(c.allowCaveFlyers)
            ShowMapPlayerLocation=\(c.showMapPlayerLocation)
            AllowThirdPersonPlayer=\(c.allowThirdPerson)
            DisableStructureDecayPvE=\(c.disableStructureDecay)
            bUseBattlEye=\(c.allowBattlEye)
            ServerPassword=\(c.serverPassword)
            ActiveMods=\(modIds)
            [MessageOfTheDay]
            Message=\(c.motdMessage)
            """
            return ("%2FShooterGame%2FSaved%2FConfig%2FLinuxServer%2FGameUserSettings.ini", ini)
            
        case .minecraft:
            let props = """
            max-players=\(c.maxPlayers)
            gamemode=\(c.mcGameMode)
            difficulty=\(c.mcDifficulty)
            pvp=\(c.pvpEnabled)
            online-mode=\(c.mcOnlineMode)
            allow-nether=\(c.mcAllowNether)
            enable-command-block=\(c.mcEnableCommandBlock)
            view-distance=\(c.mcViewDistance)
            motd=\(c.motdMessage)
            """
            return ("%2Fserver.properties", props)
            
        default:
            return ("%2Fserver.cfg", "MaxPlayers=\(c.maxPlayers)\nPvP=\(c.pvpEnabled)\nMOTD=\(c.motdMessage)")
        }
    }
    
    func createNewServer(name: String, game: GameType, ramGB: Double, maxPlayers: Int, crossplay: Bool) {
        guard isOwner else { return }
        var defaultConfig = FullServerConfig()
        defaultConfig.maxPlayers = maxPlayers
        defaultConfig.crossplayEnabled = crossplay
        if game == .minecraft { defaultConfig.mapName = "world" }
        if game == .fivem { defaultConfig.maxPlayers = max(maxPlayers, 64) }
        
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
            config: defaultConfig,
            consoleLogs: ["[NOIR] Deployed \(game.rawValue) | Max Players: \(defaultConfig.maxPlayers)"]
        )
        servers.append(newServer)
        persistServers()
        logActivity(serverName: name, action: "إنشاء سيرفر \(game.rawValue)", category: "create")
        showToast(isArabic ? "تم إنشاء وحفظ سيرفر \(game.shortBadge)" : "Created \(game.shortBadge)")
    }
    
    func deleteServer(serverId: String) {
        guard isOwner else { return }
        let deletedName = servers.first(where: { $0.id == serverId })?.name ?? "Server"
        servers.removeAll { $0.id == serverId }
        persistServers()
        logActivity(serverName: deletedName, action: "حذف السيرفر نهائياً", category: "power")
        showToast(isArabic ? "تم حذف السيرفر نهائياً" : "Server deleted")
    }
    
    func showToast(_ msg: String) {
        toastMessage = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if self.toastMessage == msg { self.toastMessage = nil }
        }
    }
}
