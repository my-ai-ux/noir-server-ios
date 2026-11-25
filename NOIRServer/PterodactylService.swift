import Foundation
import SwiftUI

@MainActor
class ServerStore: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentRole: UserRole = .owner
    @Published var currentUserName: String = "المالك"
    @Published var activePermissions: AccessCode? = nil
    
    @Published var ownerPin: String = UserDefaults.standard.string(forKey: "ownerPin") ?? "0000"
    @Published var friendCodes: [AccessCode] = []
    
    @Published var servers: [GameServer] = []
    @Published var isArabic: Bool = true
    @Published var isDemoMode: Bool = true
    @Published var panelURL: String = UserDefaults.standard.string(forKey: "panelURL") ?? ""
    @Published var apiKey: String = UserDefaults.standard.string(forKey: "apiKey") ?? ""
    @Published var toastMessage: String? = nil
    
    // متجر مودات ARK: Survival Ascended الجاهزة مع وصف عربي مترجم
    let arkModsCatalog: [StoreModItem] = [
        StoreModItem(id: "928793", name: "Super Cryo Storage (SCS)", category: "تخزين",
                     arabicDescription: "كرات تخزين متطورة لحفظ الديناصورات مع إمكانية تفريخ البيض تلقائياً وتوليد الموارد داخل الثلاجة.",
                     englishDescription: "Advanced cryopods with auto-incubation and passive resource generation."),
        StoreModItem(id: "929110", name: "Awesome SpyGlass!", category: "أدوات",
                     arabicDescription: "منظار ذكي يعرض لك نقاط القوة (Stats) للديناصور البري قبل ترويضه، ومستوى الترويض والأكل المطلوب.",
                     englishDescription: "Shows wild dino stat points, torpor, and taming food requirements."),
        StoreModItem(id: "930170", name: "Automated Ark (AA)", category: "أتمتة",
                     arabicDescription: "نظام ذكي يسحب الموارد تلقائياً من الديناصورات ويوزعها على الصناديق والأفران بدون تعب النقل اليدوي.",
                     englishDescription: "Automates resource pulling, sorting, and crafting stations."),
        StoreModItem(id: "928597", name: "Dino Depot", category: "ديناصورات",
                     arabicDescription: "بديل احترافي للكرايو بود مع محطة تجميع تلقائية لصغار الديناصورات فور ولادتها.",
                     englishDescription: "Dino storage balls with newborn auto-capture terminals."),
        StoreModItem(id: "929785", name: "TG Stacking Mod 10000-90", category: "موارد",
                     arabicDescription: "يرفع سعة تكديس الموارد (الخشب، الحجر، اللحم) إلى 10,000 حبة ويقلل وزنها بنسبة 90%.",
                     englishDescription: "Increases item stack sizes to 10,000 and reduces weight by 90%."),
        StoreModItem(id: "932365", name: "Utilities Plus", category: "أدوات",
                     arabicDescription: "يوفر خطاف (Grappling Hook) ومظلة ومنظار وأدوات تنقل لا نهائية وقابلة لإعادة الاستخدام.",
                     englishDescription: "Reusable grappling hooks, parachutes, bolas, and flares."),
        StoreModItem(id: "935985", name: "ARK Additions: Brachiosaurus", category: "ديناصورات جديدة",
                     arabicDescription: "يضيف ديناصور البراكيوصور العملاق بقدرات قتالية وتجميع خشب وتوت بكميات هائلة.",
                     englishDescription: "Adds the massive Brachiosaurus creature with unique abilities."),
        StoreModItem(id: "936457", name: "Primal Chaos", category: "تحدي ومودات كبرى",
                     arabicDescription: "مود ضخم يضيف ديناصورات خرافية وعناصر نارية وكهربائية وزعماء جدد بمستويات صعوبة عالية.",
                     englishDescription: "Overhaul mod adding elemental, demonic, and boss tier dinos."),
        StoreModItem(id: "928621", name: "Death Recovery Mod", category: "بقاء",
                     arabicDescription: "شاهد قبر يسمح لك باسترجاع كامل أغراضك ودروعك بضغطة زر واحدة بعد الموت.",
                     englishDescription: "Tombstone that recovers all your dropped inventory upon death."),
        StoreModItem(id: "930494", name: "Cybers Structures (S+)", category: "بناء",
                     arabicDescription: "إضافات بناء مطورة تشمل جدران وأسقف زجاجية ومصاعد وأبواب تفتح تلقائياً.",
                     englishDescription: "Enhanced building pieces, glass structures, and auto-doors.")
    ]
    
    init() {
        loadSavedAccessCodes()
        loadDemoServers()
    }
    
    // التحقق من رمز الدخول
    func login(with code: String) -> Bool {
        let clean = code.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean == ownerPin {
            currentRole = .owner
            currentUserName = isArabic ? "المالك (صلاحية كاملة)" : "Owner (Full Access)"
            activePermissions = nil
            isAuthenticated = true
            return true
        }
        
        if let friend = friendCodes.first(where: { $0.code == clean }) {
            currentRole = .friend
            currentUserName = friend.friendName
            activePermissions = friend
            isAuthenticated = true
            return true
        }
        
        return false
    }
    
    func logout() {
        isAuthenticated = false
        activePermissions = nil
    }
    
    func updateOwnerPin(newPin: String) {
        guard newPin.count >= 4 else { return }
        ownerPin = newPin
        UserDefaults.standard.set(newPin, forKey: "ownerPin")
        showToast(isArabic ? "تم تحديث رمز المالك بنجاح" : "Owner PIN Updated")
    }
    
    func addFriendCode(_ access: AccessCode) {
        friendCodes.append(access)
        saveFriendCodes()
        showToast(isArabic ? "تم إنشاء رمز دخول لـ \(access.friendName)" : "Code created for \(access.friendName)")
    }
    
    func removeFriendCode(id: String) {
        friendCodes.removeAll { $0.id == id }
        saveFriendCodes()
    }
    
    private func saveFriendCodes() {
        if let encoded = try? JSONEncoder().encode(friendCodes) {
            UserDefaults.standard.set(encoded, forKey: "friendCodes")
        }
    }
    
    private func loadSavedAccessCodes() {
        if let data = UserDefaults.standard.data(forKey: "friendCodes"),
           let decoded = try? JSONDecoder().decode([AccessCode].self, from: data) {
            friendCodes = decoded
        } else {
            friendCodes = [
                AccessCode(id: "f1", friendName: "أخوياي (تعديل وتشغيل)", code: "1122",
                           canPowerControl: true, canEditSettings: true, canManageMods: true, canUseConsole: false)
            ]
        }
    }
    
    // فحص الصلاحيات
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
                config: FullServerConfig(
                    mods: [
                        GameMod(modId: "928793", name: "Super Cryo Storage (SCS)",
                                arabicDescription: "كرات تخزين متطورة لحفظ الديناصورات مع تفريخ البيض تلقائياً."),
                        GameMod(modId: "929110", name: "Awesome SpyGlass!",
                                arabicDescription: "منظار ذكي يعرض نقاط القوة للديناصور قبل ترويضه.")
                    ]
                ),
                consoleLogs: [
                    "[NOIR Engine] ARK: Survival Ascended Server Initialized",
                    "[Mods] Loaded 2 CurseForge Mods: 928793, 929110",
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
                config: FullServerConfig(
                    mods: [
                        GameMod(modId: "GeyserMC", name: "Bedrock Crossplay",
                                arabicDescription: "يسمح للاعبي الجوال والبلايستيشن بالدخول مع لاعبي الكمبيوتر.")
                    ]
                ),
                consoleLogs: [
                    "[PaperMC] Server started on port 25565"
                ]
            )
        ]
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
                if !fetched.isEmpty { self.servers = fetched }
            }
        } catch {
            showToast(isArabic ? "تعذر الاتصال بالسيرفر" : "Connection failed")
        }
    }
    
    func sendPowerAction(serverId: String, action: String) {
        guard canPower, let idx = servers.firstIndex(where: { $0.id == serverId }) else { return }
        if isDemoMode {
            if action == "start" {
                servers[idx].status = .running
                servers[idx].cpuUsage = 36.0
                servers[idx].ramUsedGB = servers[idx].ramTotalGB * 0.72
                servers[idx].consoleLogs.append("[\(currentUserName)] Started server.")
            } else if action == "stop" {
                servers[idx].status = .offline
                servers[idx].cpuUsage = 0
                servers[idx].ramUsedGB = 0
                servers[idx].playersOnline = 0
                servers[idx].consoleLogs.append("[\(currentUserName)] Stopped server.")
            } else if action == "restart" {
                servers[idx].status = .starting
                servers[idx].consoleLogs.append("[\(currentUserName)] Restarting server...")
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
        guard canConsole, !command.isEmpty,
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
    
    func applyFullConfig(serverId: String, config: FullServerConfig) {
        guard let idx = servers.firstIndex(where: { $0.id == serverId }) else { return }
        servers[idx].config = config
        
        let modIds = config.mods.filter { $0.isEnabled }.map { $0.modId }.joined(separator: ",")
        let iniPayload = """
        [ServerSettings]
        HarvestAmountMultiplier=\(config.harvestMultiplier)
        TamingSpeedMultiplier=\(config.tamingSpeed)
        XPMultiplier=\(config.xpMultiplier)
        SupplyCrateLootQualityMultiplier=\(config.lootQuality)
        ItemStackSizeMultiplier=\(config.stackSizeMultiplier)
        EggHatchSpeedMultiplier=\(config.eggHatchSpeed)
        BabyMatureSpeedMultiplier=\(config.babyMatureSpeed)
        MatingIntervalMultiplier=\(config.matingInterval)
        BabyImprintAmountMultiplier=\(config.babyImprintMultiplier)
        PerLevelStatsMultiplier_Player[7]=\(config.playerWeight)
        PerLevelStatsMultiplier_Player[0]=\(config.playerHealth)
        PerLevelStatsMultiplier_Player[1]=\(config.playerStamina)
        PerLevelStatsMultiplier_Player[9]=\(config.playerSpeed)
        PerLevelStatsMultiplier_DinoTamed[7]=\(config.dinoWeight)
        PerLevelStatsMultiplier_DinoTamed[8]=\(config.dinoDamage)
        OverrideOfficialDifficulty=\(Double(config.wildDinoMaxLevel) / 30.0)
        DayTimeSpeedScale=\(config.dayTimeSpeed)
        NightTimeSpeedScale=\(config.nightTimeSpeed)
        PlayerCharacterFoodDrainMultiplier=\(config.playerFoodDrain)
        PlayerCharacterWaterDrainMultiplier=\(config.playerWaterDrain)
        MaxPlayers=\(config.maxPlayers)
        ServerPVE=\(!config.pvpEnabled)
        ForceAllowCaveFlyers=\(config.allowCaveFlyers)
        ShowMapPlayerLocation=\(config.showMapPlayerLocation)
        AllowThirdPersonPlayer=\(config.allowThirdPerson)
        DisableStructureDecayPvE=\(config.disableStructureDecay)
        ServerPassword=\(config.serverPassword)
        ServerAdminPassword=\(config.adminPassword)
        ActiveMods=\(modIds)
        [MessageOfTheDay]
        Message=\(config.motdMessage)
        """
        
        servers[idx].consoleLogs.append("[\(currentUserName)] Saved all settings & \(config.mods.filter{$0.isEnabled}.count) mods.")
        
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
                req.httpBody = iniPayload.data(using: .utf8)
                _ = try? await URLSession.shared.data(for: req)
            }
        }
        
        showToast(isArabic ? "تم حفظ جميع الإعدادات والمودات!" : "All Settings & Mods Saved!")
    }
    
    func createNewServer(name: String, game: GameType, ramGB: Double) {
        guard isOwner else { return }
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
            config: FullServerConfig(),
            consoleLogs: ["[NOIR] Deployed \(game.rawValue) server with \(Int(ramGB))GB RAM."]
        )
        servers.append(newServer)
        showToast(isArabic ? "تم إنشاء سيرفر \(game.rawValue)" : "Created \(game.rawValue)")
    }
    
    func deleteServer(serverId: String) {
        guard isOwner else { return }
        servers.removeAll { $0.id == serverId }
        showToast(isArabic ? "تم حذف السيرفر نهائياً" : "Server deleted")
    }
    
    func showToast(_ msg: String) {
        toastMessage = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if self.toastMessage == msg { self.toastMessage = nil }
        }
    }
}
