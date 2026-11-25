import Foundation

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
    
    var icon: String {
        switch self {
        case .arkAscended: return "flame.fill"
        case .minecraft: return "cube.fill"
        case .rust: return "hammer.fill"
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
    
    var modSourceLabel: String {
        switch self {
        case .arkAscended: return "CurseForge Mod ID"
        case .minecraft: return "Modrinth / Plugin ID"
        case .rust: return "Oxide / uMod Plugin"
        case .palworld, .valheim, .cs2: return "Steam Workshop / Mod ID"
        case .fivem: return "Resource Folder Name"
        case .terraria: return "tModLoader ID"
        }
    }
}

struct NitradoStyleConfig: Codable {
    var primaryRate: Double = 5.0       // التجميع (ARK/Rust) أو الصعوبة (MC)
    var secondaryRate: Double = 10.0    // الترويض (ARK) أو سرعة الصيد (Palworld)
    var xpMultiplier: Double = 3.0      // مضاعف الخبرة XP
    var thirdRate: Double = 15.0        // نمو الصغار أو سرعة البناء
    var weightOrSlots: Double = 5.0     // وزن اللاعب أو سعة المخزن
    var maxPlayers: Int = 20
    var pvpEnabled: Bool = true
    var serverPassword: String = ""
    var mods: [GameMod] = []
}

struct GameMod: Identifiable, Codable {
    var id: String { modId }
    let modId: String
    var name: String
    var isEnabled: Bool = true
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
    var config: NitradoStyleConfig
    var consoleLogs: [String]
}
