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
        case .arkAscended:
            return "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2399830/header.jpg"
        case .minecraft:
            return "https://www.minecraft.net/content/dam/games/minecraft/key-art/Vanilla-PMP_Collection-Carousel-0_Buzzy-Bees_1280x768.jpg"
        case .rust:
            return "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/252490/header.jpg"
        case .palworld:
            return "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1623730/header.jpg"
        case .valheim:
            return "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/892970/header.jpg"
        case .cs2:
            return "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/730/header.jpg"
        case .fivem:
            return "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/271590/header.jpg"
        case .terraria:
            return "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/105600/header.jpg"
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
    var maxPlayers: Int = 20
    var crossplayEnabled: Bool = true
    var pvpEnabled: Bool = true
    var serverPassword: String = ""
    var adminPassword: String = "noir123"
    var motdMessage: String = "مرحباً بكم في سيرفر NOIR!"
    var mapName: String = "TheIsland_WP"
    
    // ARK
    var harvestMultiplier: Double = 5.0
    var tamingSpeed: Double = 10.0
    var xpMultiplier: Double = 3.0
    var lootQuality: Double = 2.0
    var stackSizeMultiplier: Double = 5.0
    var eggHatchSpeed: Double = 15.0
    var babyMatureSpeed: Double = 20.0
    var babyImprintMultiplier: Double = 2.0
    var playerWeight: Double = 5.0
    var playerHealth: Double = 2.0
    var playerStamina: Double = 3.0
    var playerSpeed: Double = 1.5
    var dinoWeight: Double = 5.0
    var dinoDamage: Double = 1.5
    var wildDinoMaxLevel: Int = 150
    var dayTimeSpeed: Double = 1.0
    var nightTimeSpeed: Double = 2.0
    var allowCaveFlyers: Bool = true
    var showMapPlayerLocation: Bool = true
    var allowThirdPerson: Bool = true
    var disableStructureDecay: Bool = true
    var allowBattlEye: Bool = true
    
    // Minecraft
    var mcGameMode: String = "survival"
    var mcDifficulty: String = "normal"
    var mcOnlineMode: Bool = false
    var mcAllowNether: Bool = true
    var mcAllowEnd: Bool = true
    var mcEnableCommandBlock: Bool = true
    var mcViewDistance: Int = 12
    var mcSpawnProtection: Int = 16
    var mcAllowFlight: Bool = true
    
    // FiveM
    var fivemOneSync: String = "on"
    var fivemGameBuild: String = "3258"
    var fivemVoiceChat: Bool = true
    var fivemScriptHook: Bool = false
    var fivemSteamWebApiKey: String = ""
    var fivemLicenseKey: String = ""
    
    // Rust
    var rustWorldSize: Int = 3500
    var rustWorldSeed: Int = 133742
    var rustGatherRate: Double = 3.0
    var rustDecayScale: Double = 0.5
    var rustMaxTeamSize: Int = 4
    
    // Palworld / CS2 / Terraria
    var palCaptureRate: Double = 2.0
    var palSpawnRate: Double = 1.5
    var cs2GameMode: String = "Competitive"
    var cs2MaxRounds: Int = 24
    var terrariaWorldSize: String = "Large"
    var terrariaDifficulty: String = "Expert"
    
    var mods: [GameMod] = []
    
    func diffSummary(comparedTo old: FullServerConfig, isArabic: Bool) -> [String] {
        var changes: [String] = []
        if maxPlayers != old.maxPlayers {
            changes.append(isArabic ? "الحد الأقصى للاعبين: \(old.maxPlayers) ← \(maxPlayers)" : "Max Players: \(old.maxPlayers) → \(maxPlayers)")
        }
        if crossplayEnabled != old.crossplayEnabled {
            changes.append(isArabic ? "اللعب المشترك (PC+Console): \(crossplayEnabled ? "مفعل" : "مغلق")" : "Crossplay: \(crossplayEnabled)")
        }
        if pvpEnabled != old.pvpEnabled {
            changes.append(isArabic ? "وضع القتال (PvP): \(pvpEnabled ? "مفعل" : "مغلق")" : "PvP: \(pvpEnabled)")
        }
        if mapName != old.mapName {
            changes.append(isArabic ? "الخريطة: \(old.mapName) ← \(mapName)" : "Map: \(old.mapName) → \(mapName)")
        }
        if harvestMultiplier != old.harvestMultiplier {
            changes.append(isArabic ? "مضاعف التجميع: x\(old.harvestMultiplier) ← x\(harvestMultiplier)" : "Harvest: x\(old.harvestMultiplier) → x\(harvestMultiplier)")
        }
        if tamingSpeed != old.tamingSpeed {
            changes.append(isArabic ? "سرعة الترويض: x\(old.tamingSpeed) ← x\(tamingSpeed)" : "Taming: x\(old.tamingSpeed) → x\(tamingSpeed)")
        }
        if xpMultiplier != old.xpMultiplier {
            changes.append(isArabic ? "مضاعف الخبرة (XP): x\(old.xpMultiplier) ← x\(xpMultiplier)" : "XP: x\(old.xpMultiplier) → x\(xpMultiplier)")
        }
        if lootQuality != old.lootQuality {
            changes.append(isArabic ? "جودة اللوت: x\(old.lootQuality) ← x\(lootQuality)" : "Loot: x\(old.lootQuality) → x\(lootQuality)")
        }
        if stackSizeMultiplier != old.stackSizeMultiplier {
            changes.append(isArabic ? "تكديس الموارد: x\(old.stackSizeMultiplier) ← x\(stackSizeMultiplier)" : "Stack: x\(old.stackSizeMultiplier) → x\(stackSizeMultiplier)")
        }
        if eggHatchSpeed != old.eggHatchSpeed {
            changes.append(isArabic ? "سرعة فقس البيض: x\(old.eggHatchSpeed) ← x\(eggHatchSpeed)")
        }
        if babyMatureSpeed != old.babyMatureSpeed {
            changes.append(isArabic ? "نمو الصغار: x\(old.babyMatureSpeed) ← x\(babyMatureSpeed)")
        }
        if babyImprintMultiplier != old.babyImprintMultiplier {
            changes.append(isArabic ? "مضاعف البصمة: x\(old.babyImprintMultiplier) ← x\(babyImprintMultiplier)")
        }
        if playerWeight != old.playerWeight {
            changes.append(isArabic ? "وزن اللاعب: x\(old.playerWeight) ← x\(playerWeight)")
        }
        if dinoWeight != old.dinoWeight {
            changes.append(isArabic ? "وزن الديناصورات: x\(old.dinoWeight) ← x\(dinoWeight)")
        }
        if dinoDamage != old.dinoDamage {
            changes.append(isArabic ? "ضرر الديناصورات: x\(old.dinoDamage) ← x\(dinoDamage)")
        }
        if allowCaveFlyers != old.allowCaveFlyers {
            changes.append(isArabic ? "طيران الكهوف: \(allowCaveFlyers ? "مسموح" : "ممنوع")")
        }
        if showMapPlayerLocation != old.showMapPlayerLocation {
            changes.append(isArabic ? "موقع اللاعب بالخريطة: \(showMapPlayerLocation ? "ظاهر" : "مخفي")")
        }
        if serverPassword != old.serverPassword {
            changes.append(isArabic ? "تم تغيير كلمة مرور السيرفر" : "Server password updated")
        }
        if motdMessage != old.motdMessage {
            changes.append(isArabic ? "تم تحديث رسالة الترحيب (MOTD)" : "MOTD updated")
        }
        if mcGameMode != old.mcGameMode {
            changes.append(isArabic ? "وضع ماينكرافت: \(mcGameMode)" : "MC Gamemode: \(mcGameMode)")
        }
        if mcDifficulty != old.mcDifficulty {
            changes.append(isArabic ? "صعوبة ماينكرافت: \(mcDifficulty)" : "MC Difficulty: \(mcDifficulty)")
        }
        if fivemGameBuild != old.fivemGameBuild {
            changes.append(isArabic ? "إصدار FiveM: \(fivemGameBuild)" : "FiveM Build: \(fivemGameBuild)")
        }
        if rustGatherRate != old.rustGatherRate {
            changes.append(isArabic ? "موارد Rust: x\(rustGatherRate)" : "Rust Gather: x\(rustGatherRate)")
        }
        if mods != old.mods {
            changes.append(isArabic ? "تحديث قائمة المودات (\(mods.count) مود)" : "Mods list updated (\(mods.count))")
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
