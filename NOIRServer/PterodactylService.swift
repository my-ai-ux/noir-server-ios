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
    
    // عداد إعادة التشغيل الحي (20 ثانية)
    @Published var restartingServerId: String? = nil
    @Published var restartCountdown: Int = 0
    private var restartTimer: Timer? = nil
    
    @Published var isArabic: Bool = true
    @Published var isDemoMode: Bool = UserDefaults.standard.object(forKey: "isDemoMode") as? Bool ?? true
    @Published var panelURL: String = UserDefaults.standard.string(forKey: "panelURL") ?? ""
    @Published var apiKey: String = UserDefaults.standard.string(forKey: "apiKey") ?? ""
    @Published var toastMessage: String? = nil
    
    // مكتبة مودات ARK الشاملة (أكثر من 35 موداً من أشهر مودات ARK Ascended) + الألعاب الأخرى
    let modsCatalog: [StoreModItem] = [
        // 1. التخزين والتفريخ
        StoreModItem(id: "928793", game: .arkAscended, name: "Super Cryo Storage (SCS)", category: "تخزين",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/906/404/256/256/638356649746936221.png",
                     arabicDescription: "كرات تخزين متطورة لحفظ الديناصورات مع ثلاجة تفريخ البيض تلقائياً وتوليد الموارد والأسمدة.",
                     englishDescription: "Advanced cryopods with auto-incubation and resource generation."),
        StoreModItem(id: "928597", game: .arkAscended, name: "Dino Depot", category: "تخزين",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/906/105/256/256/638356015382716011.png",
                     arabicDescription: "بديل احترافي للكرايو بود مع محطة تجميع تلقائية لصغار الديناصورات فور ولادتها.",
                     englishDescription: "Dino storage balls with newborn auto-capture terminals."),
        StoreModItem(id: "933099", game: .arkAscended, name: "Pelayori's Cryo Storage", category: "تخزين",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/913/211/256/256/638368819201425101.png",
                     arabicDescription: "نظام كرايو خفيف وسريع يدعم التجميع التلقائي للبيض والسماد من الديناصورات المخزنة.",
                     englishDescription: "Lightweight cryo system with passive egg and fertilizer collection."),
        StoreModItem(id: "929785", game: .arkAscended, name: "TG Stacking Mod 10000-90", category: "موارد",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/907/956/256/256/638359472692523650.png",
                     arabicDescription: "يرفع سعة تكديس الموارد (الخشب، الحجر، اللحم) إلى 10,000 حبة ويقلل وزنها بنسبة 90%.",
                     englishDescription: "Increases item stack sizes to 10,000 and reduces weight by 90%."),
        StoreModItem(id: "929420", game: .arkAscended, name: "EZ Stacks 5000-50", category: "موارد",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/907/401/256/256/638358412904125120.png",
                     arabicDescription: "تكديس متوازن يصل إلى 5,000 للموارد مع تخفيض الوزن للنصف.",
                     englishDescription: "Balanced 5000 stack sizes with 50% weight reduction."),
        
        // 2. الأدوات والاستكشاف
        StoreModItem(id: "929110", game: .arkAscended, name: "Awesome SpyGlass!", category: "أدوات",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/906/939/256/256/638357627423346032.png",
                     arabicDescription: "منظار ذكي يعرض لك نقاط القوة (Stats) للديناصور البري قبل ترويضه ونوع الأكل المفضل له.",
                     englishDescription: "Shows wild dino stat points and taming food requirements."),
        StoreModItem(id: "932365", game: .arkAscended, name: "Utilities Plus", category: "أدوات",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/912/102/256/256/638366912345123412.png",
                     arabicDescription: "يوفر خطاف (Grappling Hook) ومظلة ومنظار وبولا لا نهائية وقابلة لإعادة الاستخدام بدون كسر.",
                     englishDescription: "Reusable grappling hooks, parachutes, bolas, and flares."),
        StoreModItem(id: "928621", game: .arkAscended, name: "Death Recovery Mod", category: "أدوات",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/906/140/256/256/638356091726105232.png",
                     arabicDescription: "شاهد قبر تبنيه في بيتك يسمح لك باسترجاع كامل أغراضك ودروعك بضغطة زر واحدة بعد الموت.",
                     englishDescription: "Tombstone that recovers all your dropped inventory upon death."),
        StoreModItem(id: "931214", game: .arkAscended, name: "Upgrade Station", category: "أدوات",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/910/320/256/256/638363512904123456.png",
                     arabicDescription: "طاولة تطوير تسمح لك بترقية أي سلاح أو درع أو سرج ديناصور من العادي إلى Ascendant.",
                     englishDescription: "Allows upgrading any weapon, armor, or saddle up to Ascendant quality."),
        StoreModItem(id: "929868", game: .arkAscended, name: "Super Spyglass Plus", category: "أدوات",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/908/110/256/256/638359781234567890.png",
                     arabicDescription: "منظار متطور يحدد أماكن الديناصورات النادرة ويعرض مستويات الترويض بدقة.",
                     englishDescription: "Advanced spyglass with dino radar and stat breakdown."),
        StoreModItem(id: "935421", game: .arkAscended, name: "Dino+ (Nanny & Hatchery)", category: "تربية",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/916/882/256/256/638374512398765432.png",
                     arabicDescription: "يضيف المربية الآلية (Nanny) التي تطعم صغار الديناصورات وترفع البصمة (Imprint) إلى 100% تلقائياً.",
                     englishDescription: "Adds automated Nanny and Hatchery for 100% imprinting."),
        
        // 3. الأتمتة والبناء
        StoreModItem(id: "930170", game: .arkAscended, name: "Automated Ark (AA)", category: "أتمتة",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/908/558/256/256/638360623718619239.png",
                     arabicDescription: "نظام ذكي يسحب الموارد تلقائياً من الديناصورات ويوزعها على الأفران والصناديق بضغطة زر.",
                     englishDescription: "Automates resource pulling, sorting, and crafting stations."),
        StoreModItem(id: "930494", game: .arkAscended, name: "Cybers Structures (S+)", category: "بناء",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/909/71/256/256/638361547281415229.png",
                     arabicDescription: "إضافات بناء مطورة تشمل جدران وأسقف زجاجية ومصاعد وأبواب تفتح تلقائياً ومولدات لاسلكية.",
                     englishDescription: "Enhanced building pieces, glass structures, and auto-doors."),
        StoreModItem(id: "934102", game: .arkAscended, name: "ASR - Arkitect Structures", category: "بناء",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/914/901/256/256/638371234567890123.png",
                     arabicDescription: "تصاميم بناء عصرية وقلاع حجرية وخشبية فخمة مع نوافذ وديكورات داخلية.",
                     englishDescription: "Medieval castles, modern architecture, and decorative building pieces."),
        StoreModItem(id: "938440", game: .arkAscended, name: "Klinger Additional Boats", category: "بناء",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/921/504/256/256/638382345678901234.png",
                     arabicDescription: "يضيف سفن خشبية وحديدية عملاقة قابلة للبناء عليها للإبحار ونقل الديناصورات.",
                     englishDescription: "Adds large customizable wooden and metal ships for ocean transport."),
        StoreModItem(id: "931890", game: .arkAscended, name: "Pull It!", category: "أتمتة",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/911/340/256/256/638365432109876543.png",
                     arabicDescription: "يسمح لك بسحب الموارد المطلوبة لصناعة أي أداة أو مبنى من الصناديق القريبة بضغطة زر.",
                     englishDescription: "Pulls required crafting resources from nearby storage containers."),
        
        // 4. الديناصورات الجديدة (ARK Additions & Creatures)
        StoreModItem(id: "935985", game: .arkAscended, name: "ARK Additions: Brachiosaurus", category: "ديناصورات",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/917/802/256/256/638376123456789012.png",
                     arabicDescription: "يضيف ديناصور البراكيوصور العملاق بقدرات قتالية وتجميع خشب وتوت بكميات هائلة.",
                     englishDescription: "Adds the massive Brachiosaurus creature with unique abilities."),
        StoreModItem(id: "935989", game: .arkAscended, name: "ARK Additions: Deinosuchus", category: "ديناصورات",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/917/810/256/256/638376156789012345.png",
                     arabicDescription: "يضيف التمساح العملاق Deinosuchus المفترس في المستنقعات والأنهار بقدرة عض مدمرة.",
                     englishDescription: "Adds the giant prehistoric alligator Deinosuchus."),
        StoreModItem(id: "935992", game: .arkAscended, name: "ARK Additions: Archelon", category: "ديناصورات",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/917/818/256/256/638376189012345678.png",
                     arabicDescription: "يضيف السلحفاة البحرية العملاقة التي تنتج السوشي لتسريع ترويض الكائنات البحرية.",
                     englishDescription: "Adds the giant sea turtle Archelon for underwater adventures."),
        StoreModItem(id: "935995", game: .arkAscended, name: "ARK Additions: Ceratosaurus", category: "ديناصورات",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/917/825/256/256/638376212345678901.png",
                     arabicDescription: "ديناصور مفترس سريع يعالج الديناصورات الحليفة أثناء القتال ضد الزعماء.",
                     englishDescription: "Fast carnivore that heals nearby allied dinos in combat."),
        StoreModItem(id: "935998", game: .arkAscended, name: "ARK Additions: Helicoprion", category: "ديناصورات",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/917/832/256/256/638376245678901234.png",
                     arabicDescription: "قرش ما قبل التاريخ ذو المنشار الدائري الذي يحول الدروع والأسلحة إلى مخططات (Blueprints).",
                     englishDescription: "Prehistoric shark that converts items into blueprints."),
        StoreModItem(id: "934881", game: .arkAscended, name: "Shiny! Dinos Ascended", category: "ديناصورات",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/915/980/256/256/638373123456789012.png",
                     arabicDescription: "يضيف ديناصورات ملونة ونادرة (Shiny) بقدرات خاصة ومستويات عالية في أنحاء الخريطة.",
                     englishDescription: "Spawns rare variant dinos with special colors and abilities."),
        StoreModItem(id: "937112", game: .arkAscended, name: "Custom Dino Levels", category: "توازن",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/919/620/256/256/638379123456789012.png",
                     arabicDescription: "يعدل توزيع مستويات الديناصورات البرية بحيث تظهر ديناصورات بمستويات عالية (130-150) بكثرة.",
                     englishDescription: "Balances wild dino level spawns so high-level dinos appear more frequently."),
        StoreModItem(id: "941205", game: .arkAscended, name: "Paleo ARK: Evolution", category: "ديناصورات",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/926/110/256/256/638390123456789012.png",
                     arabicDescription: "يعيد تصميم الريكس والغيغا بتفاصيل واقعية وقدرات هجومية جديدة كلياً.",
                     englishDescription: "Overhauls Rex and Giga models with new abilities."),
        
        // 5. مودات التحدي والزعماء والأسلحة
        StoreModItem(id: "936457", game: .arkAscended, name: "Primal Chaos", category: "تحدي",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/918/654/256/256/638377581249120312.png",
                     arabicDescription: "مود ضخم يضيف ديناصورات خرافية وعناصر نارية وكهربائية وزعماء جدد بمستويات صعوبة أسطورية.",
                     englishDescription: "Overhaul mod adding elemental, demonic, and boss tier dinos."),
        StoreModItem(id: "945880", game: .arkAscended, name: "Omega Ascended", category: "تحدي",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/933/412/256/256/638401234567890123.png",
                     arabicDescription: "يضيف نظام تصنيف فريد للديناصورات (كوسميك، ناري، جليدي) مع قدرات خارقة.",
                     englishDescription: "Adds tiered cosmic, elemental, and unique variant creatures."),
        StoreModItem(id: "939012", game: .arkAscended, name: "Dragon Kingdom", category: "تحدي",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/922/410/256/256/638384123456789012.png",
                     arabicDescription: "يضيف أنواعاً متعددة من التنانين القابلة للترويض والركوب بأسلحة نارية وجليدية.",
                     englishDescription: "Adds rideable elemental dragons to the game."),
        StoreModItem(id: "933771", game: .arkAscended, name: "Admin Panel (لوحة الأدمن)", category: "إدارة",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/914/312/256/256/638370123456789012.png",
                     arabicDescription: "لوحة تحكم للأدمن داخل اللعبة لاستدعاء الديناصورات وتنظيف السيرفر والتحكم بالطقس.",
                     englishDescription: "In-game admin menu for spawning dinos, items, and server cleanup."),
        StoreModItem(id: "931550", game: .arkAscended, name: "Solo Farm Mod", category: "أتمتة",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/910/820/256/256/638364123456789012.png",
                     arabicDescription: "يسمح للديناصورات بالضرب والتجميع تلقائياً أثناء حملها بطائر الأرجنتافيس أو الكويتزال.",
                     englishDescription: "Allows carried dinos to auto-harvest resources for solo players."),
        StoreModItem(id: "932884", game: .arkAscended, name: "Imbue and Upgrade Station", category: "أسلحة",
                     imageURL: "https://media.forgecdn.net/avatars/thumbnails/912/890/256/256/638368123456789012.png",
                     arabicDescription: "إضافة خصائص سحرية وعناصر قوة للأسلحة والدروع.",
                     englishDescription: "Imbue weapons and armor with elemental bonuses."),
        
        // --- Minecraft ---
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
        
        // --- FiveM ---
        StoreModItem(id: "qb-core", game: .fivem, name: "QBCore Framework", category: "حياة واقعية",
                     imageURL: "https://avatars.githubusercontent.com/u/81791099?s=200&v=4",
                     arabicDescription: "النظام الأساسي المتكامل لسيرفرات الحياة الواقعية (وظائف، بنوك، شرطة، عصابات، ومعارض سيارات).",
                     englishDescription: "Complete Roleplay framework for FiveM servers."),
        StoreModItem(id: "pma-voice", game: .fivem, name: "pma-voice (راديو وصوت)", category: "صوتيات",
                     imageURL: "https://avatars.githubusercontent.com/u/40129634?s=200&v=4",
                     arabicDescription: "نظام المحادثة الصوتية المحيطية والراديو والاتصال الهاتفي داخل سيرفر FiveM.",
                     englishDescription: "Proximity voice chat and radio system for FiveM."),
        
        // --- Rust ---
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
    
    // حفظ فوري ومضمون في ذاكرة الهاتف
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
    
    // حفظ التعديلات وإرسال رسالة تحذير داخل السيرفر بإعادة التشغيل بعد 20 ثانية
    func saveConfigAndScheduleRestart(serverId: String, newConfig: FullServerConfig, changesList: [String]) {
        guard let idx = servers.firstIndex(where: { $0.id == serverId }) else { return }
        servers[idx].config = newConfig
        
        let broadcastMsg = "ServerChat ⚠️ تنبيه من الإدارة: تم حفظ تعديلات جديدة! سيعاد تشغيل السيرفر تلقائياً بعد 20 ثانية..."
        servers[idx].consoleLogs.append("[\(currentUserName)] حفظ التعديلات: \(changesList.joined(separator: " | "))")
        servers[idx].consoleLogs.append("[Broadcast] ⚠️ تنبيه داخل السيرفر: بعد 20 ثانية سيسوي السيرفر إعادة تشغيل!")
        
        logActivity(serverName: servers[idx].name, action: changesList.first ?? "تحديث إعدادات السيرفر", category: "config")
        persistServers()
        
        // إرسال رسالة التحذير إلى السيرفر الفعلي إذا كان مربوطاً بـ API
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
        
        // بدء العد التنازلي 20 ثانية
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
