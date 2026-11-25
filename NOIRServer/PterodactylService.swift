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
    
    // مكتبة المودات والبلوقنات بالصور الرسمية لكل لعبة
    let modsCatalog: [StoreModItem] = [
        // --- مودات ARK: Survival Ascended ---
        StoreModItem(id: "928793", game: .arkAscended, name: "Super Cryo Storage (SCS)", category: "تخزين وتفريخ",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/906/404/256/256/638356649746936221.png",
                     arabicDescription: "كرات تخزين متطورة لحفظ الديناصورات مع ثلاجة تفريخ البيض تلقائياً وتوليد الموارد والأسمدة.",
                     englishDescription: "Advanced cryopods with auto-incubation and resource generation."),
        StoreModItem(id: "929110", game: .arkAscended, name: "Awesome SpyGlass!", category: "أدوات",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/906/939/256/256/638357627423346032.png",
                     arabicDescription: "منظار ذكي يعرض لك نقاط القوة (Stats) للديناصور البري قبل ترويضه ونوع الأكل المفضل له.",
                     englishDescription: "Shows wild dino stat points and taming food requirements."),
        StoreModItem(id: "930170", game: .arkAscended, name: "Automated Ark (AA)", category: "أتمتة",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/908/558/256/256/638360623718619239.png",
                     arabicDescription: "نظام ذكي يسحب الموارد تلقائياً من الديناصورات ويوزعها على الأفران والصناديق بضغطة زر.",
                     englishDescription: "Automates resource pulling, sorting, and crafting stations."),
        StoreModItem(id: "928597", game: .arkAscended, name: "Dino Depot", category: "ديناصورات",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/906/105/256/256/638356015382716011.png",
                     arabicDescription: "بديل احترافي للكرايو بود مع محطة تجميع تلقائية لصغار الديناصورات فور ولادتها.",
                     englishDescription: "Dino storage balls with newborn auto-capture terminals."),
        StoreModItem(id: "929785", game: .arkAscended, name: "TG Stacking Mod 10000-90", category: "موارد",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/907/956/256/256/638359472692523650.png",
                     arabicDescription: "يرفع سعة تكديس الموارد (الخشب، الحجر، اللحم) إلى 10,000 حبة ويقلل وزنها بنسبة 90%.",
                     englishDescription: "Increases item stack sizes to 10,000 and reduces weight by 90%."),
        StoreModItem(id: "930494", game: .arkAscended, name: "Cybers Structures (S+)", category: "بناء",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/909/71/256/256/638361547281415229.png",
                     arabicDescription: "إضافات بناء مطورة تشمل جدران وأسقف زجاجية ومصاعد وأبواب تفتح تلقائياً ومولدات لاسلكية.",
                     englishDescription: "Enhanced building pieces, glass structures, and auto-doors."),
        StoreModItem(id: "928621", game: .arkAscended, name: "Death Recovery Mod", category: "بقاء",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/906/140/256/256/638356091726105232.png",
                     arabicDescription: "شاهد قبر تبنيه في بيتك يسمح لك باسترجاع كامل أغراضك ودروعك بضغطة زر واحدة بعد الموت.",
                     englishDescription: "Tombstone that recovers all your dropped inventory upon death."),
        StoreModItem(id: "936457", game: .arkAscended, name: "Primal Chaos", category: "تحدي",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/918/654/256/256/638377581249120312.png",
                     arabicDescription: "مود ضخم يضيف ديناصورات خرافية وعناصر نارية وكهربائية وزعماء جدد بمستويات صعوبة أسطورية.",
                     englishDescription: "Overhaul mod adding elemental, demonic, and boss tier dinos."),
        
        // --- بلوقنات ومودات Minecraft ---
        StoreModItem(id: "GeyserMC", game: .minecraft, name: "GeyserMC + Floodgate", category: "Crossplay",
                     imageURL: "https://cdn.modrinth.com/data/wKKOqHrH/icon.png",
                     arabicDescription: "يسمح للاعبي الجوال والبلايستيشن والإكسبوكس (Bedrock) بالدخول إلى سيرفر Java واللعب مع أصحاب الكمبيوتر.",
                     englishDescription: "Allows Bedrock players (Console/Mobile) to join Java servers."),
        StoreModItem(id: "EssentialsX", game: .minecraft, name: "EssentialsX", category: "إدارة",
                     imageURL: "https://cdn.modrinth.com/data/hXiMc263/icon.png",
                     arabicDescription: "يضيف أوامر الإدارة الأساسية مثل /home و /tpa و /spawn ونظام الاقتصاد والمناطق.",
                     englishDescription: "Essential commands like /home, /tpa, /warp, and economy."),
        StoreModItem(id: "ViaVersion", game: .minecraft, name: "ViaVersion", category: "توافق",
                     imageURL: "https://cdn.modrinth.com/data/P1OZGk5p/icon.png",
                     arabicDescription: "يسمح للاعبين أصحاب الإصدارات الأحدث أو الأقدم بالدخول للسيرفر بدون مشاكل توافق النسخة.",
                     englishDescription: "Allows players on newer Minecraft versions to join older servers."),
        StoreModItem(id: "WorldEdit", game: .minecraft, name: "WorldEdit", category: "بناء",
                     imageURL: "https://cdn.modrinth.com/data/1u6gypXI/icon.png",
                     arabicDescription: "أداة بناء احترافية لنسخ ولصق وتعديل التضاريس والمباني الضخمة بأوامر سريعة.",
                     englishDescription: "In-game map editor and fast building tool."),
        
        // --- موارد FiveM (GTA V) ---
        StoreModItem(id: "qb-core", game: .fivem, name: "QBCore Framework", category: "حياة واقعية",
                     imageURL: "https://avatars.githubusercontent.com/u/81791099?s=200&v=4",
                     arabicDescription: "النظام الأساسي المتكامل لسيرفرات الحياة الواقعية (وظائف، بنوك، شرطة، عصابات، ومعارض سيارات).",
                     englishDescription: "Complete Roleplay framework for FiveM servers."),
        StoreModItem(id: "pma-voice", game: .fivem, name: "pma-voice (راديو وصوت)", category: "صوتيات",
                     imageURL: "https://avatars.githubusercontent.com/u/40129634?s=200&v=4",
                     arabicDescription: "نظام المحادثة الصوتية المحيطية والراديو والاتصال الهاتفي داخل سيرفر FiveM.",
                     englishDescription: "Proximity voice chat and radio system for FiveM."),
        
        // --- بلوقنات Rust ---
        StoreModItem(id: "GatherManager", game: .rust, name: "Gather Manager (x3/x5)", category: "موارد",
                     imageURL: "https://umod.org/images/icons/plugin/5c1a9f1567891.png",
                     arabicDescription: "التحكم في مضاعفة تجميع الخشب والحجر والخامات واللوت في سيرفر Rust.",
                     englishDescription: "Modifies resource gather rates in Rust."),
        StoreModItem(id: "StackSizeController", game: .rust, name: "Stack Size Controller", category: "تخزين",
                     imageURL: "https://umod.org/images/icons/plugin/5c1aa21431245.png",
                     arabicDescription: "زيادة الحد الأقصى لتكديس الموارد والذخيرة داخل الصناديق والحقيبة.",
                     englishDescription: "Customizes maximum stack sizes for all items.")
    ]
    
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
        
        if let data = UserDefaults.standard.data(forKey: "savedServersV3"),
           let decoded = try? JSONDecoder().decode([GameServer].self, from: data), !decoded.isEmpty {
            servers = decoded
        } else {
            loadDefaultServers()
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
            UserDefaults.standard.set(encoded, forKey: "savedServersV3")
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
                    "[Crossplay] PC + PS5 + Xbox enabled",
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
                    "[PaperMC] Server started on port 25565",
                    "[GeyserMC] Bedrock Crossplay active on UDP 19132"
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
            PerLevelStatsMultiplier_Player[0]=\(c.playerHealth)
            PerLevelStatsMultiplier_Player[1]=\(c.playerStamina)
            PerLevelStatsMultiplier_Player[9]=\(c.playerSpeed)
            PerLevelStatsMultiplier_DinoTamed[7]=\(c.dinoWeight)
            PerLevelStatsMultiplier_DinoTamed[8]=\(c.dinoDamage)
            OverrideOfficialDifficulty=\(Double(c.wildDinoMaxLevel) / 30.0)
            DayTimeSpeedScale=\(c.dayTimeSpeed)
            NightTimeSpeedScale=\(c.nightTimeSpeed)
            ForceAllowCaveFlyers=\(c.allowCaveFlyers)
            ShowMapPlayerLocation=\(c.showMapPlayerLocation)
            AllowThirdPersonPlayer=\(c.allowThirdPerson)
            DisableStructureDecayPvE=\(c.disableStructureDecay)
            bUseBattlEye=\(c.allowBattlEye)
            ServerPassword=\(c.serverPassword)
            ServerAdminPassword=\(c.adminPassword)
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
            simulation-distance=\(c.mcSimulationDistance)
            spawn-protection=\(c.mcSpawnProtection)
            allow-flight=\(c.mcAllowFlight)
            motd=\(c.motdMessage)
            """
            return ("%2Fserver.properties", props)
            
        case .fivem:
            let cfg = """
            sv_maxclients \(c.maxPlayers)
            set onesync \(c.fivemOneSync)
            sv_enforceGameBuild \(c.fivemGameBuild)
            sv_scriptHookAllowed \(c.fivemScriptHook ? 1 : 0)
            set steam_webApiKey "\(c.fivemSteamWebApiKey)"
            sv_licenseKey "\(c.fivemLicenseKey)"
            sv_hostname "\(server.name)"
            sets sv_projectDesc "\(c.motdMessage)"
            """
            return ("%2Fserver.cfg", cfg)
            
        case .rust:
            let cfg = """
            server.maxplayers \(c.maxPlayers)
            server.worldsize \(c.rustWorldSize)
            server.seed \(c.rustWorldSeed)
            server.pve \(!c.pvpEnabled)
            decay.scale \(c.rustDecayScale)
            relationshipmanager.maxteamsize \(c.rustMaxTeamSize)
            server.description "\(c.motdMessage)"
            """
            return ("%2Fserver%2Frust%2Fcfg%2Fserver.cfg", cfg)
            
        default:
            let generic = """
            MaxPlayers=\(c.maxPlayers)
            Crossplay=\(c.crossplayEnabled)
            PvP=\(c.pvpEnabled)
            Password=\(c.serverPassword)
            MOTD=\(c.motdMessage)
            """
            return ("%2Fserver.cfg", generic)
        }
    }
    
    func applyFullConfig(serverId: String, config: FullServerConfig, customLogText: String? = nil) {
        guard let idx = servers.firstIndex(where: { $0.id == serverId }) else { return }
        servers[idx].config = config
        
        let logMsg = customLogText ?? "تحديث إعدادات \(servers[idx].game.shortBadge) (الحد الأقصى: \(config.maxPlayers) لاعب، Crossplay: \(config.crossplayEnabled ? "مفعل" : "مغلق"))"
        servers[idx].consoleLogs.append("[\(currentUserName)] \(logMsg)")
        logActivity(serverName: servers[idx].name, action: logMsg, category: customLogText != nil ? "mod" : "config")
        persistServers()
        
        if !isDemoMode {
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
        
        showToast(isArabic ? "تم حفظ وتطبيق كافة الإعدادات!" : "All Settings Saved!")
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
            consoleLogs: ["[NOIR] Deployed \(game.rawValue) | Max Players: \(defaultConfig.maxPlayers) | Crossplay: \(crossplay)"]
        )
        servers.append(newServer)
        persistServers()
        logActivity(serverName: name, action: "إنشاء سيرفر \(game.rawValue) (\(defaultConfig.maxPlayers) لاعب)", category: "create")
        showToast(isArabic ? "تم إنشاء سيرفر \(game.shortBadge)" : "Created \(game.shortBadge)")
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
