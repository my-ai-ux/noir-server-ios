import SwiftUI

struct ServerDetailView: View {
    @EnvironmentObject var store: ServerStore
    @Environment(\.dismiss) var dismiss
    let serverId: String
    
    // نسخة مسودة للتعديلات بحيث تظهر التعديلات ويطلب الحفظ
    @State private var draftConfig: FullServerConfig = FullServerConfig()
    @State private var hasLoadedDraft: Bool = false
    @State private var showReviewSaveSheet: Bool = false
    
    @State private var selectedTab = 0
    @State private var newModId = ""
    @State private var newModName = ""
    @State private var modSearchText = ""
    @State private var selectedModCategory = "الكل"
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
                        // شريط تحذير إعادة التشغيل بعد 20 ثانية داخل السيرفر
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
                            Text(store.isArabic ? "المودات (\(draftConfig.mods.count))" : "Mods (\(draftConfig.mods.count))").tag(1)
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
                    
                    // شريط الحفظ العائم يظهر تلقائياً عند وجود أي تعديل غير محفوظ
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
                // نافذة مراجعة التعديلات قبل الحفظ
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
                // تأكيد الحذف الأول
                .alert(store.isArabic ? "هل أنت متأكد؟" : "Are you sure?", isPresented: $showFirstDeleteAlert) {
                    Button(store.isArabic ? "نعم، متابعة" : "Yes, Continue", role: .destructive) {
                        showSecondDeleteAlert = true
                    }
                    Button(store.isArabic ? "إلغاء" : "Cancel", role: .cancel) {}
                } message: {
                    Text(store.isArabic ? "أنت على وشك حذف سيرفر (\(server.name))." : "You are about to delete \(server.name).")
                }
                // تأكيد الحذف الثاني النهائي (آمن بدون كراش)
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
                                Text(store.isArabic ? "الحد الأقصى للاعبين" : "Max Players")
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(draftConfig.maxPlayers)")
                                    .font(.headline.monospaced())
                                    .foregroundColor(.electricCyan)
                            }
                        }
                    }
                    .padding()
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    
                    SettingToggleCard(
                        title: store.isArabic ? "السماح باللعب المشترك (PC + Console / الجوال)" : "Enable Crossplay (PC + Console)",
                        isOn: $draftConfig.crossplayEnabled
                    )
                    
                    SettingToggleCard(
                        title: store.isArabic ? "تفعيل القتال بين اللاعبين (PvP)" : "Enable PvP",
                        isOn: $draftConfig.pvpEnabled
                    )
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(store.isArabic ? "كلمة مرور السيرفر (اتركها فارغة ليكون عام)" : "Server Password")
                            .font(.caption.bold()).foregroundColor(.gray)
                        TextField("Password...", text: $draftConfig.serverPassword)
                            .padding(10).background(Color.black.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        Text(store.isArabic ? "رسالة الترحيب (MOTD)" : "MOTD")
                            .font(.caption.bold()).foregroundColor(.gray)
                        TextField("MOTD...", text: $draftConfig.motdMessage)
                            .padding(10).background(Color.black.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding()
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!store.canEdit)
                
                Group {
                    switch game {
                    case .arkAscended:
                        arkSettingsSection()
                    case .minecraft:
                        minecraftSettingsSection()
                    case .fivem:
                        fivemSettingsSection()
                    case .rust:
                        rustSettingsSection()
                    case .palworld:
                        palworldSettingsSection()
                    case .cs2:
                        cs2SettingsSection()
                    case .terraria:
                        terrariaSettingsSection()
                    case .valheim:
                        valheimSettingsSection()
                    }
                }
                .disabled(!store.canEdit)
                
                // زر حفظ ثابت في أسفل الصفحة أيضاً
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
                    .padding(.bottom, 70)
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    func arkSettingsSection() -> some View {
        SettingGroupTitle(title: store.isArabic ? "2. خريطة ومعدلات ARK Ascended" : "2. ARK Map & Rates")
        
        VStack(alignment: .leading, spacing: 8) {
            Text(store.isArabic ? "الخريطة النشطة (Map)" : "Active Map")
                .font(.caption.bold()).foregroundColor(.gray)
            Picker("Map", selection: $draftConfig.mapName) {
                Text("The Island").tag("TheIsland_WP")
                Text("Scorched Earth").tag("ScorchedEarth_WP")
                Text("The Center").tag("TheCenter_WP")
                Text("Aberration").tag("Aberration_WP")
                Text("Extinction").tag("Extinction_WP")
            }
            .pickerStyle(.menu)
            .tint(.electricCyan)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        
        CustomRateSlider(title: store.isArabic ? "مضاعف التجميع (Harvest)" : "Harvest", value: $draftConfig.harvestMultiplier, range: 1...100)
        CustomRateSlider(title: store.isArabic ? "سرعة الترويض (Taming)" : "Taming", value: $draftConfig.tamingSpeed, range: 1...100)
        CustomRateSlider(title: store.isArabic ? "مضاعف الخبرة (XP)" : "XP", value: $draftConfig.xpMultiplier, range: 1...50)
        CustomRateSlider(title: store.isArabic ? "جودة اللوت (Loot Quality)" : "Loot Quality", value: $draftConfig.lootQuality, range: 1...10)
        CustomRateSlider(title: store.isArabic ? "تكديس الموارد (Stack Size)" : "Stack Size", value: $draftConfig.stackSizeMultiplier, range: 1...50)
        
        SettingGroupTitle(title: store.isArabic ? "3. التفريخ والتربية (Breeding)" : "3. Breeding")
        CustomRateSlider(title: store.isArabic ? "سرعة فقس البيض (Egg Hatch)" : "Egg Hatch", value: $draftConfig.eggHatchSpeed, range: 1...100)
        CustomRateSlider(title: store.isArabic ? "سرعة نمو الصغار (Baby Mature)" : "Baby Mature", value: $draftConfig.babyMatureSpeed, range: 1...100)
        CustomRateSlider(title: store.isArabic ? "مضاعف البصمة (Imprinting)" : "Imprinting", value: $draftConfig.babyImprintMultiplier, range: 1...20)
        
        SettingGroupTitle(title: store.isArabic ? "4. إحصائيات اللاعب والديناصورات والقوانين" : "4. Stats & World Rules")
        CustomRateSlider(title: store.isArabic ? "وزن اللاعب (Player Weight)" : "Player Weight", value: $draftConfig.playerWeight, range: 1...100)
        CustomRateSlider(title: store.isArabic ? "وزن الديناصورات (Dino Weight)" : "Dino Weight", value: $draftConfig.dinoWeight, range: 1...100)
        CustomRateSlider(title: store.isArabic ? "ضرر الديناصورات (Dino Damage)" : "Dino Damage", value: $draftConfig.dinoDamage, range: 1...20)
        
        SettingToggleCard(title: store.isArabic ? "السماح بالطيران داخل الكهوف" : "Allow Cave Flyers", isOn: $draftConfig.allowCaveFlyers)
        SettingToggleCard(title: store.isArabic ? "إظهار موقع اللاعب على الخريطة" : "Show Player on Map", isOn: $draftConfig.showMapPlayerLocation)
        SettingToggleCard(title: store.isArabic ? "تفعيل المنظور الثالث" : "Allow Third Person", isOn: $draftConfig.allowThirdPerson)
        SettingToggleCard(title: store.isArabic ? "منع تحلل المباني تلقائياً" : "Disable Structure Decay", isOn: $draftConfig.disableStructureDecay)
        SettingToggleCard(title: store.isArabic ? "حماية الغش (BattlEye)" : "Enable BattlEye", isOn: $draftConfig.allowBattlEye)
    }
    
    @ViewBuilder
    func minecraftSettingsSection() -> some View {
        SettingGroupTitle(title: store.isArabic ? "2. إعدادات عالم Minecraft" : "2. Minecraft World Settings")
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(store.isArabic ? "وضع اللعب" : "Gamemode").foregroundColor(.white)
                Spacer()
                Picker("", selection: $draftConfig.mcGameMode) {
                    Text("Survival").tag("survival")
                    Text("Creative").tag("creative")
                    Text("Adventure").tag("adventure")
                    Text("Spectator").tag("spectator")
                }
                .tint(.electricCyan)
            }
            Divider().background(Color.white.opacity(0.1))
            HStack {
                Text(store.isArabic ? "مستوى الصعوبة" : "Difficulty").foregroundColor(.white)
                Spacer()
                Picker("", selection: $draftConfig.mcDifficulty) {
                    Text("Peaceful").tag("peaceful")
                    Text("Easy").tag("easy")
                    Text("Normal").tag("normal")
                    Text("Hard").tag("hard")
                }
                .tint(.electricCyan)
            }
        }
        .padding().background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 14))
        
        SettingToggleCard(title: store.isArabic ? "السماح بالحسابات المكركة (Offline Mode)" : "Allow Cracked Accounts", isOn: Binding(
            get: { !draftConfig.mcOnlineMode },
            set: { draftConfig.mcOnlineMode = !$0 }
        ))
        SettingToggleCard(title: store.isArabic ? "تفعيل عالم النذر (Nether)" : "Allow Nether", isOn: $draftConfig.mcAllowNether)
        SettingToggleCard(title: store.isArabic ? "تفعيل بلوكات الأوامر (Command Blocks)" : "Command Blocks", isOn: $draftConfig.mcEnableCommandBlock)
    }
    
    @ViewBuilder
    func fivemSettingsSection() -> some View {
        SettingGroupTitle(title: store.isArabic ? "2. إعدادات FiveM (GTA V)" : "2. FiveM Settings")
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(store.isArabic ? "إصدار اللعبة (Game Build)" : "Game Build").foregroundColor(.white)
                Spacer()
                Picker("", selection: $draftConfig.fivemGameBuild) {
                    Text("3258 (Bottom Dollar)").tag("3258")
                    Text("3095 (Chop Shop)").tag("3095")
                    Text("2944 (Mercenaries)").tag("2944")
                }
                .tint(.electricCyan)
            }
        }
        .padding().background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 14))
        SettingToggleCard(title: store.isArabic ? "تفعيل المحادثة الصوتية (Voice Chat)" : "Voice Chat", isOn: $draftConfig.fivemVoiceChat)
    }
    
    @ViewBuilder
    func rustSettingsSection() -> some View {
        SettingGroupTitle(title: store.isArabic ? "2. إعدادات Rust" : "2. Rust Settings")
        CustomRateSlider(title: store.isArabic ? "مضاعف الموارد (Gather Rate)" : "Gather Rate", value: $draftConfig.rustGatherRate, range: 1...20)
        Stepper(value: $draftConfig.rustWorldSize, in: 1000...6000, step: 500) {
            HStack {
                Text(store.isArabic ? "حجم الخريطة" : "World Size").foregroundColor(.white)
                Spacer()
                Text("\(draftConfig.rustWorldSize)").foregroundColor(.electricCyan)
            }
        }
        .padding().background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    @ViewBuilder
    func palworldSettingsSection() -> some View {
        SettingGroupTitle(title: store.isArabic ? "2. إعدادات Palworld" : "2. Palworld Settings")
        CustomRateSlider(title: store.isArabic ? "نسبة صيد الـ Pals" : "Capture Rate", value: $draftConfig.palCaptureRate, range: 0.5...10)
    }
    
    @ViewBuilder
    func cs2SettingsSection() -> some View {
        SettingGroupTitle(title: store.isArabic ? "2. إعدادات CS2" : "2. CS2 Settings")
        Stepper(value: $draftConfig.cs2MaxRounds, in: 10...30, step: 2) {
            HStack {
                Text(store.isArabic ? "عدد الجولات" : "Max Rounds").foregroundColor(.white)
                Spacer()
                Text("\(draftConfig.cs2MaxRounds)").foregroundColor(.electricCyan)
            }
        }
        .padding().background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    @ViewBuilder
    func terrariaSettingsSection() -> some View {
        SettingGroupTitle(title: store.isArabic ? "2. إعدادات Terraria" : "2. Terraria Settings")
        Picker("Difficulty", selection: $draftConfig.terrariaDifficulty) {
            Text("Classic").tag("Classic")
            Text("Expert").tag("Expert")
            Text("Master").tag("Master")
        }
        .padding().background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    @ViewBuilder
    func valheimSettingsSection() -> some View {
        SettingGroupTitle(title: store.isArabic ? "2. إعدادات Valheim" : "2. Valheim Settings")
        CustomRateSlider(title: store.isArabic ? "مضاعف الموارد" : "Resource Rate", value: $draftConfig.harvestMultiplier, range: 1...5)
    }
    
    // ---------------------------------------------------------
    // متجر المودات الشامل (أكثر من 35 موداً لأرك + الألعاب الأخرى)
    // ---------------------------------------------------------
    func modsAndStoreView(game: GameType) -> some View {
        let categories = ["الكل", "تخزين", "موارد", "أدوات", "تربية", "أتمتة", "بناء", "ديناصورات", "تحدي", "إدارة", "أسلحة"]
        let gameMods = store.modsCatalog.filter { $0.game == game }
        let filteredCatalog = gameMods.filter { item in
            let matchesSearch = modSearchText.isEmpty || item.name.localizedCaseInsensitiveContains(modSearchText) || item.arabicDescription.contains(modSearchText)
            let matchesCat = selectedModCategory == "الكل" || item.category.contains(selectedModCategory)
            return matchesSearch && matchesCat
        }
        
        return ScrollView {
            VStack(spacing: 16) {
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
                
                if store.canMods {
                    VStack(spacing: 10) {
                        Text(store.isArabic ? "إضافة أي مود برقم المعرّف (CurseForge Mod ID)" : "Add Custom Mod by ID")
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
                            Label(store.isArabic ? "إضافة للقائمة (ثم اضغط حفظ)" : "Add to List", systemImage: "plus.circle.fill")
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
                
                if !gameMods.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(store.isArabic ? "متجر مودات \(game.shortBadge) الشامل (\(gameMods.count) مود)" : "\(game.shortBadge) Mods Store")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField(store.isArabic ? "ابحث في المتجر بالاسم أو الوصف..." : "Search mods...", text: $modSearchText)
                            .padding(10)
                            .background(Color.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        if game == .arkAscended {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(categories, id: \.self) { cat in
                                        Button {
                                            selectedModCategory = cat
                                        } label: {
                                            Text(cat)
                                                .font(.caption.bold())
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(selectedModCategory == cat ? Color.electricCyan : Color.cardBg)
                                                .foregroundColor(selectedModCategory == cat ? .black : .white)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }
                        
                        ForEach(filteredCatalog) { item in
                            let alreadyInstalled = draftConfig.mods.contains(where: { $0.modId == item.id })
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 12) {
                                    GameOfficialImage(urlString: item.imageURL, fallbackIcon: "puzzlepiece.fill")
                                        .frame(width: 58, height: 58)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.name)
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                        HStack(spacing: 6) {
                                            Text(item.category)
                                                .font(.caption2.bold())
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(Color.electricCyan.opacity(0.15))
                                                .foregroundColor(.electricCyan)
                                                .clipShape(Capsule())
                                            Text("ID: \(item.id)")
                                                .font(.caption2.monospaced())
                                                .foregroundColor(.gray)
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
                                
                                Text(store.isArabic ? item.arabicDescription : item.englishDescription)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.85))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .background(Color.cardBg)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
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
// نافذة مراجعة التعديلات قبل الحفظ وتأكيد إعادة التشغيل بعد 20 ثانية
// ---------------------------------------------------------
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
