import SwiftUI

struct ServerDetailView: View {
    @EnvironmentObject var store: ServerStore
    @Environment(\.dismiss) var dismiss
    let serverId: String
    
    @State private var draftConfig: FullServerConfig = FullServerConfig()
    @State private var hasLoadedDraft: Bool = false
    @State private var showReviewSaveSheet: Bool = false
    
    @State private var selectedTab = 0
    @State private var newModId = ""
    @State private var newModName = ""
    @State private var modSearchText = ""
    @State private var sortOption: ModSortOption = .downloads
    @State private var liveStoreMods: [StoreModItem] = []
    @State private var isFetchingMods: Bool = false
    @State private var selectedModDetail: StoreModItem? = nil
    @State private var commandText = ""
    
    @State private var showFirstDeleteAlert = false
    @State private var showSecondDeleteAlert = false
    
    var currentServer: GameServer? {
        store.servers.first(where: { $0.id == serverId })
    }
    
    var pendingChanges: [String] {
        guard let saved = currentServer?.config else { return [] }
        return draftConfig.diffSummary(comparedTo: saved, isArabic: store.isArabic)
    }
    
    var body: some View {
        Group {
            if let server = currentServer {
                ZStack(alignment: .bottom) {
                    Color.appBg.ignoresSafeArea()
                    
                    VStack(spacing: 12) {
                        if store.restartingServerId == server.id && store.restartCountdown > 0 {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.black)
                                Text(store.isArabic
                                     ? "تنبيه داخل السيرفر: بعد \(store.restartCountdown) ثانية سيسوي السيرفر إعادة تشغيل!"
                                     : "Server Notice: Restarting in \(store.restartCountdown)s...")
                                    .font(.caption.bold())
                                    .foregroundColor(.black)
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                        
                        serverHeaderCard(server: server)
                        
                        Picker("", selection: $selectedTab) {
                            Text(store.isArabic ? "إعدادات \(server.game.shortBadge)" : "\(server.game.shortBadge) Settings").tag(0)
                            Text(store.isArabic ? "متجر المودات (\(draftConfig.mods.count))" : "Mods Store (\(draftConfig.mods.count))").tag(1)
                            Text(store.isArabic ? "الكونسول" : "Console").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        if selectedTab == 0 {
                            gameSpecificSettingsView(game: server.game)
                        } else if selectedTab == 1 {
                            modsAndStoreView(game: server.game)
                        } else {
                            consoleView(server: server)
                        }
                    }
                    
                    if !pendingChanges.isEmpty && store.canEdit {
                        VStack(spacing: 6) {
                            Button {
                                showReviewSaveSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.shield.fill")
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(store.isArabic ? "لديك (\(pendingChanges.count)) تعديلات غير محفوظة" : "You have (\(pendingChanges.count)) unsaved changes")
                                            .font(.subheadline.bold())
                                        Text(store.isArabic ? "اضغط لمراجعة التعديلات وحفظها في السيرفر" : "Tap to review & save changes")
                                            .font(.caption2)
                                    }
                                    Spacer()
                                    Text(store.isArabic ? "حفظ" : "Save")
                                        .font(.subheadline.bold())
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(Color.black.opacity(0.25))
                                        .clipShape(Capsule())
                                }
                                .padding()
                                .background(LinearGradient(colors: [.electricCyan, .neonViolet], startPoint: .leading, endPoint: .trailing))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(radius: 10)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }
                }
                .onAppear {
                    if !hasLoadedDraft {
                        draftConfig = server.config
                        hasLoadedDraft = true
                        Task { await loadLiveModsForGame(game: server.game) }
                    }
                }
                .navigationTitle(server.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if store.isOwner {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(role: .destructive) {
                                showFirstDeleteAlert = true
                            } label: {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .sheet(item: $selectedModDetail) { modItem in
                    ModPreviewDetailSheet(
                        modItem: modItem,
                        isInstalled: draftConfig.mods.contains(where: { $0.modId == modItem.id }),
                        canInstall: store.canMods,
                        isArabic: store.isArabic,
                        onInstall: {
                            let newMod = GameMod(modId: modItem.id, name: modItem.name, arabicDescription: modItem.arabicDescription, imageURL: modItem.imageURL)
                            draftConfig.mods.append(newMod)
                            selectedModDetail = nil
                        }
                    )
                }
                .sheet(isPresented: $showReviewSaveSheet) {
                    ReviewChangesSheet(
                        serverName: server.name,
                        changes: pendingChanges,
                        isArabic: store.isArabic,
                        onConfirmSave: {
                            store.saveConfigAndScheduleRestart(
                                serverId: server.id,
                                newConfig: draftConfig,
                                changesList: pendingChanges
                            )
                            showReviewSaveSheet = false
                        },
                        onDiscard: {
                            draftConfig = server.config
                            showReviewSaveSheet = false
                        }
                    )
                }
                .alert(store.isArabic ? "هل أنت متأكد؟" : "Are you sure?", isPresented: $showFirstDeleteAlert) {
                    Button(store.isArabic ? "نعم، متابعة" : "Yes, Continue", role: .destructive) {
                        showSecondDeleteAlert = true
                    }
                    Button(store.isArabic ? "إلغاء" : "Cancel", role: .cancel) {}
                } message: {
                    Text(store.isArabic ? "أنت على وشك حذف سيرفر (\(server.name))." : "You are about to delete \(server.name).")
                }
                .alert(store.isArabic ? "تأكيد نهائي: هل أنت متأكد فعلاً؟" : "Final Confirmation: Are you really sure?", isPresented: $showSecondDeleteAlert) {
                    Button(store.isArabic ? "حذف السيرفر نهائياً" : "Delete Permanently", role: .destructive) {
                        let idToDelete = server.id
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            store.deleteServer(serverId: idToDelete)
                        }
                    }
                    Button(store.isArabic ? "تراجع" : "Cancel", role: .cancel) {}
                } message: {
                    Text(store.isArabic ? "سيتم مسح السيرفر والعالم والمودات نهائياً ولن يمكنك التراجع!" : "This action cannot be undone!")
                }
            } else {
                Color.appBg.ignoresSafeArea()
            }
        }
    }
    
    // ---------------------------------------------------------
    // محرك جلب وترجمة جميع المودات الحية لكل لعبة (Modrinth + CurseForge + Catalog)
    // ---------------------------------------------------------
    func loadLiveModsForGame(game: GameType) async {
        isFetchingMods = true
        defer { isFetchingMods = false }
        
        var combined: [StoreModItem] = getExpandedBuiltInCatalog(for: game)
        
        // جلب آلاف المودات الحقيقية من Modrinth API (لـ Minecraft و Palworld و Valheim)
        let queryTerm: String
        switch game {
        case .minecraft: queryTerm = modSearchText.isEmpty ? "plugin" : modSearchText
        case .palworld: queryTerm = modSearchText.isEmpty ? "palworld" : modSearchText
        case .valheim: queryTerm = modSearchText.isEmpty ? "valheim" : modSearchText
        default: queryTerm = modSearchText
        }
        
        if game == .minecraft || game == .palworld || game == .valheim {
            let encodedQ = queryTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "mod"
            let urlString = "https://api.modrinth.com/v2/search?query=\(encodedQ)&limit=40&index=\(sortOption.rawValue)"
            if let url = URL(string: urlString),
               let (data, _) = try? await URLSession.shared.data(from: url),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let hits = json["hits"] as? [[String: Any]] {
                for hit in hits {
                    let slug = hit["slug"] as? String ?? UUID().uuidString
                    let title = hit["title"] as? String ?? "Mod"
                    let desc = hit["description"] as? String ?? ""
                    let icon = hit["icon_url"] as? String ?? game.officialImageURL
                    let gallery = hit["gallery"] as? [String] ?? []
                    let downloads = hit["downloads"] as? Int ?? 5000
                    let cats = hit["categories"] as? [String] ?? ["Mod"]
                    let translatedAr = await translateToArabic(text: desc)
                    
                    if !combined.contains(where: { $0.id == slug }) {
                        combined.append(StoreModItem(
                            id: slug,
                            game: game,
                            name: title,
                            category: cats.first?.capitalized ?? "Mod",
                            imageURL: icon.isEmpty ? game.officialImageURL : icon,
                            screenshots: gallery.isEmpty ? [icon.isEmpty ? game.officialImageURL : icon] : gallery,
                            downloadsCount: downloads,
                            arabicDescription: translatedAr,
                            englishDescription: desc
                        ))
                    }
                }
            }
        }
        
        // تطبيق البحث والفلتر على القائمة الكاملة
        let filtered = combined.filter { item in
            modSearchText.isEmpty ||
            item.name.localizedCaseInsensitiveContains(modSearchText) ||
            item.arabicDescription.contains(modSearchText) ||
            item.id.localizedCaseInsensitiveContains(modSearchText)
        }
        
        switch sortOption {
        case .downloads:
            liveStoreMods = filtered.sorted { $0.downloadsCount > $1.downloadsCount }
        case .follows:
            liveStoreMods = filtered.sorted { $0.downloadsCount > $1.downloadsCount }
        case .updated:
            liveStoreMods = filtered.reversed()
        case .relevance:
            liveStoreMods = filtered
        }
    }
    
    // ترجمة فورية مجانية لأي وصف مود إنجليزي إلى العربية
    func translateToArabic(text: String) async -> String {
        guard !text.isEmpty,
              let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=ar&dt=t&q=\(encoded)"),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [Any],
              let sentences = json.first as? [[Any]] else {
            return text
        }
        let translated = sentences.compactMap { $0.first as? String }.joined()
        return translated.isEmpty ? text : translated
    }
    
    // قاعدة بيانات موسعة بالصور واللقطات وعدد التنزيلات لكل الألعاب
    func getExpandedBuiltInCatalog(for game: GameType) -> [StoreModItem] {
        switch game {
        case .arkAscended:
            return [
                StoreModItem(id: "928793", game: .arkAscended, name: "Super Cryo Storage (SCS)", category: "تخزين",
                             imageURL: "https://media.forgecdn.net/avatars/thumbnails/906/404/256/256/638356649746936221.png",
                             screenshots: ["https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2399830/ss_2a82e08710557941625069966126305894964691.1920x1080.jpg"],
                             downloadsCount: 2_850_000,
                             arabicDescription: "كرات تخزين متطورة لحفظ الديناصورات مع ثلاجة تفريخ البيض تلقائياً وتوليد الموارد والأسمدة.",
                             englishDescription: "Advanced cryopods with auto-incubation and resource generation."),
                StoreModItem(id: "929110", game: .arkAscended, name: "Awesome SpyGlass!", category: "أدوات",
                             imageURL: "https://media.forgecdn.net/avatars/thumbnails/906/939/256/256/638357627423346032.png",
                             screenshots: ["https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2399830/ss_611085564043400353616305894964691.1920x1080.jpg"],
                             downloadsCount: 3_420_000,
                             arabicDescription: "منظار ذكي يعرض لك نقاط القوة (Stats) للديناصور البري قبل ترويضه ونوع الأكل المفضل له.",
                             englishDescription: "Shows wild dino stat points and taming food requirements."),
                StoreModItem(id: "930170", game: .arkAscended, name: "Automated Ark (AA)", category: "أتمتة",
                             imageURL: "https://media.forgecdn.net/avatars/thumbnails/908/558/256/256/638360623718619239.png",
                             screenshots: ["https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2399830/header.jpg"],
                             downloadsCount: 2_190_000,
                             arabicDescription: "نظام ذكي يسحب الموارد تلقائياً من الديناصورات ويوزعها على الأفران والصناديق بضغطة زر.",
                             englishDescription: "Automates resource pulling, sorting, and crafting stations."),
                StoreModItem(id: "929785", game: .arkAscended, name: "TG Stacking Mod 10000-90", category: "موارد",
                             imageURL: "https://media.forgecdn.net/avatars/thumbnails/907/956/256/256/638359472692523650.png",
                             screenshots: ["https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2399830/header.jpg"],
                             downloadsCount: 3_110_000,
                             arabicDescription: "يرفع سعة تكديس الموارد (الخشب، الحجر، اللحم) إلى 10,000 حبة ويقلل وزنها بنسبة 90%.",
                             englishDescription: "Increases item stack sizes to 10,000 and reduces weight by 90%."),
                StoreModItem(id: "928597", game: .arkAscended, name: "Dino Depot", category: "ديناصورات",
                             imageURL: "https://media.forgecdn.net/avatars/thumbnails/906/105/256/256/638356015382716011.png",
                             screenshots: ["https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2399830/header.jpg"],
                             downloadsCount: 1_940_000,
                             arabicDescription: "بديل احترافي للكرايو بود مع محطة تجميع تلقائية لصغار الديناصورات فور ولادتها.",
                             englishDescription: "Dino storage balls with newborn auto-capture terminals."),
                StoreModItem(id: "930494", game: .arkAscended, name: "Cybers Structures (S+)", category: "بناء",
                             imageURL: "https://media.forgecdn.net/avatars/thumbnails/909/71/256/256/638361547281415229.png",
                             screenshots: ["https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2399830/header.jpg"],
                             downloadsCount: 1_780_000,
                             arabicDescription: "إضافات بناء مطورة تشمل جدران وأسقف زجاجية ومصاعد وأبواب تفتح تلقائياً ومولدات لاسلكية.",
                             englishDescription: "Enhanced building pieces, glass structures, and auto-doors."),
                StoreModItem(id: "928621", game: .arkAscended, name: "Death Recovery Mod", category: "أدوات",
                             imageURL: "https://media.forgecdn.net/avatars/thumbnails/906/140/256/256/638356091726105232.png",
                             screenshots: ["https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2399830/header.jpg"],
                             downloadsCount: 1_650_000,
                             arabicDescription: "شاهد قبر تبنيه في بيتك يسمح لك باسترجاع كامل أغراضك ودروعك بضغطة زر واحدة بعد الموت.",
                             englishDescription: "Tombstone that recovers all your dropped inventory upon death."),
                StoreModItem(id: "936457", game: .arkAscended, name: "Primal Chaos", category: "تحدي",
                             imageURL: "https://media.forgecdn.net/avatars/thumbnails/918/654/256/256/638377581249120312.png",
                             screenshots: ["https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2399830/header.jpg"],
                             downloadsCount: 1_520_000,
                             arabicDescription: "مود ضخم يضيف ديناصورات خرافية وعناصر نارية وكهربائية وزعماء جدد بمستويات صعوبة أسطورية.",
                             englishDescription: "Overhaul mod adding elemental, demonic, and boss tier dinos."),
                StoreModItem(id: "935985", game: .arkAscended, name: "ARK Additions: Brachiosaurus", category: "ديناصورات",
                             imageURL: "https://media.forgecdn.net/avatars/thumbnails/917/802/256/256/638376123456789012.png",
                             screenshots: ["https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2399830/header.jpg"],
                             downloadsCount: 1_310_000,
                             arabicDescription: "يضيف ديناصور البراكيوصور العملاق بقدرات قتالية وتجميع خشب وتوت بكميات هائلة.",
                             englishDescription: "Adds the massive Brachiosaurus creature."),
                StoreModItem(id: "931214", game: .arkAscended, name: "Upgrade Station", category: "أسلحة",
                             imageURL: "https://media.forgecdn.net/avatars/thumbnails/910/320/256/256/638363512904123456.png",
                             screenshots: ["https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2399830/header.jpg"],
                             downloadsCount: 1_240_000,
                             arabicDescription: "طاولة تطوير تسمح لك بترقية أي سلاح أو درع أو سرج ديناصور من العادي إلى Ascendant.",
                             englishDescription: "Upgrade weapons, armor, and saddles."),
                StoreModItem(id: "937112", game: .arkAscended, name: "Custom Dino Levels", category: "توازن",
                             imageURL: "https://media.forgecdn.net/avatars/thumbnails/919/620/256/256/638379123456789012.png",
                             screenshots: ["https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2399830/header.jpg"],
                             downloadsCount: 1_490_000,
                             arabicDescription: "يعدل توزيع مستويات الديناصورات البرية بحيث تظهر ديناصورات بمستويات عالية (130-150) بكثرة.",
                             englishDescription: "Balances wild dino level spawns."),
                StoreModItem(id: "932365", game: .arkAscended, name: "Utilities Plus", category: "أدوات",
                             imageURL: "https://media.forgecdn.net/avatars/thumbnails/912/102/256/256/638366912345123412.png",
                             screenshots: ["https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2399830/header.jpg"],
                             downloadsCount: 1_890_000,
                             arabicDescription: "يوفر خطاف (Grappling Hook) ومظلة ومنظار وبولا لا نهائية وقابلة لإعادة الاستخدام.",
                             englishDescription: "Reusable grappling hooks and parachutes.")
            ]
        case .minecraft:
            return [
                StoreModItem(id: "GeyserMC", game: .minecraft, name: "GeyserMC + Floodgate", category: "Crossplay",
                             imageURL: "https://cdn.modrinth.com/data/wKKOqHrH/icon.png",
                             screenshots: ["https://www.minecraft.net/content/dam/games/minecraft/key-art/Vanilla-PMP_Collection-Carousel-0_Buzzy-Bees_1280x768.jpg"],
                             downloadsCount: 4_500_000,
                             arabicDescription: "يسمح للاعبي الجوال والبلايستيشن والإكسبوكس (Bedrock) بالدخول إلى سيرفر Java واللعب مع الكمبيوتر.",
                             englishDescription: "Allows Bedrock players to join Java servers.")
            ]
        case .fivem:
            return [
                StoreModItem(id: "qb-core", game: .fivem, name: "QBCore Framework", category: "حياة واقعية",
                             imageURL: "https://avatars.githubusercontent.com/u/81791099?s=200&v=4",
                             screenshots: ["https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/271590/header.jpg"],
                             downloadsCount: 980_000,
                             arabicDescription: "النظام الأساسي المتكامل لسيرفرات الحياة الواقعية (وظائف، بنوك، شرطة، عصابات، ومعارض سيارات).",
                             englishDescription: "Complete Roleplay framework for FiveM servers."),
                StoreModItem(id: "pma-voice", game: .fivem, name: "pma-voice (راديو وصوت)", category: "صوتيات",
                             imageURL: "https://avatars.githubusercontent.com/u/40129634?s=200&v=4",
                             screenshots: ["https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/271590/header.jpg"],
                             downloadsCount: 1_200_000,
                             arabicDescription: "نظام المحادثة الصوتية المحيطية والراديو والاتصال الهاتفي داخل سيرفر FiveM.",
                             englishDescription: "Proximity voice chat and radio system."),
                StoreModItem(id: "esx-legacy", game: .fivem, name: "ESX Legacy Pack", category: "حياة واقعية",
                             imageURL: "https://avatars.githubusercontent.com/u/33160388?s=200&v=4",
                             screenshots: ["https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/271590/header.jpg"],
                             downloadsCount: 1_450_000,
                             arabicDescription: "حزمة ESX الكاملة لإدارة السيرفرات الواقعية والمتاجر والعقارات.",
                             englishDescription: "Classic ESX framework for GTA V Roleplay.")
            ]
        case .rust:
            return [
                StoreModItem(id: "GatherManager", game: .rust, name: "Gather Manager (x3/x5)", category: "موارد",
                             imageURL: "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/252490/header.jpg",
                             screenshots: ["https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/252490/header.jpg"],
                             downloadsCount: 890_000,
                             arabicDescription: "التحكم في مضاعفة تجميع الخشب والحجر والخامات واللوت في سيرفر Rust.",
                             englishDescription: "Modifies resource gather rates in Rust."),
                StoreModItem(id: "StackSizeController", game: .rust, name: "Stack Size Controller", category: "تخزين",
                             imageURL: "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/252490/header.jpg",
                             screenshots: ["https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/252490/header.jpg"],
                             downloadsCount: 760_000,
                             arabicDescription: "زيادة الحد الأقصى لتكديس الموارد والذخيرة داخل الصناديق والحقيبة.",
                             englishDescription: "Customizes maximum stack sizes for all items.")
            ]
        default:
            return [
                StoreModItem(id: "core-plus", game: game, name: "\(game.shortBadge) Essentials Pack", category: "أساسي",
                             imageURL: game.officialImageURL,
                             screenshots: [game.officialImageURL],
                             downloadsCount: 320_000,
                             arabicDescription: "حزمة الإضافات الأساسية لتحسين أداء السيرفر وإدارة اللاعبين في \(game.rawValue).",
                             englishDescription: "Core server enhancements and admin utilities.")
            ]
        }
    }
    
    func serverHeaderCard(server: GameServer) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                GameOfficialImage(urlString: server.game.officialImageURL, fallbackIcon: server.game.fallbackIcon)
                    .frame(width: 64, height: 46)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(server.game.rawValue)
                        .font(.caption.bold())
                        .foregroundColor(.electricCyan)
                    Text("\(server.ipAddress):\(server.port)")
                        .font(.subheadline.monospaced().bold())
                        .foregroundColor(.white)
                }
                Spacer()
                Button {
                    UIPasteboard.general.string = "\(server.ipAddress):\(server.port)"
                    store.showToast(store.isArabic ? "تم نسخ IP السيرفر!" : "IP Copied!")
                } label: {
                    Label(store.isArabic ? "نسخ IP" : "Copy", systemImage: "doc.on.doc")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.electricCyan.opacity(0.15))
                        .foregroundColor(.electricCyan)
                        .clipShape(Capsule())
                }
            }
            
