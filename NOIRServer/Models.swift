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
    let category: String // "config", "mod", "power", "create"
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
        case .arkAscended: return "ARK"
        case .minecraft: return "MC"
        case .rust: return "RUST"
        case .palworld: return "PAL"
        case .valheim: return "VAL"
        case .cs2: return "CS2"
        case .fivem: return "GTA"
        case .terraria: return "TER"
        }
    }
    
    var icon: String {
        switch self {
        case .arkAscended: return "lizard.fill"
        case .minecraft: return "cube.transparent.fill"
        case .rust: return "flame.circle.fill"
        case .palworld: return "pawprint.circle.fill"
        case .valheim: return "shield.lefthalf.filled"
        case .cs2: return "scope"
        case .fivem: return "car.side.fill"
        case .terraria: return "leaf.circle.fill"
        }
    }
    
    var themeColors: [Color] {
        switch self {
        case .arkAscended: return [Color(red: 0.0, green: 0.82, blue: 0.95), Color(red: 0.05, green: 0.45, blue: 0.85)]
        case .minecraft: return [Color(red: 0.16, green: 0.82, blue: 0.48), Color(red: 0.05, green: 0.55, blue: 0.35)]
        case .rust: return [Color(red: 0.96, green: 0.42, blue: 0.22), Color(red: 0.78, green: 0.18, blue: 0.18)]
        case .palworld: return [Color(red: 0.35, green: 0.65, blue: 1.0), Color(red: 0.45, green: 0.30, blue: 0.95)]
        case .valheim: return [Color(red: 0.20, green: 0.75, blue: 0.72), Color(red: 0.12, green: 0.42, blue: 0.55)]
        case .cs2: return [Color(red: 0.95, green: 0.62, blue: 0.18), Color(red: 0.82, green: 0.35, blue: 0.12)]
        case .fivem: return [Color(red: 0.65, green: 0.35, blue: 0.98), Color(red: 0.35, green: 0.15, blue: 0.75)]
        case .terraria: return [Color(red: 0.28, green: 0.85, blue: 0.55), Color(red: 0.18, green: 0.60, blue: 0.75)]
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
    var harvestMultiplier: Double = 5.0
    var tamingSpeed: Double = 10.0
    var xpMultiplier: Double = 3.0
    var lootQuality: Double = 2.0
    var stackSizeMultiplier: Double = 5.0
    
    var eggHatchSpeed: Double = 15.0
    var babyMatureSpeed: Double = 20.0
    var matingInterval: Double = 0.2
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
    var playerFoodDrain: Double = 0.5
    var playerWaterDrain: Double = 0.5
    var maxPlayers: Int = 20
    var pvpEnabled: Bool = true
    var allowCaveFlyers: Bool = true
    var showMapPlayerLocation: Bool = true
    var allowThirdPerson: Bool = true
    var disableStructureDecay: Bool = true
    var serverPassword: String = ""
    var adminPassword: String = "noir123"
    var motdMessage: String = "مرحباً بكم في سيرفر NOIR!"
    
    var mods: [GameMod] = []
}

struct GameMod: Identifiable, Codable {
    var id: String { modId }
    let modId: String
    var name: String
    var arabicDescription: String
    var iconName: String = "puzzlepiece.extension.fill"
    var isEnabled: Bool = true
}

struct StoreModItem: Identifiable {
    let id: String
    let name: String
    let category: String
    let iconName: String
    let bannerColors: [Color]
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
