import Foundation
import SwiftUI

enum UserRole: String, Codable {
    case owner = "owner"
    case friend = "friend"
}

struct AccessCode: Identifiable, Codable {
    let id: String
    var friendName: String
    var code: String
    var canPowerControl: Bool
    var canEditSettings: Bool
    var canManageMods: Bool
    var canUseConsole: Bool
}

struct ActivityLogItem: Identifiable, Codable {
    let id: String
    let userName: String
    let serverName: String
    let actionDescription: String
    let timestamp: Date
    let category: String
}

enum ServerStatus: String, Codable {
    case running = "running"
    case offline = "offline"
    case starting = "starting"
}

enum ModSortOption: String, CaseIterable, Identifiable {
    case downloads = "downloads"
    case updated = "updated"
    case relevance = "relevance"
    case follows = "follows"
    
    var id: String { rawValue }
    
    func title(isArabic: Bool) -> String {
        switch self {
        case .downloads: return isArabic ? "الأكثر تنزيلاً 🔥" : "Most Downloads"
        case .updated: return isArabic ? "الأحدث تحديثاً 🆕" : "Recently Updated"
        case .relevance: return isArabic ? "الأكثر تطابقاً 🎯" : "Most Relevant"
        case .follows: return isArabic ? "الأعلى تقييماً ⭐" : "Top Rated"
        }
    }
}

enum GameType: String, CaseIterable, Identifiable, Codable {
    case arkAscended = "ARK: Survival Ascended"
    case minecraft = "Minecraft Java/Bedrock"
    case rust = "Rust"
    case palworld = "Palworld"
    case valheim = "Valheim"
    case cs2 = "Counter-Strike 2"
    case fivem = "FiveM (GTA V)"
    case terraria = "Terraria"
    
    var id: String { rawValue }
    
    var shortBadge: String {
        switch self {
        case .arkAscended: return "ARK ASA"
        case .minecraft: return "MINECRAFT"
        case .rust: return "RUST"
        case .palworld: return "PALWORLD"
        case .valheim: return "VALHEIM"
        case .cs2: return "CS2"
        case .fivem: return "FIVEM"
        case .terraria: return "TERRARIA"
        }
    }
    
    var officialImageURL: String {
        switch self {
        case .arkAscended: return "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2399830/header.jpg"
        case .minecraft: return "https://www.minecraft.net/content/dam/games/minecraft/key-art/Vanilla-PMP_Collection-Carousel-0_Buzzy-Bees_1280x768.jpg"
        case .rust: return "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/252490/header.jpg"
        case .palworld: return "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1623730/header.jpg"
        case .valheim: return "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/892970/header.jpg"
        case .cs2: return "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/730/header.jpg"
        case .fivem: return "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/271590/header.jpg"
        case .terraria: return "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/105600/header.jpg"
        }
    }
    
    var fallbackIcon: String {
        switch self {
        case .arkAscended: return "lizard.fill"
        case .minecraft: return "cube.fill"
        case .rust: return "flame.fill"
        case .palworld: return "pawprint.fill"
        case .valheim: return "shield.fill"
        case .cs2: return "scope"
        case .fivem: return "car.fill"
        case .terraria: return "leaf.fill"
        }
    }
    
    var recommendedRAM: Double {
        switch self {
        case .arkAscended: return 16
        case .rust, .palworld, .fivem: return 8
        case .minecraft, .cs2: return 6
        case .valheim, .terraria: return 4
        }
    }
    
    var defaultPort: Int {
        switch self {
        case .arkAscended: return 7777
        case .minecraft: return 25565
        case .rust: return 28015
        case .palworld: return 8211
        case .valheim: return 2456
        case .cs2: return 27015
        case .fivem: return 30120
        case .terraria: return 7778
        }
    }
}

struct FullServerConfig: Codable, Equatable {
    // 1. إعدادات عامة ومنصات
    var maxPlayers: Int = 20
    var crossplayEnabled: Bool = true
    var pvpEnabled: Bool = true
    var serverPassword: String = ""
    var adminPassword: String = "noir123"
    var motdMessage: String = "مرحباً بكم في سيرفر NOIR!"
    var mapName: String = "TheIsland_WP"
    var autoSaveMinutes: Int = 15
    
    // 2. كافة إعدادات ARK: Survival Ascended
    var harvestMultiplier: Double = 5.0
    var harvestHealthMultiplier: Double = 2.0
    var resourceRespawnSpeed: Double = 2.0
    var tamingSpeed: Double = 10.0
    var passiveTameInterval: Double = 1.0
    var xpMultiplier: Double = 3.0
    var killXPMultiplier: Double = 3.0
    var harvestXPMultiplier: Double = 3.0
    var craftXPMultiplier: Double = 3.0
    var lootQuality: Double = 2.0
    var fishingLootQuality: Double = 2.0
    var stackSizeMultiplier: Double = 5.0
    var cropGrowthSpeed: Double = 3.0
    var fuelConsumptionInterval: Double = 2.0
    
