import SwiftUI

struct ServerDetailView: View {
    @EnvironmentObject var store: ServerStore
    @Environment(\.dismiss) var dismiss
    let serverId: String
    
    @State private var selectedTab = 0
    @State private var newModId = ""
    @State private var newModName = ""
    @State private var modSearchText = ""
    @State private var commandText = ""
    
    @State private var showFirstDeleteAlert = false
    @State private var showSecondDeleteAlert = false
    
    var serverIndex: Int? {
        store.servers.firstIndex(where: { $0.id == serverId })
    }
    
    var body: some View {
        if let idx = serverIndex {
            let server = store.servers[idx]
            ZStack {
                Color.appBg.ignoresSafeArea()
                
                VStack(spacing: 12) {
                    serverHeaderCard(server: server)
                    
                    Picker("", selection: $selectedTab) {
                        Text(store.isArabic ? "إعدادات \(server.game.shortBadge)" : "\(server.game.shortBadge) Settings").tag(0)
                        Text(store.isArabic ? "المودات والمتجر" : "Mods Store").tag(1)
                        Text(store.isArabic ? "الكونسول" : "Console").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    if selectedTab == 0 {
                        gameSpecificSettingsView(index: idx, game: server.game)
                    } else if selectedTab == 1 {
                        modsAndStoreView(index: idx, game: server.game)
                    } else {
                        consoleView(server: server)
                    }
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
                    store.deleteServer(serverId: server.id)
                    dismiss()
                }
                Button(store.isArabic ? "تراجع" : "Cancel", role: .cancel) {}
            } message: {
                Text(store.isArabic ? "سيتم مسح السيرفر والعالم والمودات نهائياً ولن يمكنك التراجع!" : "This action cannot be undone!")
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
    
    // ---------------------------------------------------------
    // إعدادات مخصصة وحقيقية لكل لعبة على حدة
    // ---------------------------------------------------------
    func gameSpecificSettingsView(index: Int, game: GameType) -> some View {
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
                
                // 1. الإعدادات الأساسية والمنصات (مشتركة لكل الألعاب)
                Group {
                    SettingGroupTitle(title: store.isArabic ? "1. الوصول والمنصات واللاعبين" : "1. Access, Platforms & Players")
                    
                    VStack(spacing: 12) {
                        Stepper(value: $store.servers[index].config.maxPlayers, in: 2...500, step: 2) {
                            HStack {
                                Text(store.isArabic ? "الحد الأقصى للاعبين" : "Max Players")
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(store.servers[index].config.maxPlayers)")
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
                        isOn: $store.servers[index].config.crossplayEnabled
                    )
                    
                    SettingToggleCard(
                        title: store.isArabic ? "تفعيل القتال بين اللاعبين (PvP)" : "Enable PvP",
                        isOn: $store.servers[index].config.pvpEnabled
                    )
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(store.isArabic ? "كلمة مرور السيرفر (اتركها فارغة ليكون عام)" : "Server Password")
                            .font(.caption.bold()).foregroundColor(.gray)
                        TextField("Password...", text: $store.servers[index].config.serverPassword)
                            .padding(10).background(Color.black.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        Text(store.isArabic ? "رسالة الترحيب (MOTD)" : "MOTD")
                            .font(.caption.bold()).foregroundColor(.gray)
                        TextField("MOTD...", text: $store.servers[index].config.motdMessage)
                            .padding(10).background(Color.black.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding()
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!store.canEdit)
                
                // 2. الإعدادات الخاصة بكل لعبة
                Group {
                    switch game {
                    case .arkAscended:
                        arkSettingsSection(index: index)
                    case .minecraft:
                        minecraftSettingsSection(index: index)
                    case .fivem:
                        fivemSettingsSection(index: index)
                    case .rust:
                        rustSettingsSection(index: index)
                    case .palworld:
                        palworldSettingsSection(index: index)
                    case .cs2:
                        cs2SettingsSection(index: index)
                    case .terraria:
                        terrariaSettingsSection(index: index)
                    case .valheim:
                        valheimSettingsSection(index: index)
                    }
                }
                .disabled(!store.canEdit)
                
                if store.canEdit {
                    Button {
                        store.applyFullConfig(serverId: serverId, config: store.servers[index].config)
                    } label: {
                        Text(store.isArabic ? "حفظ وتطبيق إعدادات \(game.shortBadge)" : "Save \(game.shortBadge) Settings")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [.electricCyan, .neonViolet], startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding()
        }
    }
    
    // --- قسم إعدادات ARK: Survival Ascended ---
    @ViewBuilder
    func arkSettingsSection(index: Int) -> some View {
        SettingGroupTitle(title: store.isArabic ? "2. خريطة ومعدلات ARK Ascended" : "2. ARK Map & Rates")
        
        VStack(alignment: .leading, spacing: 8) {
            Text(store.isArabic ? "الخريطة النشطة (Map)" : "Active Map")
                .font(.caption.bold()).foregroundColor(.gray)
            Picker("Map", selection: $store.servers[index].config.mapName) {
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
        
        CustomRateSlider(title: store.isArabic ? "مضاعف التجميع (Harvest)" : "Harvest", value: $store.servers[index].config.harvestMultiplier, range: 1...100)
        CustomRateSlider(title: store.isArabic ? "سرعة الترويض (Taming)" : "Taming", value: $store.servers[index].config.tamingSpeed, range: 1...100)
        CustomRateSlider(title: store.isArabic ? "مضاعف الخبرة (XP)" : "XP", value: $store.servers[index].config.xpMultiplier, range: 1...50)
        CustomRateSlider(title: store.isArabic ? "جودة اللوت (Loot Quality)" : "Loot Quality", value: $store.servers[index].config.lootQuality, range: 1...10)
        CustomRateSlider(title: store.isArabic ? "تكديس الموارد (Stack Size)" : "Stack Size", value: $store.servers[index].config.stackSizeMultiplier, range: 1...50)
        
        SettingGroupTitle(title: store.isArabic ? "3. التفريخ والتربية (Breeding)" : "3. Breeding")
        CustomRateSlider(title: store.isArabic ? "سرعة فقس البيض (Egg Hatch)" : "Egg Hatch", value: $store.servers[index].config.eggHatchSpeed, range: 1...100)
        CustomRateSlider(title: store.isArabic ? "سرعة نمو الصغار (Baby Mature)" : "Baby Mature", value: $store.servers[index].config.babyMatureSpeed, range: 1...100)
        CustomRateSlider(title: store.isArabic ? "مضاعف البصمة (Imprinting)" : "Imprinting", value: $store.servers[index].config.babyImprintMultiplier, range: 1...20)
        
        SettingGroupTitle(title: store.isArabic ? "4. إحصائيات اللاعب والديناصورات والقوانين" : "4. Stats & World Rules")
        CustomRateSlider(title: store.isArabic ? "وزن اللاعب (Player Weight)" : "Player Weight", value: $store.servers[index].config.playerWeight, range: 1...100)
        CustomRateSlider(title: store.isArabic ? "وزن الديناصورات (Dino Weight)" : "Dino Weight", value: $store.servers[index].config.dinoWeight, range: 1...100)
        CustomRateSlider(title: store.isArabic ? "ضرر الديناصورات (Dino Damage)" : "Dino Damage", value: $store.servers[index].config.dinoDamage, range: 1...20)
        
        SettingToggleCard(title: store.isArabic ? "السماح بالطيران داخل الكهوف" : "Allow Cave Flyers", isOn: $store.servers[index].config.allowCaveFlyers)
        SettingToggleCard(title: store.isArabic ? "إظهار موقع اللاعب على الخريطة" : "Show Player on Map", isOn: $store.servers[index].config.showMapPlayerLocation)
        SettingToggleCard(title: store.isArabic ? "تفعيل المنظور الثالث" : "Allow Third Person", isOn: $store.servers[index].config.allowThirdPerson)
        SettingToggleCard(title: store.isArabic ? "منع تحلل المباني تلقائياً" : "Disable Structure Decay", isOn: $store.servers[index].config.disableStructureDecay)
        SettingToggleCard(title: store.isArabic ? "حماية الغش (BattlEye)" : "Enable BattlEye", isOn: $store.servers[index].config.allowBattlEye)
    }
    
    // --- قسم إعدادات Minecraft ---
    @ViewBuilder
    func minecraftSettingsSection(index: Int) -> some View {
        SettingGroupTitle(title: store.isArabic ? "2. إعدادات عالم Minecraft" : "2. Minecraft World Settings")
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(store.isArabic ? "وضع اللعب (Gamemode)" : "Gamemode").foregroundColor(.white)
                Spacer()
                Picker("", selection: $store.servers[index].config.mcGameMode) {
                    Text("Survival").tag("survival")
                    Text("Creative").tag("creative")
                    Text("Adventure").tag("adventure")
                    Text("Spectator").tag("spectator")
                }
                .tint(.electricCyan)
            }
            Divider().background(Color.white.opacity(0.1))
            HStack {
                Text(store.isArabic ? "مستوى الصعوبة (Difficulty)" : "Difficulty").foregroundColor(.white)
                Spacer()
                Picker("", selection: $store.servers[index].config.mcDifficulty) {
                    Text("Peaceful").tag("peaceful")
                    Text("Easy").tag("easy")
                    Text("Normal").tag("normal")
                    Text("Hard").tag("hard")
                }
                .tint(.electricCyan)
            }
        }
        .padding()
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        
        VStack(spacing: 12) {
            Stepper(value: $store.servers[index].config.mcViewDistance, in: 4...32) {
                HStack {
                    Text(store.isArabic ? "مسافة الرؤية (View Distance)" : "View Distance").foregroundColor(.white)
                    Spacer()
                    Text("\(store.servers[index].config.mcViewDistance) Chunks").foregroundColor(.electricCyan)
                }
            }
            Divider().background(Color.white.opacity(0.1))
            Stepper(value: $store.servers[index].config.mcSpawnProtection, in: 0...64, step: 4) {
                HStack {
                    Text(store.isArabic ? "حماية منطقة البداية (Spawn)" : "Spawn Protection").foregroundColor(.white)
                    Spacer()
                    Text("\(store.servers[index].config.mcSpawnProtection)").foregroundColor(.electricCyan)
                }
            }
        }
        .padding()
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        
        SettingToggleCard(title: store.isArabic ? "السماح بالحسابات المكركة (Offline Mode)" : "Allow Cracked Accounts (Offline Mode)", isOn: Binding(
            get: { !store.servers[index].config.mcOnlineMode },
            set: { store.servers[index].config.mcOnlineMode = !$0 }
        ))
        SettingToggleCard(title: store.isArabic ? "تفعيل عالم النذر (Allow Nether)" : "Allow Nether", isOn: $store.servers[index].config.mcAllowNether)
        SettingToggleCard(title: store.isArabic ? "تفعيل عالم الإند (Allow End)" : "Allow End", isOn: $store.servers[index].config.mcAllowEnd)
        SettingToggleCard(title: store.isArabic ? "تفعيل بلوكات الأوامر (Command Blocks)" : "Enable Command Blocks", isOn: $store.servers[index].config.mcEnableCommandBlock)
        SettingToggleCard(title: store.isArabic ? "السماح بالطيران (Allow Flight)" : "Allow Flight", isOn: $store.servers[index].config.mcAllowFlight)
    }
    
    // --- قسم إعدادات FiveM (GTA V) ---
    @ViewBuilder
    func fivemSettingsSection(index: Int) -> some View {
        SettingGroupTitle(title: store.isArabic ? "2. إعدادات سيرفر FiveM (GTA V)" : "2. FiveM Server Settings")
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(store.isArabic ? "نظام OneSync" : "OneSync Mode").foregroundColor(.white)
                Spacer()
                Picker("", selection: $store.servers[index].config.fivemOneSync) {
                    Text("Infinity (On)").tag("on")
                    Text("Legacy").tag("legacy")
                    Text("Off").tag("off")
                }
                .tint(.electricCyan)
            }
            Divider().background(Color.white.opacity(0.1))
            HStack {
                Text(store.isArabic ? "إصدار اللعبة (Game Build)" : "Game Build").foregroundColor(.white)
                Spacer()
                Picker("", selection: $store.servers[index].config.fivemGameBuild) {
                    Text("3258 (Bottom Dollar)").tag("3258")
                    Text("3095 (Chop Shop)").tag("3095")
                    Text("2944 (Mercenaries)").tag("2944")
                    Text("2802 (Drug Wars)").tag("2802")
                }
                .tint(.electricCyan)
            }
        }
        .padding()
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        
        SettingToggleCard(title: store.isArabic ? "تفعيل المحادثة الصوتية (Voice Chat)" : "Enable Voice Chat", isOn: $store.servers[index].config.fivemVoiceChat)
        SettingToggleCard(title: store.isArabic ? "السماح بـ ScriptHook (مودات اللاعب)" : "Allow Client ScriptHook", isOn: $store.servers[index].config.fivemScriptHook)
        
        VStack(alignment: .leading, spacing: 10) {
            Text("Cfx.re License Key").font(.caption.bold()).foregroundColor(.gray)
            TextField("cfxk_...", text: $store.servers[index].config.fivemLicenseKey)
                .padding(10).background(Color.black.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 10))
            
            Text("Steam Web API Key").font(.caption.bold()).foregroundColor(.gray)
            TextField("API Key...", text: $store.servers[index].config.fivemSteamWebApiKey)
                .padding(10).background(Color.black.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    // --- قسم إعدادات Rust ---
    @ViewBuilder
    func rustSettingsSection(index: Int) -> some View {
        SettingGroupTitle(title: store.isArabic ? "2. إعدادات عالم وموارد Rust" : "2. Rust Server Settings")
        CustomRateSlider(title: store.isArabic ? "مضاعف الموارد (Gather Rate)" : "Gather Rate", value: $store.servers[index].config.rustGatherRate, range: 1...20)
        CustomRateSlider(title: store.isArabic ? "نسبة تحلل المباني (Decay Scale)" : "Decay Scale", value: $store.servers[index].config.rustDecayScale, range: 0...2)
        
        VStack(spacing: 12) {
            Stepper(value: $store.servers[index].config.rustWorldSize, in: 1000...6000, step: 500) {
                HStack {
                    Text(store.isArabic ? "حجم الخريطة (World Size)" : "World Size").foregroundColor(.white)
                    Spacer()
                    Text("\(store.servers[index].config.rustWorldSize)").foregroundColor(.electricCyan)
                }
            }
            Divider().background(Color.white.opacity(0.1))
            Stepper(value: $store.servers[index].config.rustMaxTeamSize, in: 1...16) {
                HStack {
                    Text(store.isArabic ? "أقصى حجم للفريق (Team Size)" : "Max Team Size").foregroundColor(.white)
                    Spacer()
                    Text("\(store.servers[index].config.rustMaxTeamSize)").foregroundColor(.electricCyan)
                }
            }
        }
        .padding()
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    // --- أقسام Palworld / CS2 / Terraria / Valheim ---
    @ViewBuilder
    func palworldSettingsSection(index: Int) -> some View {
        SettingGroupTitle(title: store.isArabic ? "2. إعدادات Palworld" : "2. Palworld Settings")
        CustomRateSlider(title: store.isArabic ? "نسبة صيد الـ Pals (Capture Rate)" : "Pal Capture Rate", value: $store.servers[index].config.palCaptureRate, range: 0.5...10)
        CustomRateSlider(title: store.isArabic ? "معدل ظهور الـ Pals (Spawn Rate)" : "Pal Spawn Rate", value: $store.servers[index].config.palSpawnRate, range: 0.5...5)
        CustomRateSlider(title: store.isArabic ? "مضاعف الخبرة (XP)" : "XP Rate", value: $store.servers[index].config.xpMultiplier, range: 1...20)
    }
    
    @ViewBuilder
    func cs2SettingsSection(index: Int) -> some View {
        SettingGroupTitle(title: store.isArabic ? "2. إعدادات Counter-Strike 2" : "2. CS2 Settings")
        VStack(spacing: 12) {
            HStack {
                Text(store.isArabic ? "نمط اللعب" : "Game Mode").foregroundColor(.white)
                Spacer()
                Picker("", selection: $store.servers[index].config.cs2GameMode) {
                    Text("Competitive").tag("Competitive")
                    Text("Premier").tag("Premier")
                    Text("Deathmatch").tag("Deathmatch")
                    Text("Casual").tag("Casual")
                }
                .tint(.electricCyan)
            }
            Divider().background(Color.white.opacity(0.1))
            Stepper(value: $store.servers[index].config.cs2MaxRounds, in: 10...30, step: 2) {
                HStack {
                    Text(store.isArabic ? "عدد الجولات (Max Rounds)" : "Max Rounds").foregroundColor(.white)
                    Spacer()
                    Text("\(store.servers[index].config.cs2MaxRounds)").foregroundColor(.electricCyan)
                }
            }
        }
        .padding()
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    @ViewBuilder
    func terrariaSettingsSection(index: Int) -> some View {
        SettingGroupTitle(title: store.isArabic ? "2. إعدادات عالم Terraria" : "2. Terraria World")
        VStack(spacing: 12) {
            HStack {
                Text(store.isArabic ? "حجم العالم" : "World Size").foregroundColor(.white)
                Spacer()
                Picker("", selection: $store.servers[index].config.terrariaWorldSize) {
                    Text("Small").tag("Small")
                    Text("Medium").tag("Medium")
                    Text("Large").tag("Large")
                }
                .tint(.electricCyan)
            }
            Divider().background(Color.white.opacity(0.1))
            HStack {
                Text(store.isArabic ? "الصعوبة" : "Difficulty").foregroundColor(.white)
                Spacer()
                Picker("", selection: $store.servers[index].config.terrariaDifficulty) {
                    Text("Classic").tag("Classic")
                    Text("Expert").tag("Expert")
                    Text("Master").tag("Master")
                    Text("Journey").tag("Journey")
                }
                .tint(.electricCyan)
            }
        }
        .padding()
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    @ViewBuilder
    func valheimSettingsSection(index: Int) -> some View {
        SettingGroupTitle(title: store.isArabic ? "2. إعدادات عالم Valheim" : "2. Valheim Settings")
        CustomRateSlider(title: store.isArabic ? "مضاعف الموارد (Resource Rate)" : "Resource Rate", value: $store.servers[index].config.harvestMultiplier, range: 1...5)
        SettingToggleCard(title: store.isArabic ? "السماح بنقل المعادن عبر البوابات" : "Allow Portal Metals", isOn: $store.servers[index].config.allowCaveFlyers)
    }
    
    // ---------------------------------------------------------
    // متجر المودات والبلوقنات بالصور الرسمية لكل لعبة
    // ---------------------------------------------------------
    func modsAndStoreView(index: Int, game: GameType) -> some View {
        let gameMods = store.modsCatalog.filter { $0.game == game }
        let filteredCatalog = gameMods.filter { item in
            modSearchText.isEmpty || item.name.localizedCaseInsensitiveContains(modSearchText) || item.arabicDescription.contains(modSearchText)
        }
        
        return ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(store.isArabic ? "المودات المثبتة حالياً (\(store.servers[index].config.mods.count))" : "Installed Mods (\(store.servers[index].config.mods.count))")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach(store.servers[index].config.mods.indices, id: \.self) { mIdx in
                        let mod = store.servers[index].config.mods[mIdx]
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
                                Toggle("", isOn: $store.servers[index].config.mods[mIdx].isEnabled)
                                    .labelsHidden()
                                    .tint(.electricCyan)
                                Button {
                                    let removedName = mod.name
                                    store.servers[index].config.mods.remove(at: mIdx)
                                    store.applyFullConfig(serverId: serverId, config: store.servers[index].config, customLogText: "حذف مود: \(removedName)")
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
                        Text(store.isArabic ? "إضافة أي مود برقم المعرّف (Mod ID)" : "Add Custom Mod by ID")
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
                            store.servers[index].config.mods.append(mod)
                            store.applyFullConfig(serverId: serverId, config: store.servers[index].config, customLogText: "إضافة مود يدوي: \(mName)")
                            newModId = ""
                            newModName = ""
                        } label: {
                            Label(store.isArabic ? "تثبيت وحفظ المود" : "Install Mod", systemImage: "plus.circle.fill")
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
                
                if !filteredCatalog.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(store.isArabic ? "متجر مودات \(game.shortBadge) (بالصور الأصلية والوصف العربي)" : "\(game.shortBadge) Mods Store")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField(store.isArabic ? "ابحث في المتجر..." : "Search mods...", text: $modSearchText)
                            .padding(10)
                            .background(Color.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        ForEach(filteredCatalog) { item in
                            let alreadyInstalled = store.servers[index].config.mods.contains(where: { $0.modId == item.id })
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
                                                store.servers[index].config.mods.append(mod)
                                                store.applyFullConfig(serverId: serverId, config: store.servers[index].config, customLogText: "تثبيت مود: \(item.name)")
                                            }
                                        } label: {
                                            Text(alreadyInstalled ? (store.isArabic ? "مثبّت ✓" : "Installed") : (store.isArabic ? "تثبيت +" : "Install"))
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
