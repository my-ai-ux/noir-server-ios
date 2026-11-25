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
    
    // روابط الصور الرسمية الأصلية للألعاب
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

struct FullServerConfig: Codable {
    // --- إعدادات مشتركة لجميع السيرفرات ---
    var maxPlayers: Int = 20
    var crossplayEnabled: Bool = true        // اللعب المشترك (PC + Console / Bedrock)
    var pvpEnabled: Bool = true
    var serverPassword: String = ""
    var adminPassword: String = "noir123"
    var motdMessage: String = "مرحباً بكم في سيرفر NOIR!"
    var autoSaveMinutes: Int = 15
    var mapName: String = "TheIsland_WP"
    
    // --- إعدادات ARK: Survival Ascended ---
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
    
    // --- إعدادات Minecraft ---
    var mcGameMode: String = "survival"      // survival, creative, adventure, spectator
    var mcDifficulty: String = "normal"      // peaceful, easy, normal, hard
    var mcOnlineMode: Bool = false           // false = يسمح بالمكركة والأصلية
    var mcAllowNether: Bool = true
    var mcAllowEnd: Bool = true
    var mcEnableCommandBlock: Bool = true
    var mcViewDistance: Int = 12
    var mcSimulationDistance: Int = 10
    var mcSpawnProtection: Int = 16
    var mcAllowFlight: Bool = true
    
    // --- إعدادات FiveM (GTA V) ---
    var fivemOneSync: String = "on"          // on, legacy, off
    var fivemGameBuild: String = "3258"      // 3258, 3095, 2944, 2802
    var fivemVoiceChat: Bool = true
    var fivemScriptHook: Bool = false
    var fivemSteamWebApiKey: String = ""
    var fivemLicenseKey: String = ""
    
    // --- إعدادات Rust ---
    var rustWorldSize: Int = 3500
    var rustWorldSeed: Int = 133742
    var rustGatherRate: Double = 3.0
    var rustDecayScale: Double = 0.5
    var rustMaxTeamSize: Int = 4
    var rustWipeSchedule: String = "Weekly"
    
    // --- إعدادات Palworld / Valheim / CS2 / Terraria ---
    var palCaptureRate: Double = 2.0
    var palSpawnRate: Double = 1.5
    var palDeathPenalty: String = "Item"     // None, Item, ItemAndEquipment, All
    var cs2GameMode: String = "Competitive"  // Competitive, Premier, Deathmatch, Casual
    var cs2MaxRounds: Int = 24
    var terrariaWorldSize: String = "Large"  // Small, Medium, Large
    var terrariaDifficulty: String = "Expert"// Classic, Expert, Master, Journey
    
    var mods: [GameMod] = []
}

struct GameMod: Identifiable, Codable {
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
    let arabicDescription: String
    let englishDescription: String
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
