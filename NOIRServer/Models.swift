import Foundation

enum UserRole: String, Codable {
    case owner = "owner"
    case friend = "friend"
}

struct AccessCode: Identifiable, Codable {
    let id: String
    var friendName: String
    var code: String
    var canPowerControl: Bool   // تشغيل / إيقاف / ريستارت
    var canEditSettings: Bool   // تعديل إعدادات السيرفر
    var canManageMods: Bool     // إضافة وحذف المودات
    var canUseConsole: Bool     // كتابة أوامر الكونسول
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
}

struct FullServerConfig: Codable {
    // 1. المعدلات الأساسية
    var harvestMultiplier: Double = 5.0
    var tamingSpeed: Double = 10.0
    var xpMultiplier: Double = 3.0
    var lootQuality: Double = 2.0
    var stackSizeMultiplier: Double = 5.0
    
    // 2. التفريخ والتربية (Breeding)
    var eggHatchSpeed: Double = 15.0
    var babyMatureSpeed: Double = 20.0
    var matingInterval: Double = 0.2
    var babyImprintMultiplier: Double = 2.0
    
    // 3. إحصائيات اللاعب والديناصورات
    var playerWeight: Double = 5.0
    var playerHealth: Double = 2.0
    var playerStamina: Double = 3.0
    var playerSpeed: Double = 1.5
    var dinoWeight: Double = 5.0
    var dinoDamage: Double = 1.5
    var wildDinoMaxLevel: Int = 150
    
    // 4. قوانين العالم والبيئة
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
    var isEnabled: Bool = true
}

struct StoreModItem: Identifiable {
    let id: String
    let name: String
    let category: String
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