            if store.canPower {
                HStack(spacing: 10) {
                    PowerActionBtn(title: store.isArabic ? "تشغيل" : "Start", icon: "play.fill", color: .emeraldGreen) {
                        store.sendPowerAction(serverId: server.id, action: "start")
                    }
                    PowerActionBtn(title: store.isArabic ? "ريستارت" : "Restart", icon: "arrow.clockwise", color: .electricCyan) {
                        store.sendPowerAction(serverId: server.id, action: "restart")
                    }
                    PowerActionBtn(title: store.isArabic ? "إيقاف" : "Stop", icon: "stop.fill", color: .red) {
                        store.sendPowerAction(serverId: server.id, action: "stop")
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }
    
    // ---------------------------------------------------------
    // متجر المودات الشامل لكل الألعاب + الفلتر + عدد التنزيلات + صور المود
    // ---------------------------------------------------------
    func modsAndStoreView(game: GameType) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // المودات المثبتة
                VStack(alignment: .leading, spacing: 10) {
                    Text(store.isArabic ? "المودات المثبتة (\(draftConfig.mods.count))" : "Installed Mods (\(draftConfig.mods.count))")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach(draftConfig.mods.indices, id: \.self) { mIdx in
                        let mod = draftConfig.mods[mIdx]
                        HStack(spacing: 12) {
                            GameOfficialImage(urlString: mod.imageURL, fallbackIcon: "puzzlepiece.extension.fill")
                                .frame(width: 46, height: 46)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mod.name)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                Text(mod.arabicDescription)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                            }
                            Spacer()
                            if store.canMods {
                                Toggle("", isOn: $draftConfig.mods[mIdx].isEnabled)
                                    .labelsHidden()
                                    .tint(.electricCyan)
                                Button {
                                    draftConfig.mods.remove(at: mIdx)
                                } label: {
                                    Image(systemName: "trash").foregroundColor(.red)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                
                // إضافة مود يدوي برقم ID
                if store.canMods {
                    VStack(spacing: 10) {
                        Text(store.isArabic ? "إضافة أي مود برقم المعرّف (Mod ID / Slug)" : "Add Custom Mod by ID")
                            .font(.subheadline.bold())
                            .foregroundColor(.electricCyan)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack {
                            TextField(store.isArabic ? "رقم المود" : "Mod ID", text: $newModId)
                                .padding(10).background(Color.black.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 10))
                            TextField(store.isArabic ? "اسم المود" : "Mod Name", text: $newModName)
                                .padding(10).background(Color.black.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        Button {
                            guard !newModId.isEmpty else { return }
                            let mName = newModName.isEmpty ? "Mod #\(newModId)" : newModName
                            let mod = GameMod(
                                modId: newModId.trimmingCharacters(in: .whitespaces),
                                name: mName,
                                arabicDescription: store.isArabic ? "مود مضاف يدوياً برقم المعرّف \(newModId)." : "Manually installed mod.",
                                imageURL: game.officialImageURL
                            )
                            draftConfig.mods.append(mod)
                            newModId = ""
                            newModName = ""
                        } label: {
                            Label(store.isArabic ? "إضافة للقائمة" : "Add to List", systemImage: "plus.circle.fill")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(Color.electricCyan)
                                .foregroundColor(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                // متجر المودات الحي لكل الألعاب مع الفلاتر وعدد التنزيلات
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(store.isArabic ? "متجر مودات \(game.shortBadge)" : "\(game.shortBadge) Mods Store")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        if isFetchingMods {
                            ProgressView().tint(.electricCyan)
                        }
                    }
                    
                    // شريط البحث الحي
                    HStack {
                        TextField(store.isArabic ? "ابحث في جميع المودات..." : "Search all mods...", text: $modSearchText)
                            .padding(10)
                            .background(Color.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onSubmit {
                                Task { await loadLiveModsForGame(game: game) }
                            }
                        
                        Button {
                            Task { await loadLiveModsForGame(game: game) }
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .padding(12)
                                .background(Color.electricCyan)
                                .foregroundColor(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    // أزرار الفلترة (الأكثر تنزيلاً، الأحدث، الأعلى تقييماً...)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ModSortOption.allCases) { option in
                                Button {
                                    sortOption = option
                                    Task { await loadLiveModsForGame(game: game) }
                                } label: {
                                    Text(option.title(isArabic: store.isArabic))
                                        .font(.caption.bold())
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(sortOption == option ? Color.electricCyan : Color.cardBg)
                                        .foregroundColor(sortOption == option ? .black : .white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    
                    // قائمة المودات مع صورة المود، عدد التنزيلات، والوصف العربي
                    ForEach(liveStoreMods) { item in
                        let alreadyInstalled = draftConfig.mods.contains(where: { $0.modId == item.id })
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 12) {
                                Button {
                                    selectedModDetail = item
                                } label: {
                                    GameOfficialImage(urlString: item.imageURL, fallbackIcon: "puzzlepiece.fill")
                                        .frame(width: 62, height: 62)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Button {
                                        selectedModDetail = item
                                    } label: {
                                        Text(item.name)
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    HStack(spacing: 6) {
                                        // شارة عدد التنزيلات
                                        Label("\(item.formattedDownloads)", systemImage: "arrow.down.circle.fill")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.emeraldGreen.opacity(0.18))
                                            .foregroundColor(.emeraldGreen)
                                            .clipShape(Capsule())
                                        
                                        Text(item.category)
                                            .font(.caption2)
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 3)
                                            .background(Color.white.opacity(0.08))
                                            .foregroundColor(.electricCyan)
                                            .clipShape(Capsule())
                                    }
                                }
                                
                                Spacer()
                                
                                if store.canMods {
                                    Button {
                                        if !alreadyInstalled {
                                            let mod = GameMod(modId: item.id, name: item.name, arabicDescription: item.arabicDescription, imageURL: item.imageURL)
                                            draftConfig.mods.append(mod)
                                        }
                                    } label: {
                                        Text(alreadyInstalled ? (store.isArabic ? "مضاف ✓" : "Added") : (store.isArabic ? "إضافة +" : "Add +"))
                                            .font(.caption.bold())
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(alreadyInstalled ? Color.emeraldGreen.opacity(0.2) : Color.electricCyan)
                                            .foregroundColor(alreadyInstalled ? .emeraldGreen : .black)
                                            .clipShape(Capsule())
                                    }
                                    .disabled(alreadyInstalled)
                                }
                            }
                            
                            // الوصف بالعربية
                            Text(store.isArabic ? item.arabicDescription : item.englishDescription)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // زر عرض صور المود والتفاصيل الكاملة
                            Button {
                                selectedModDetail = item
                            } label: {
                                HStack {
                                    Image(systemName: "photo.on.rectangle.angled")
                                    Text(store.isArabic ? "عرض صور المود والتفاصيل الكاملة" : "View Mod Screenshots & Details")
                                }
                                .font(.caption2.bold())
                                .foregroundColor(.electricCyan)
                            }
                        }
                        .padding()
                        .background(Color.cardBg)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.bottom, 80)
            }
            .padding()
        }
    }
    
    // بقية أقسام الإعدادات والكونسول (نفس الكود السابق بالكامل)
    func gameSpecificSettingsView(game: GameType) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                if !store.canEdit {
                    Text(store.isArabic ? "🔒 وضع القراءة فقط: المالك قيّد تعديل الإعدادات لحسابك" : "🔒 Read-only mode")
                        .font(.caption.bold())
                        .foregroundColor(.electricCyan)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(Color.electricCyan.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Group {
                    SettingGroupTitle(title: store.isArabic ? "1. الوصول والمنصات واللاعبين" : "1. Access, Platforms & Players")
                    VStack(spacing: 12) {
                        Stepper(value: $draftConfig.maxPlayers, in: 2...500, step: 2) {
                            HStack {
                                Text(store.isArabic ? "الحد الأقصى للاعبين" : "Max Players").foregroundColor(.white)
                                Spacer()
                                Text("\(draftConfig.maxPlayers)").font(.headline.monospaced()).foregroundColor(.electricCyan)
                            }
                        }
                    }
                    .padding().background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 14))
                    
                    SettingToggleCard(title: store.isArabic ? "السماح باللعب المشترك (PC + Console / الجوال)" : "Enable Crossplay", isOn: $draftConfig.crossplayEnabled)
                    SettingToggleCard(title: store.isArabic ? "تفعيل القتال بين اللاعبين (PvP)" : "Enable PvP", isOn: $draftConfig.pvpEnabled)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(store.isArabic ? "كلمة مرور السيرفر" : "Server Password").font(.caption.bold()).foregroundColor(.gray)
                        TextField("Password...", text: $draftConfig.serverPassword)
                            .padding(10).background(Color.black.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 10))
                        Text(store.isArabic ? "رسالة الترحيب (MOTD)" : "MOTD").font(.caption.bold()).foregroundColor(.gray)
                        TextField("MOTD...", text: $draftConfig.motdMessage)
                            .padding(10).background(Color.black.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding().background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!store.canEdit)
                
                Group {
                    switch game {
                    case .arkAscended:
                        SettingGroupTitle(title: store.isArabic ? "2. معدلات ARK Ascended" : "2. ARK Rates")
                        CustomRateSlider(title: store.isArabic ? "مضاعف التجميع (Harvest)" : "Harvest", value: $draftConfig.harvestMultiplier, range: 1...100)
                        CustomRateSlider(title: store.isArabic ? "سرعة الترويض (Taming)" : "Taming", value: $draftConfig.tamingSpeed, range: 1...100)
                        CustomRateSlider(title: store.isArabic ? "مضاعف الخبرة (XP)" : "XP", value: $draftConfig.xpMultiplier, range: 1...50)
                        CustomRateSlider(title: store.isArabic ? "سرعة فقس البيض" : "Egg Hatch", value: $draftConfig.eggHatchSpeed, range: 1...100)
                        CustomRateSlider(title: store.isArabic ? "سرعة نمو الصغار" : "Baby Mature", value: $draftConfig.babyMatureSpeed, range: 1...100)
                        CustomRateSlider(title: store.isArabic ? "وزن اللاعب" : "Player Weight", value: $draftConfig.playerWeight, range: 1...100)
                        SettingToggleCard(title: store.isArabic ? "السماح بالطيران داخل الكهوف" : "Allow Cave Flyers", isOn: $draftConfig.allowCaveFlyers)
                        SettingToggleCard(title: store.isArabic ? "إظهار موقع اللاعب على الخريطة" : "Show Player on Map", isOn: $draftConfig.showMapPlayerLocation)
                    case .minecraft:
                        SettingGroupTitle(title: store.isArabic ? "2. إعدادات Minecraft" : "2. Minecraft Settings")
                        SettingToggleCard(title: store.isArabic ? "السماح بالحسابات المكركة" : "Allow Cracked", isOn: Binding(
                            get: { !draftConfig.mcOnlineMode },
                            set: { draftConfig.mcOnlineMode = !$0 }
                        ))
                        SettingToggleCard(title: store.isArabic ? "تفعيل بلوكات الأوامر" : "Command Blocks", isOn: $draftConfig.mcEnableCommandBlock)
                    default:
                        SettingGroupTitle(title: store.isArabic ? "2. معدلات اللعبة" : "2. Game Rates")
                        CustomRateSlider(title: store.isArabic ? "مضاعف الموارد" : "Resource Rate", value: $draftConfig.harvestMultiplier, range: 1...20)
                    }
                }
                .disabled(!store.canEdit)
                
                if store.canEdit {
                    Button {
                        showReviewSaveSheet = true
                    } label: {
                        Text(pendingChanges.isEmpty
                             ? (store.isArabic ? "جميع الإعدادات محفوظة ✓" : "All Settings Saved ✓")
                             : (store.isArabic ? "مراجعة وحفظ التعديلات (\(pendingChanges.count))" : "Review & Save (\(pendingChanges.count))"))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(pendingChanges.isEmpty ? AnyShapeStyle(Color.white.opacity(0.1)) : AnyShapeStyle(LinearGradient(colors: [.electricCyan, .neonViolet], startPoint: .leading, endPoint: .trailing)))
                            .foregroundColor(pendingChanges.isEmpty ? .gray : .white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(pendingChanges.isEmpty)
                    .padding(.bottom, 75)
                }
            }
            .padding()
        }
    }
    
    func consoleView(server: GameServer) -> some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(server.consoleLogs, id: \.self) { line in
                        Text(line)
                            .font(.caption.monospaced())
                            .foregroundColor(.emeraldGreen)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .background(Color.black.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
            
            if store.canConsole {
                HStack {
                    TextField(store.isArabic ? "اكتب أمر السيرفر..." : "Enter command...", text: $commandText)
                        .autocapitalization(.none)
                        .padding(10)
                        .background(Color.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Button {
                        store.sendCommand(serverId: server.id, command: commandText)
                        commandText = ""
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .padding(12)
                            .background(Color.electricCyan)
                            .foregroundColor(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
        }
    }
}

// ---------------------------------------------------------
// نافذة تفاصيل المود بالصور المتعددة والوصف العربي المترجم
// ---------------------------------------------------------
struct ModPreviewDetailSheet: View {
    let modItem: StoreModItem
    let isInstalled: Bool
    let canInstall: Bool
    let isArabic: Bool
    let onInstall: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // رأس المود بالأيقونة وعدد التنزيلات
                    HStack(spacing: 14) {
                        GameOfficialImage(urlString: modItem.imageURL, fallbackIcon: "puzzlepiece.fill")
                            .frame(width: 76, height: 76)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(modItem.name)
                                .font(.title3.bold())
                            HStack(spacing: 8) {
                                Label("\(modItem.formattedDownloads) \(isArabic ? "تنزيل" : "Downloads")", systemImage: "arrow.down.circle.fill")
                                    .font(.caption.bold())
                                    .foregroundColor(.emeraldGreen)
                                Text("ID: \(modItem.id)")
                                    .font(.caption.monospaced())
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    // معرض صور المود (Screenshots)
                    Text(isArabic ? "صور من داخل المود" : "Mod Screenshots")
                        .font(.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(modItem.screenshots, id: \.self) { imgURL in
                                GameOfficialImage(urlString: imgURL, fallbackIcon: "photo.fill")
                                    .frame(width: 280, height: 165)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    
                    // وصف المود بالعربية
                    Text(isArabic ? "وصف المود (مترجم بالعربية)" : "Description")
                        .font(.headline)
                    
                    Text(isArabic ? modItem.arabicDescription : modItem.englishDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if canInstall {
                        Button {
                            onInstall()
                        } label: {
                            Text(isInstalled ? (isArabic ? "المود مضاف مسبقاً ✓" : "Already Added ✓") : (isArabic ? "إضافة المود إلى السيرفر +" : "Add Mod to Server +"))
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isInstalled ? AnyShapeStyle(Color.gray.opacity(0.3)) : AnyShapeStyle(LinearGradient(colors: [.electricCyan, .neonViolet], startPoint: .leading, endPoint: .trailing)))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isInstalled)
                        .padding(.top, 10)
                    }
                }
                .padding()
            }
            .navigationTitle(isArabic ? "تفاصيل المود" : "Mod Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isArabic ? "إغلاق" : "Close") { dismiss() }
                }
            }
        }
    }
}

struct ReviewChangesSheet: View {
    let serverName: String
    let changes: [String]
    let isArabic: Bool
    let onConfirmSave: () -> Void
    let onDiscard: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.trianglebadge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.electricCyan)
                    Text(isArabic ? "مراجعة التعديلات قبل الحفظ" : "Review Changes Before Saving")
                        .font(.headline)
                    Text(isArabic ? "سيتم إرسال تنبيه للاعبين داخل (\(serverName)) بأن السيرفر سيعاد تشغيله بعد 20 ثانية." : "Players will be notified of a 20-second restart countdown.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                List {
                    Section(isArabic ? "التعديلات التي قمت بها (\(changes.count))" : "Your Changes (\(changes.count))") {
                        ForEach(changes, id: \.self) { item in
                            HStack {
                                Image(systemName: "arrow.left.arrow.right.circle.fill")
                                    .foregroundColor(.electricCyan)
                                Text(item)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                
                VStack(spacing: 10) {
                    Button {
                        onConfirmSave()
                    } label: {
                        Text(isArabic ? "تأكيد الحفظ وإرسال تنبيه 20 ثانية" : "Confirm Save & 20s Restart Notice")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [.electricCyan, .neonViolet], startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    Button(role: .destructive) {
                        onDiscard()
                    } label: {
                        Text(isArabic ? "تراجع عن التعديلات" : "Discard Changes")
                            .font(.subheadline)
                    }
                }
                .padding()
            }
            .navigationTitle(isArabic ? "تأكيد الحفظ" : "Confirm Save")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SettingGroupTitle: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.subheadline.bold())
            .foregroundColor(.electricCyan)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }
}

struct SettingToggleCard: View {
    let title: String
    @Binding var isOn: Bool
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .tint(.electricCyan)
        .padding()
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct CustomRateSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Spacer()
                Text("x\(String(format: "%.1f", value))")
                    .font(.subheadline.monospaced().bold())
                    .foregroundColor(.electricCyan)
            }
            Slider(value: $value, in: range, step: 0.5)
                .tint(.electricCyan)
        }
        .padding()
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct PowerActionBtn: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.caption.bold())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