    // التفريخ والتربية (ARK Breeding)
    var eggHatchSpeed: Double = 15.0
    var babyMatureSpeed: Double = 20.0
    var matingInterval: Double = 0.2
    var matingSpeed: Double = 2.0
    var babyFoodConsumption: Double = 0.5
    var babyImprintMultiplier: Double = 2.0
    var babyCuddleInterval: Double = 0.2
    var anyoneCanImprint: Bool = true
    
    // إحصائيات اللاعب (ARK Player Stats)
    var playerHealth: Double = 2.0
    var playerStamina: Double = 3.0
    var playerOxygen: Double = 3.0
    var playerFood: Double = 2.0
    var playerWater: Double = 2.0
    var playerWeight: Double = 5.0
    var playerDamage: Double = 1.5
    var playerSpeed: Double = 1.5
    var playerFortitude: Double = 3.0
    var playerCraftingSpeed: Double = 2.0
    
    // إحصائيات الديناصورات (ARK Dino Stats)
    var wildDinoMaxLevel: Int = 150
    var dinoCountMultiplier: Double = 1.0
    var dinoHealth: Double = 1.5
    var dinoStamina: Double = 2.0
    var dinoWeight: Double = 5.0
    var dinoDamage: Double = 1.5
    var dinoSpeed: Double = 1.5
    var allowRaidDinoFeeding: Bool = true
    var allowFlyerSpeedLeveling: Bool = true
    
    // قوانين العالم والبيئة (ARK World & Rules)
    var dayTimeSpeed: Double = 1.0
    var nightTimeSpeed: Double = 2.0
    var playerFoodDrain: Double = 0.5
    var playerWaterDrain: Double = 0.5
    var playerStaminaDrain: Double = 0.5
    var playerHealthRecovery: Double = 2.0
    var maxTribePlayers: Int = 10
    var maxStructuresInRange: Int = 10500
    var platformStructureMultiplier: Double = 2.0
    var allowCaveFlyers: Bool = true
    var allowCaveBuildingPvE: Bool = true
    var showMapPlayerLocation: Bool = true
    var allowThirdPerson: Bool = true
    var enableCrosshair: Bool = true
    var showFloatingDamage: Bool = true
    var disableStructureDecay: Bool = true
    var allowBattlEye: Bool = true
    var enableOfflineRaidProtection: Bool = false
    
    // 3. كافة إعدادات Minecraft
    var mcGameMode: String = "survival"
    var mcDifficulty: String = "normal"
    var mcLevelType: String = "minecraft:normal"
    var mcLevelSeed: String = ""
    var mcOnlineMode: Bool = false
    var mcAllowNether: Bool = true
    var mcAllowEnd: Bool = true
    var mcEnableCommandBlock: Bool = true
    var mcViewDistance: Int = 12
    var mcSimulationDistance: Int = 10
    var mcSpawnProtection: Int = 16
    var mcAllowFlight: Bool = true
    var mcSpawnMonsters: Bool = true
    var mcSpawnAnimals: Bool = true
    var mcSpawnNPCs: Bool = true
    var mcKeepInventory: Bool = true
    var mcMobGriefing: Bool = true
    var mcDoFireTick: Bool = true
    var mcWhiteList: Bool = false
    var mcHardcore: Bool = false
    
    // 4. كافة إعدادات FiveM (GTA V)
    var fivemOneSync: String = "on"
    var fivemGameBuild: String = "3258"
    var fivemVoiceChat: Bool = true
    var fivemScriptHook: Bool = false
    var fivemPureLevel: Int = 0
    var fivemMaxPing: Int = 250
    var fivemTxAdminEnabled: Bool = true
    var fivemSteamWebApiKey: String = ""
    var fivemLicenseKey: String = ""
    
    // 5. كافة إعدادات Rust
    var rustWorldSize: Int = 3500
    var rustWorldSeed: Int = 133742
    var rustGatherRate: Double = 3.0
    var rustSmeltingSpeed: Double = 2.0
    var rustCraftingSpeed: Double = 2.0
    var rustStackMultiplier: Double = 5.0
    var rustDecayScale: Double = 0.5
    var rustUpkeepScale: Double = 0.5
    var rustMaxTeamSize: Int = 4
    var rustRadiation: Bool = true
    var rustHelicopterEvent: Bool = true
    var rustAirdropFrequency: Int = 60
    
    // 6. كافة إعدادات Palworld / CS2 / Terraria / Valheim
    var palCaptureRate: Double = 2.0
    var palSpawnRate: Double = 1.5
    var palWorkSpeed: Double = 2.0
    var palStomachDecrease: Double = 0.5
    var palDropItemMultiplier: Double = 3.0
    var palDeathPenalty: String = "Item"
    var palEnableInvader: Bool = true
    
    var cs2GameMode: String = "Competitive"
    var cs2MaxRounds: Int = 24
    var cs2FriendlyFire: Bool = true
    var cs2FreeArmor: Bool = false
    var cs2StartMoney: Int = 800
    var cs2BotQuota: Int = 0
    
    var terrariaWorldSize: String = "Large"
    var terrariaDifficulty: String = "Expert"
    var terrariaEvilType: String = "Random"
    var terrariaNPCStream: Int = 60
    
