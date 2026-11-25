import SwiftUI

struct ServerDetailView: View {
    @EnvironmentObject var store: ServerStore
    @Environment(\.dismiss) var dismiss
    let serverId: String
    
    @State private var selectedTab = 0
    @State private var newModId = ""
    @State private var newModName = ""
    @State private var modSearchText = ""
    @State private var selectedCategory = "الكل"
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
                        Text(store.isArabic ? "الإعدادات الشاملة" : "All Settings").tag(0)
                        Text(store.isArabic ? "المودات والمتجر" : "Mods Store").tag(1)
                        Text(store.isArabic ? "الكونسول" : "Console").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    if selectedTab == 0 {
                        allServerSettingsView(index: idx)
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
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: server.game.themeColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 46, height: 46)
                    Image(systemName: server.game.icon)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
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
    
    func allServerSettingsView(index: Int) -> some View {
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
                    SettingGroupTitle(title: store.isArabic ? "1. المعدلات الأساسية والموارد" : "1. Core Rates")
                    CustomRateSlider(title: store.isArabic ? "مضاعف التجميع (Harvest)" : "Harvest Amount", value: $store.servers[index].config.harvestMultiplier, range: 1...100)
                    CustomRateSlider(title: store.isArabic ? "سرعة الترويض (Taming)" : "Taming Speed", value: $store.servers[index].config.tamingSpeed, range: 1...100)
                    CustomRateSlider(title: store.isArabic ? "مضاعف الخبرة (XP)" : "XP Multiplier", value: $store.servers[index].config.xpMultiplier, range: 1...50)
                    CustomRateSlider(title: store.isArabic ? "جودة اللوت (Loot Quality)" : "Loot Quality", value: $store.servers[index].config.lootQuality, range: 1...10)
                    CustomRateSlider(title: store.isArabic ? "تكديس الموارد (Stack Size)" : "Stack Size", value: $store.servers[index].config.stackSizeMultiplier, range: 1...50)
                }
                .disabled(!store.canEdit)
                
                Group {
                    SettingGroupTitle(title: store.isArabic ? "2. التفريخ والتربية (Breeding)" : "2. Breeding")
                    CustomRateSlider(title: store.isArabic ? "سرعة فقس البيض (Egg Hatch)" : "Egg Hatch Speed", value: $store.servers[index].config.eggHatchSpeed, range: 1...100)
                    CustomRateSlider(title: store.isArabic ? "سرعة نمو الصغار (Baby Mature)" : "Baby Mature Speed", value: $store.servers[index].config.babyMatureSpeed, range: 1...100)
                    CustomRateSlider(title: store.isArabic ? "مضاعف البصمة (Imprinting)" : "Imprint Multiplier", value: $store.servers[index].config.babyImprintMultiplier, range: 1...20)
                }
                .disabled(!store.canEdit)
                
                Group {
                    SettingGroupTitle(title: store.isArabic ? "3. إحصائيات اللاعب والديناصورات" : "3. Player & Dino Stats")
                    CustomRateSlider(title: store.isArabic ? "وزن اللاعب (Player Weight)" : "Player Weight", value: $store.servers[index].config.playerWeight, range: 1...100)
                    CustomRateSlider(title: store.isArabic ? "صحة اللاعب (Player Health)" : "Player Health", value: $store.servers[index].config.playerHealth, range: 1...20)
                    CustomRateSlider(title: store.isArabic ? "طاقة اللاعب (Player Stamina)" : "Player Stamina", value: $store.servers[index].config.playerStamina, range: 1...20)
                    CustomRateSlider(title: store.isArabic ? "سرعة اللاعب (Player Speed)" : "Player Speed", value: $store.servers[index].config.playerSpeed, range: 1...10)
                    CustomRateSlider(title: store.isArabic ? "وزن الديناصورات (Dino Weight)" : "Dino Weight", value: $store.servers[index].config.dinoWeight, range: 1...100)
                    CustomRateSlider(title: store.isArabic ? "ضرر الديناصورات (Dino Damage)" : "Dino Damage", value: $store.servers[index].config.dinoDamage, range: 1...20)
                }
                .disabled(!store.canEdit)
                
