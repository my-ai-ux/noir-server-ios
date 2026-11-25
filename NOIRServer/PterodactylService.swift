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
    
    @Published var isArabic: Bool = true
    @Published var isDemoMode: Bool = UserDefaults.standard.object(forKey: "isDemoMode") as? Bool ?? true
    @Published var panelURL: String = UserDefaults.standard.string(forKey: "panelURL") ?? ""
    @Published var apiKey: String = UserDefaults.standard.string(forKey: "apiKey") ?? ""
    @Published var toastMessage: String? = nil
    
    // مكتبة مودات ARK: Survival Ascended الشاملة بالصور والأيقونات والوصف العربي
    let arkModsCatalog: [StoreModItem] = [
        StoreModItem(id: "928793", name: "Super Cryo Storage (SCS)", category: "تخزين وتفريخ", iconName: "snowflake.circle.fill",
                     bannerColors: [.cyan, .blue],
                     arabicDescription: "كرات تخزين متطورة لحفظ الديناصورات مع ثلاجة تفريخ البيض تلقائياً وتوليد الموارد والأسمدة.",
                     englishDescription: "Advanced cryopods with auto-incubation and passive resource generation."),
        StoreModItem(id: "929110", name: "Awesome SpyGlass!", category: "أدوات واستكشاف", iconName: "scope",
                     bannerColors: [.purple, .indigo],
                     arabicDescription: "منظار ذكي يعرض لك نقاط القوة (Stats) للديناصور البري قبل ترويضه ونوع الأكل المفضل له.",
                     englishDescription: "Shows wild dino stat points, torpor, and taming food requirements."),
        StoreModItem(id: "930170", name: "Automated Ark (AA)", category: "أتمتة ومصانع", iconName: "gearshape.2.fill",
                     bannerColors: [.teal, .green],
                     arabicDescription: "نظام ذكي يسحب الموارد تلقائياً من الديناصورات ويوزعها على الأفران والصناديق بضغطة زر.",
                     englishDescription: "Automates resource pulling, sorting, and crafting stations."),
        StoreModItem(id: "928597", name: "Dino Depot", category: "ديناصورات", iconName: "shippingbox.circle.fill",
                     bannerColors: [.blue, .indigo],
                     arabicDescription: "بديل احترافي للكرايو بود مع محطة تجميع تلقائية لصغار الديناصورات فور ولادتها.",
                     englishDescription: "Dino storage balls with newborn auto-capture terminals."),
        StoreModItem(id: "929785", name: "TG Stacking Mod 10000-90", category: "موارد ووزن", iconName: "square.stack.3d.up.fill",
                     bannerColors: [.orange, .red],
                     arabicDescription: "يرفع سعة تكديس الموارد (الخشب، الحجر، اللحم) إلى 10,000 حبة ويقلل وزنها بنسبة 90%.",
                     englishDescription: "Increases item stack sizes to 10,000 and reduces weight by 90%."),
        StoreModItem(id: "930494", name: "Cybers Structures (S+)", category: "بناء متطور", iconName: "building.2.fill",
                     bannerColors: [.cyan, .teal],
                     arabicDescription: "إضافات بناء مطورة تشمل جدران وأسقف زجاجية ومصاعد وأبواب تفتح تلقائياً ومولدات لاسلكية.",
                     englishDescription: "Enhanced building pieces, glass structures, and auto-doors."),
        StoreModItem(id: "932365", name: "Utilities Plus", category: "أدوات بقاء", iconName: "figure.climbing",
                     bannerColors: [.mint, .teal],
                     arabicDescription: "يوفر خطاف (Grappling Hook) ومظلة ومنظار وبولا لا نهائية وقابلة لإعادة الاستخدام بدون كسر.",
                     englishDescription: "Reusable grappling hooks, parachutes, bolas, and flares."),
        StoreModItem(id: "928621", name: "Death Recovery Mod", category: "استرجاع الأغراض", iconName: "cross.circle.fill",
                     bannerColors: [.red, .pink],
                     arabicDescription: "شاهد قبر تبنيه في بيتك يسمح لك باسترجاع كامل أغراضك ودروعك بضغطة زر واحدة بعد الموت.",
                     englishDescription: "Tombstone that recovers all your dropped inventory upon death."),
        StoreModItem(id: "936457", name: "Primal Chaos", category: "تحدي وزعماء", iconName: "flame.fill",
                     bannerColors: [.red, .orange],
                     arabicDescription: "مود ضخم يضيف ديناصورات خرافية وعناصر نارية وكهربائية وزعماء جدد بمستويات صعوبة أسطورية.",
                     englishDescription: "Overhaul mod adding elemental, demonic, and boss tier dinos."),
        StoreModItem(id: "935985", name: "ARK Additions: Brachiosaurus", category: "ديناصورات جديدة", iconName: "lizard.fill",
                     bannerColors: [.green, .mint],
                     arabicDescription: "يضيف ديناصور البراكيوصور العملاق بقدرات قتالية وتجميع خشب وتوت بكميات هائلة.",
                     englishDescription: "Adds the massive Brachiosaurus creature with unique abilities."),
        StoreModItem(id: "933099", name: "Pelayori's Cryo Storage", category: "تخزين", iconName: "cube.fill",
                     bannerColors: [.indigo, .purple],
                     arabicDescription: "نظام كرايو خفيف وسريع يدعم التجميع التلقائي للبيض والسماد من الديناصورات المخزنة.",
                     englishDescription: "Lightweight cryo system with passive egg and fertilizer collection."),
        StoreModItem(id: "931214", name: "Upgrade Station", category: "تطوير الأسلحة", iconName: "hammer.circle.fill",
                     bannerColors: [.yellow, .orange],
                     arabicDescription: "طاولة تطوير تسمح لك بترقية أي سلاح أو درع أو سرج ديناصور من العادي إلى Ascendant.",
                     englishDescription: "Allows upgrading any weapon, armor, or saddle up to Ascendant quality."),
        StoreModItem(id: "934881", name: "Shiny! Dinos Ascended", category: "ديناصورات نادرة", iconName: "sparkles",
                     bannerColors: [.pink, .purple],
                     arabicDescription: "يضيف ديناصورات ملونة ونادرة (Shiny) بقدرات خاصة ومستويات عالية في أنحاء الخريطة.",
                     englishDescription: "Spawns rare variant dinos with special colors and abilities across the map."),
        StoreModItem(id: "937112", name: "Custom Dino Levels", category: "توازن المستويات", iconName: "chart.bar.fill",
                     bannerColors: [.blue, .cyan],
                     arabicDescription: "يعدل توزيع مستويات الديناصورات البرية بحيث تظهر ديناصورات بمستويات عالية (130-150) بكثرة.",
                     englishDescription: "Balances wild dino level spawns so high-level dinos appear more frequently."),
        StoreModItem(id: "938440", name: "Klinger Additional Boats", category: "سفن وقوارب", iconName: "ferry.fill",
                     bannerColors: [.teal, .blue],
                     arabicDescription: "يضيف سفن خشبية وحديدية عملاقة قابلة للبناء عليها للإبحار ونقل الديناصورات.",
                     englishDescription: "Adds large customizable wooden and metal ships for ocean transport.")
    ]
    
    init() {
        loadAllPersistedData()
    }
    
    // حفظ واسترجاع جميع البيانات من ذاكرة الهاتف
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
        
        if let data = UserDefaults.standard.data(forKey: "savedServers"),
           let decoded = try? JSONDecoder().decode([GameServer].self, from: data), !decoded.isEmpty {
            servers = decoded
        } else {
            loadDefaultServers()
        }
        
        if let data = UserDefaults.standard.data(forKey: "savedActivityLogs"),
           let decoded = try? JSONDecoder().decode([ActivityLogItem].self, from: data) {
            activityLogs = decoded
        } else {
            logActivity(serverName: "NOIR ARK Ascended x5", action: "تم تهيئة السيرفر وتركيب المودات الأساسية", category: "create")
        }
    }
    
    func persistServers() {
        if let encoded = try? JSONEncoder().encode(servers) {
            UserDefaults.standard.set(encoded, forKey: "savedServers")
        }
    }
    
    func persistLogs() {
        if let encoded = try? JSONEncoder().encode(activityLogs) {
            UserDefaults.standard.set(encoded, forKey: "savedActivityLogs")
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
    }
    
    func logout() {
        isAuthenticated = false
        activePermissions = nil
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "savedActivePermissions")
    }
    
    func updateOwnerPin(newPin: String) {
        guard newPin.count >= 4 else { return }
        ownerPin = newPin
        UserDefaults.standard.set(newPin, forKey: "ownerPin")
        showToast(isArabic ? "تم حفظ رمز المالك الجديد" : "Owner PIN Saved")
    }
    
    func addFriendCode(_ access: AccessCode) {
        friendCodes.append(access)
        if let encoded = try? JSONEncoder().encode(friendCodes) {
            UserDefaults.standard.set(encoded, forKey: "friendCodes")
        }
        showToast(isArabic ? "تم حفظ رمز \(access.friendName)" : "Code Saved")
    }
    
    func removeFriendCode(id: String) {
        friendCodes.removeAll { $0.id == id }
        if let encoded = try? JSONEncoder().encode(friendCodes) {
            UserDefaults.standard.set(encoded, forKey: "friendCodes")
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
                    mods: [
                        GameMod(modId: "928793", name: "Super Cryo Storage (SCS)",
                                arabicDescription: "كرات تخزين متطورة لحفظ الديناصورات مع ثلاجة تفريخ البيض تلقائياً.",
                                iconName: "snowflake.circle.fill"),
                        GameMod(modId: "929110", name: "Awesome SpyGlass!",
                                arabicDescription: "منظار ذكي يعرض نقاط القوة للديناصور قبل ترويضه.",
                                iconName: "scope")
                    ]
                ),
                consoleLogs: [
                    "[NOIR Engine] ARK: Survival Ascended Server Initialized",
                    "[Mods] Loaded 2 CurseForge Mods: 928793, 929110"
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
                                arabicDescription: "يسمح للاعبي الجوال والبلايستيشن بالدخول مع لاعبي الكمبيوتر.",
                                iconName: "cube.transparent.fill")
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
                self.servers[idx].status = .running
                self.servers[idx].consoleLogs.append("[NOIR] Server Online!")
                self.persistServers()
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
    
    func applyFullConfig(serverId: String, config: FullServerConfig, customLogText: String? = nil) {
        guard let idx = servers.firstIndex(where: { $0.id == serverId }) else { return }
        servers[idx].config = config
        
        let logMsg = customLogText ?? "تحديث الإعدادات (تجميع x\(Int(config.harvestMultiplier))، ترويض x\(Int(config.tamingSpeed)))"
        servers[idx].consoleLogs.append("[\(currentUserName)] \(logMsg)")
        logActivity(serverName: servers[idx].name, action: logMsg, category: customLogText != nil ? "mod" : "config")
        persistServers()
        
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
        
        showToast(isArabic ? "تم الحفظ في ذاكرة التطبيق والسيرفر!" : "Saved Permanently!")
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
        persistServers()
        logActivity(serverName: name, action: "إنشاء سيرفر جديد (\(game.rawValue))", category: "create")
        showToast(isArabic ? "تم إنشاء وحفظ سيرفر \(game.rawValue)" : "Created \(game.rawValue)")
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