    var valheimCombatModifier: String = "Normal"
    var valheimDeathPenalty: String = "Normal"
    var valheimResourceRate: Double = 2.0
    var valheimPortalAllItems: Bool = true
    var valheimNoBuildCost: Bool = false
    
    var mods: [GameMod] = []
    
    func diffSummary(comparedTo old: FullServerConfig, isArabic: Bool) -> [String] {
        var changes: [String] = []
        if maxPlayers != old.maxPlayers { changes.append(isArabic ? "الحد الأقصى للاعبين: \(old.maxPlayers) ← \(maxPlayers)" : "Max Players: \(old.maxPlayers) -> \(maxPlayers)") }
        if crossplayEnabled != old.crossplayEnabled { changes.append(isArabic ? "اللعب المشترك: \(crossplayEnabled ? "مفعل" : "مغلق")" : "Crossplay: \(crossplayEnabled)") }
        if pvpEnabled != old.pvpEnabled { changes.append(isArabic ? "نظام PvP: \(pvpEnabled ? "مفعل" : "مغلق")" : "PvP: \(pvpEnabled)") }
        if mapName != old.mapName { changes.append(isArabic ? "الخريطة: \(old.mapName) ← \(mapName)" : "Map: \(mapName)") }
        if harvestMultiplier != old.harvestMultiplier { changes.append(isArabic ? "مضاعف التجميع: x\(old.harvestMultiplier) ← x\(harvestMultiplier)" : "Harvest: x\(harvestMultiplier)") }
        if tamingSpeed != old.tamingSpeed { changes.append(isArabic ? "سرعة الترويض: x\(old.tamingSpeed) ← x\(tamingSpeed)" : "Taming: x\(tamingSpeed)") }
        if xpMultiplier != old.xpMultiplier { changes.append(isArabic ? "مضاعف الخبرة: x\(old.xpMultiplier) ← x\(xpMultiplier)" : "XP: x\(xpMultiplier)") }
        if eggHatchSpeed != old.eggHatchSpeed { changes.append(isArabic ? "سرعة فقس البيض: x\(eggHatchSpeed)" : "Egg Hatch: x\(eggHatchSpeed)") }
        if babyMatureSpeed != old.babyMatureSpeed { changes.append(isArabic ? "نمو الصغار: x\(babyMatureSpeed)" : "Baby Mature: x\(babyMatureSpeed)") }
        if playerWeight != old.playerWeight { changes.append(isArabic ? "وزن اللاعب: x\(playerWeight)" : "Player Weight: x\(playerWeight)") }
        if dinoWeight != old.dinoWeight { changes.append(isArabic ? "وزن الديناصورات: x\(dinoWeight)" : "Dino Weight: x\(dinoWeight)") }
        if mcGameMode != old.mcGameMode { changes.append(isArabic ? "وضع ماينكرافت: \(mcGameMode)" : "MC Gamemode: \(mcGameMode)") }
        if mcDifficulty != old.mcDifficulty { changes.append(isArabic ? "صعوبة ماينكرافت: \(mcDifficulty)" : "MC Difficulty: \(mcDifficulty)") }
        if fivemGameBuild != old.fivemGameBuild { changes.append(isArabic ? "إصدار FiveM: \(fivemGameBuild)" : "FiveM Build: \(fivemGameBuild)") }
        if rustGatherRate != old.rustGatherRate { changes.append(isArabic ? "موارد Rust: x\(rustGatherRate)" : "Rust Gather: x\(rustGatherRate)") }
        if palCaptureRate != old.palCaptureRate { changes.append(isArabic ? "صيد Palworld: x\(palCaptureRate)" : "Pal Capture: x\(palCaptureRate)") }
        if mods != old.mods { changes.append(isArabic ? "تحديث المودات (\(mods.count) مود)" : "Mods updated (\(mods.count))") }
        
        if changes.isEmpty && self != old {
            changes.append(isArabic ? "تعديل إعدادات متقدمة في السيرفر" : "Updated advanced server settings")
        }
        return changes
    }
}

struct GameMod: Identifiable, Codable, Equatable {
    var id: String { modId }
    let modId: String
    var name: String
    var arabicDescription: String
    var imageURL: String
    var isEnabled: Bool = true
}

struct StoreModItem: Identifiable {
    let id: String
    let game: GameType
    let name: String
    let category: String
    let imageURL: String
    let screenshots: [String]
    let downloadsCount: Int
    let arabicDescription: String
    let englishDescription: String
    
    var formattedDownloads: String {
        if downloadsCount >= 1_000_000 {
            return String(format: "%.1fM", Double(downloadsCount) / 1_000_000.0)
        } else if downloadsCount >= 1_000 {
            return String(format: "%.0fK", Double(downloadsCount) / 1_000.0)
        }
        return "\(downloadsCount)"
    }
}

struct GameServer: Identifiable, Codable {
    let id: String
    var name: String
    var game: GameType
    var ipAddress: String
    var port: Int
    var status: ServerStatus
    var cpuUsage: Double
    var ramUsedGB: Double
    var ramTotalGB: Double
    var playersOnline: Int
    var config: FullServerConfig
    var consoleLogs: [String]
}