                Group {
                    SettingGroupTitle(title: store.isArabic ? "4. قوانين العالم والبيئة" : "4. World Rules")
                    CustomRateSlider(title: store.isArabic ? "سرعة النهار (Day Speed)" : "Day Speed", value: $store.servers[index].config.dayTimeSpeed, range: 0.1...5)
                    CustomRateSlider(title: store.isArabic ? "سرعة الليل (Night Speed)" : "Night Speed", value: $store.servers[index].config.nightTimeSpeed, range: 0.1...10)
                    CustomRateSlider(title: store.isArabic ? "استهلاك الأكل (Food Drain)" : "Food Drain", value: $store.servers[index].config.playerFoodDrain, range: 0.1...3)
                    
                    SettingToggleCard(title: store.isArabic ? "تفعيل القتال بين اللاعبين (PvP)" : "Enable PvP", isOn: $store.servers[index].config.pvpEnabled)
                    SettingToggleCard(title: store.isArabic ? "السماح بالطيران داخل الكهوف" : "Allow Cave Flyers", isOn: $store.servers[index].config.allowCaveFlyers)
                    SettingToggleCard(title: store.isArabic ? "إظهار موقع اللاعب على الخريطة" : "Show Player on Map", isOn: $store.servers[index].config.showMapPlayerLocation)
                    SettingToggleCard(title: store.isArabic ? "تفعيل المنظور الثالث" : "Allow Third Person", isOn: $store.servers[index].config.allowThirdPerson)
                    SettingToggleCard(title: store.isArabic ? "منع تحلل المباني تلقائياً" : "Disable Structure Decay", isOn: $store.servers[index].config.disableStructureDecay)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(store.isArabic ? "كلمة مرور السيرفر (اتركها فارغة للعام)" : "Server Password")
                            .font(.caption.bold()).foregroundColor(.gray)
                        TextField("Password...", text: $store.servers[index].config.serverPassword)
                            .padding(10).background(Color.black.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        Text(store.isArabic ? "رسالة الترحيب عند الدخول (MOTD)" : "MOTD Message")
                            .font(.caption.bold()).foregroundColor(.gray)
                        TextField("MOTD...", text: $store.servers[index].config.motdMessage)
                            .padding(10).background(Color.black.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding()
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!store.canEdit)
                
                if store.canEdit {
                    Button {
                        store.applyFullConfig(serverId: serverId, config: store.servers[index].config)
                    } label: {
                        Text(store.isArabic ? "حفظ وتطبيق كافة الإعدادات" : "Save All Settings")
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
    
    // متجر مودات ARK بالصور والأيقونات والوصف المترجم
    func modsAndStoreView(index: Int, game: GameType) -> some View {
        let categories = ["الكل", "تخزين وتفريخ", "أدوات واستكشاف", "أتمتة ومصانع", "ديناصورات", "موارد ووزن", "بناء متطور", "تحدي وزعماء"]
        let filteredCatalog = store.arkModsCatalog.filter { item in
            let matchesSearch = modSearchText.isEmpty || item.name.localizedCaseInsensitiveContains(modSearchText) || item.arabicDescription.contains(modSearchText)
            let matchesCat = selectedCategory == "الكل" || item.category.contains(selectedCategory)
            return matchesSearch && matchesCat
        }
        
        return ScrollView {
            VStack(spacing: 16) {
                // المودات المثبتة حالياً
                VStack(alignment: .leading, spacing: 10) {
                    Text(store.isArabic ? "المودات المثبتة حالياً (\(store.servers[index].config.mods.count))" : "Installed Mods (\(store.servers[index].config.mods.count))")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach(store.servers[index].config.mods.indices, id: \.self) { mIdx in
                        let mod = store.servers[index].config.mods[mIdx]
                        HStack(spacing: 12) {
                            Image(systemName: mod.iconName)
                                .font(.title3)
                                .foregroundColor(.electricCyan)
                                .frame(width: 40, height: 40)
                                .background(Color.electricCyan.opacity(0.15))
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
                
                // إضافة مود يدوي برقم ID
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
                                arabicDescription: store.isArabic ? "مود مضاف يدوياً برقم المعرّف \(newModId)." : "Manually installed mod."
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
                
                // متجر مودات ARK الكامل بالصور والأيقونات والوصف العربي
                VStack(alignment: .leading, spacing: 12) {
                    Text(store.isArabic ? "متجر مودات ARK الشامل (بالصور والوصف العربي)" : "ARK Mods Store")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField(store.isArabic ? "ابحث عن مود بالاسم أو الوصف..." : "Search mods...", text: $modSearchText)
                        .padding(10)
                        .background(Color.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { cat in
                                Button {
                                    selectedCategory = cat
                                } label: {
                                    Text(cat)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedCategory == cat ? Color.electricCyan : Color.cardBg)
                                        .foregroundColor(selectedCategory == cat ? .black : .white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    
                    ForEach(filteredCatalog) { item in
                        let alreadyInstalled = store.servers[index].config.mods.contains(where: { $0.modId == item.id })
                        VStack(alignment: .leading, spacing: 10) {
                            // بطاقة صورة وأيقونة المود العلوية
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(LinearGradient(colors: item.bannerColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 56, height: 56)
                                    Image(systemName: item.iconName)
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                
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
                                            let mod = GameMod(modId: item.id, name: item.name, arabicDescription: item.arabicDescription, iconName: item.iconName)
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
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(Color.cardBg)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                    TextField(store.isArabic ? "اكتب أمر السيرفر (مثال: saveworld)" : "Enter command...", text: $commandText)
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
