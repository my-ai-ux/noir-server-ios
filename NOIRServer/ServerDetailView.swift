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
    
    // تأكيد الحذف مرتين للمالك فقط
    @State private var showFirstDeleteAlert = false
    @State private var showSecondDeleteAlert = false
    
    var serverIndex: Int? {
        store.servers.firstIndex(where: { $0.id == serverId })
    }
    
    var body: some View {
        if let idx = serverIndex {
            let server = store.servers[idx]
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()
                
                VStack(spacing: 12) {
                    serverInfoAndPowerCard(server: server)
                    
                    Picker("", selection: $selectedTab) {
                        Text(store.isArabic ? "كافة الإعدادات" : "All Settings").tag(0)
                        Text(store.isArabic ? "المودات والمتجر" : "Mods & Store").tag(1)
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
                // زر الحذف يظهر للمالك فقط
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
            // التنبيه الأول للحذف
            .alert(store.isArabic ? "هل أنت متأكد؟" : "Are you sure?", isPresented: $showFirstDeleteAlert) {
                Button(store.isArabic ? "نعم، متابعة" : "Yes, Continue", role: .destructive) {
                    showSecondDeleteAlert = true
                }
                Button(store.isArabic ? "إلغاء" : "Cancel", role: .cancel) {}
            } message: {
                Text(store.isArabic ? "أنت على وشك حذف سيرفر (\(server.name))." : "You are about to delete \(server.name).")
            }
            // التنبيه الثاني النهائي للحذف
            .alert(store.isArabic ? "تأكيد نهائي: هل أنت متأكد فعلاً؟" : "Final Confirmation: Are you really sure?", isPresented: $showSecondDeleteAlert) {
                Button(store.isArabic ? "حذف السيرفر نهائياً" : "Delete Permanently", role: .destructive) {
                    store.deleteServer(serverId: server.id)
                    dismiss()
                }
                Button(store.isArabic ? "تراجع" : "Cancel", role: .cancel) {}
            } message: {
                Text(store.isArabic ? "سيتم مسح جميع ملفات السيرفر والعالم والمودات ولن تتمكن من استرجاعها أبداً!" : "All world saves and mods will be permanently erased!")
            }
        }
    }
    
    func serverInfoAndPowerCard(server: GameServer) -> some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(server.game.rawValue)
                        .font(.caption.bold())
                        .foregroundColor(.amberGold)
                    Text("\(server.ipAddress):\(server.port)")
                        .font(.subheadline.monospaced().bold())
                        .foregroundColor(.white)
                }
                Spacer()
                Button {
                    UIPasteboard.general.string = "\(server.ipAddress):\(server.port)"
                    store.showToast(store.isArabic ? "تم نسخ IP السيرفر!" : "IP Copied!")
                } label: {
                    Label(store.isArabic ? "نسخ IP" : "Copy IP", systemImage: "doc.on.doc")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.amberGold)
                        .clipShape(Capsule())
                }
            }
            
            if store.canPower {
                HStack(spacing: 10) {
                    PowerButton(title: store.isArabic ? "تشغيل" : "Start", icon: "play.fill", color: .green) {
                        store.sendPowerAction(serverId: server.id, action: "start")
                    }
                    PowerButton(title: store.isArabic ? "إعادة تشغيل" : "Restart", icon: "arrow.clockwise", color: .amberGold) {
                        store.sendPowerAction(serverId: server.id, action: "restart")
                    }
                    PowerButton(title: store.isArabic ? "إيقاف" : "Stop", icon: "stop.fill", color: .red) {
                        store.sendPowerAction(serverId: server.id, action: "stop")
                    }
                }
            } else {
                Text(store.isArabic ? "🔒 التحكم بالتشغيل مقيد من قبل المالك" : "🔒 Power control restricted by Owner")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(red: 0.10, green: 0.10, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    // كافة إعدادات السيرفر الشاملة (المعدلات، التفريخ، اللاعبين، قوانين العالم)
    func allServerSettingsView(index: Int) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                if !store.canEdit {
                    Text(store.isArabic ? "🔒 وضع القراءة فقط: المالك قيّد تعديل الإعدادات لحسابك" : "🔒 Read-only mode: Editing restricted by Owner")
                        .font(.caption.bold())
                        .foregroundColor(.amberGold)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(Color.amberGold.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Group {
                    SectionHeader(title: store.isArabic ? "1. المعدلات الأساسية والموارد" : "1. Core Rates & Resources")
                    RateSliderCard(title: store.isArabic ? "مضاعف التجميع (Harvest)" : "Harvest Amount", value: $store.servers[index].config.harvestMultiplier, range: 1...100)
                    RateSliderCard(title: store.isArabic ? "سرعة الترويض (Taming)" : "Taming Speed", value: $store.servers[index].config.tamingSpeed, range: 1...100)
                    RateSliderCard(title: store.isArabic ? "مضاعف الخبرة (XP)" : "XP Multiplier", value: $store.servers[index].config.xpMultiplier, range: 1...50)
                    RateSliderCard(title: store.isArabic ? "جودة اللوت والصناديق (Loot Quality)" : "Loot Quality", value: $store.servers[index].config.lootQuality, range: 1...10)
                    RateSliderCard(title: store.isArabic ? "تكديس الموارد (Stack Size)" : "Stack Size Multiplier", value: $store.servers[index].config.stackSizeMultiplier, range: 1...50)
                }
                .disabled(!store.canEdit)
                
                Group {
                    SectionHeader(title: store.isArabic ? "2. التفريخ والتربية (Breeding)" : "2. Breeding & Maturation")
                    RateSliderCard(title: store.isArabic ? "سرعة فقس البيض (Egg Hatch)" : "Egg Hatch Speed", value: $store.servers[index].config.eggHatchSpeed, range: 1...100)
                    RateSliderCard(title: store.isArabic ? "سرعة نمو الصغار (Baby Mature)" : "Baby Mature Speed", value: $store.servers[index].config.babyMatureSpeed, range: 1...100)
                    RateSliderCard(title: store.isArabic ? "مضاعف البصمة (Imprinting)" : "Imprint Multiplier", value: $store.servers[index].config.babyImprintMultiplier, range: 1...20)
                }
                .disabled(!store.canEdit)
                
                Group {
                    SectionHeader(title: store.isArabic ? "3. إحصائيات اللاعب والديناصورات" : "3. Player & Dino Stats")
                    RateSliderCard(title: store.isArabic ? "وزن اللاعب (Player Weight)" : "Player Weight", value: $store.servers[index].config.playerWeight, range: 1...100)
                    RateSliderCard(title: store.isArabic ? "صحة اللاعب (Player Health)" : "Player Health", value: $store.servers[index].config.playerHealth, range: 1...20)
                    RateSliderCard(title: store.isArabic ? "طاقة اللاعب (Player Stamina)" : "Player Stamina", value: $store.servers[index].config.playerStamina, range: 1...20)
                    RateSliderCard(title: store.isArabic ? "سرعة اللاعب (Player Speed)" : "Player Speed", value: $store.servers[index].config.playerSpeed, range: 1...10)
                    RateSliderCard(title: store.isArabic ? "وزن الديناصورات (Dino Weight)" : "Dino Weight", value: $store.servers[index].config.dinoWeight, range: 1...100)
                    RateSliderCard(title: store.isArabic ? "ضرر الديناصورات (Dino Damage)" : "Dino Damage", value: $store.servers[index].config.dinoDamage, range: 1...20)
                }
                .disabled(!store.canEdit)
                
                Group {
                    SectionHeader(title: store.isArabic ? "4. قوانين العالم والبيئة والحماية" : "4. World Rules & Security")
                    RateSliderCard(title: store.isArabic ? "سرعة النهار (Day Speed)" : "Day Speed", value: $store.servers[index].config.dayTimeSpeed, range: 0.1...5)
                    RateSliderCard(title: store.isArabic ? "سرعة الليل (Night Speed)" : "Night Speed", value: $store.servers[index].config.nightTimeSpeed, range: 0.1...10)
                    RateSliderCard(title: store.isArabic ? "استهلاك الأكل (Food Drain)" : "Food Drain", value: $store.servers[index].config.playerFoodDrain, range: 0.1...3)
                    
                    ToggleRow(title: store.isArabic ? "تفعيل القتال بين اللاعبين (PvP)" : "Enable PvP", isOn: $store.servers[index].config.pvpEnabled)
                    ToggleRow(title: store.isArabic ? "السماح بالطيران داخل الكهوف" : "Allow Cave Flyers", isOn: $store.servers[index].config.allowCaveFlyers)
                    ToggleRow(title: store.isArabic ? "إظهار موقع اللاعب على الخريطة" : "Show Player on Map", isOn: $store.servers[index].config.showMapPlayerLocation)
                    ToggleRow(title: store.isArabic ? "تفعيل المنظور الثالث (Third Person)" : "Allow Third Person", isOn: $store.servers[index].config.allowThirdPerson)
                    ToggleRow(title: store.isArabic ? "منع تحلل المباني تلقائياً" : "Disable Structure Decay", isOn: $store.servers[index].config.disableStructureDecay)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(store.isArabic ? "كلمة مرور السيرفر (اتركها فارغة للعام)" : "Server Password")
                            .font(.caption.bold()).foregroundColor(.gray)
                        TextField("Password...", text: $store.servers[index].config.serverPassword)
                            .padding(10).background(Color.black.opacity(0.4)).clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Text(store.isArabic ? "رسالة الترحيب عند الدخول (MOTD)" : "Message of the Day")
                            .font(.caption.bold()).foregroundColor(.gray)
                        TextField("MOTD...", text: $store.servers[index].config.motdMessage)
                            .padding(10).background(Color.black.opacity(0.4)).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding()
                    .background(Color(red: 0.10, green: 0.10, blue: 0.13))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!store.canEdit)
                
                if store.canEdit {
                    Button {
                        store.applyFullConfig(serverId: serverId, config: store.servers[index].config)
                    } label: {
                        Text(store.isArabic ? "حفظ وتطبيق كافة الإعدادات" : "Save & Apply All Settings")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.amberGold)
                            .foregroundColor(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding()
        }
    }
    
    // صفحة المودات + متجر مودات ARK المترجم بالعربية
    func modsAndStoreView(index: Int, game: GameType) -> some View {
        let filteredCatalog = store.arkModsCatalog.filter {
            modSearchText.isEmpty || $0.name.localizedCaseInsensitiveContains(modSearchText) || $0.arabicDescription.contains(modSearchText)
        }
        
        return ScrollView {
            VStack(spacing: 16) {
                // المودات المثبتة حالياً
                VStack(alignment: .leading, spacing: 10) {
                    Text(store.isArabic ? "المودات المثبتة على السيرفر (\(store.servers[index].config.mods.count))" : "Installed Mods (\(store.servers[index].config.mods.count))")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach(store.servers[index].config.mods.indices, id: \.self) { mIdx in
                        let mod = store.servers[index].config.mods[mIdx]
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mod.name)
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                    Text("ID: \(mod.modId)")
                                        .font(.caption2.monospaced())
                                        .foregroundColor(.amberGold)
                                }
                                Spacer()
                                if store.canMods {
                                    Toggle("", isOn: $store.servers[index].config.mods[mIdx].isEnabled)
                                        .labelsHidden()
                                        .tint(.amberGold)
                                    Button {
                                        store.servers[index].config.mods.remove(at: mIdx)
                                        store.applyFullConfig(serverId: serverId, config: store.servers[index].config)
                                    } label: {
                                        Image(systemName: "trash").foregroundColor(.red)
                                    }
                                    .padding(.leading, 8)
                                }
                            }
                            if !mod.arabicDescription.isEmpty {
                                Text(mod.arabicDescription)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(red: 0.10, green: 0.10, blue: 0.13))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                // إضافة مود يدوي بالرقم
                if store.canMods {
                    VStack(spacing: 10) {
                        Text(store.isArabic ? "إضافة مود يدوي برقم ID" : "Add Custom Mod by ID")
                            .font(.subheadline.bold())
                            .foregroundColor(.amberGold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack {
                            TextField(store.isArabic ? "رقم المود (Mod ID)" : "Mod ID", text: $newModId)
                                .padding(10).background(Color.black.opacity(0.4)).clipShape(RoundedRectangle(cornerRadius: 8))
                            TextField(store.isArabic ? "اسم المود" : "Mod Name", text: $newModName)
                                .padding(10).background(Color.black.opacity(0.4)).clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        Button {
                            guard !newModId.isEmpty else { return }
                            let mod = GameMod(
                                modId: newModId.trimmingCharacters(in: .whitespaces),
                                name: newModName.isEmpty ? "Custom Mod #\(newModId)" : newModName,
                                arabicDescription: store.isArabic ? "مود مضاف يدوياً برقم المعرّف." : "Manually added mod."
                            )
                            store.servers[index].config.mods.append(mod)
                            store.applyFullConfig(serverId: serverId, config: store.servers[index].config)
                            newModId = ""
                            newModName = ""
                        } label: {
                            Label(store.isArabic ? "تثبيت المود اليدوي" : "Install Custom Mod", systemImage: "plus.circle.fill")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(Color.amberGold)
                                .foregroundColor(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding()
                    .background(Color(red: 0.10, green: 0.10, blue: 0.13))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                // متجر مودات ARK الجاهزة مع الوصف المترجم بالعربي
                if game == .arkAscended {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(store.isArabic ? "متجر مودات ARK (مترجم بالعربي)" : "ARK Mods Store")
                            .font(.headline)
                            .foregroundColor(.amberGold)
                        
                        TextField(store.isArabic ? "ابحث في المتجر بالاسم أو الوصف العربي..." : "Search ARK mods...", text: $modSearchText)
                            .padding(10)
                            .background(Color(red: 0.12, green: 0.12, blue: 0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        ForEach(filteredCatalog) { item in
                            let alreadyInstalled = store.servers[index].config.mods.contains(where: { $0.modId == item.id })
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                        Text("\(item.category) • ID: \(item.id)")
                                            .font(.caption2)
                                            .foregroundColor(.amberGold)
                                    }
                                    Spacer()
                                    if store.canMods {
                                        Button {
                                            if !alreadyInstalled {
                                                let mod = GameMod(modId: item.id, name: item.name, arabicDescription: item.arabicDescription)
                                                store.servers[index].config.mods.append(mod)
                                                store.applyFullConfig(serverId: serverId, config: store.servers[index].config)
                                            }
                                        } label: {
                                            Text(alreadyInstalled ? (store.isArabic ? "مثبّت ✓" : "Installed ✓") : (store.isArabic ? "تثبيت +" : "Install +"))
                                                .font(.caption.bold())
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(alreadyInstalled ? Color.green.opacity(0.2) : Color.amberGold)
                                                .foregroundColor(alreadyInstalled ? .green : .black)
                                                .clipShape(Capsule())
                                        }
                                        .disabled(alreadyInstalled)
                                    }
                                }
                                
                                Text(store.isArabic ? item.arabicDescription : item.englishDescription)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .background(Color(red: 0.10, green: 0.10, blue: 0.13))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
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
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            
            if store.canConsole {
                HStack {
                    TextField(store.isArabic ? "اكتب أمر السيرفر (مثال: saveworld)" : "Enter command...", text: $commandText)
                        .autocapitalization(.none)
                        .padding(10)
                        .background(Color(red: 0.12, green: 0.12, blue: 0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    Button {
                        store.sendCommand(serverId: server.id, command: commandText)
                        commandText = ""
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .padding(12)
                            .background(Color.amberGold)
                            .foregroundColor(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            } else {
                Text(store.isArabic ? "🔒 إرسال الأوامر مقيد من قبل المالك" : "🔒 Console commands restricted by Owner")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.subheadline.bold())
            .foregroundColor(.amberGold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }
}

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .tint(.amberGold)
        .padding()
        .background(Color(red: 0.10, green: 0.10, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct RateSliderCard: View {
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
                    .foregroundColor(.amberGold)
            }
            Slider(value: $value, in: range, step: 0.5)
                .tint(.amberGold)
        }
        .padding()
        .background(Color(red: 0.10, green: 0.10, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PowerButton: View {
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
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
