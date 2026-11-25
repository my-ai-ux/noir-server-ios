import SwiftUI

struct ServerDetailView: View {
    @EnvironmentObject var store: ServerStore
    @Environment(\.dismiss) var dismiss
    let serverId: String
    
    @State private var selectedTab = 0
    @State private var newModId = ""
    @State private var newModName = ""
    @State private var commandText = ""
    
    var serverIndex: Int? {
        store.servers.firstIndex(where: { $0.id == serverId })
    }
    
    var body: some View {
        if let idx = serverIndex {
            let server = store.servers[idx]
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()
                
                VStack(spacing: 14) {
                    // معلومات السيرفر المباشرة وأزرار التحكم
                    serverInfoAndPowerCard(server: server)
                    
                    Picker("", selection: $selectedTab) {
                        Text(store.isArabic ? "إعدادات Nitrado" : "Nitrado Config").tag(0)
                        Text(store.isArabic ? "المودات (\(server.config.mods.count))" : "Mods (\(server.config.mods.count))").tag(1)
                        Text(store.isArabic ? "الكونسول" : "Console").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    if selectedTab == 0 {
                        nitradoDynamicConfigView(index: idx, game: server.game)
                    } else if selectedTab == 1 {
                        modsManagerView(index: idx, game: server.game)
                    } else {
                        consoleView(server: server)
                    }
                }
            }
            .navigationTitle(server.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        store.deleteServer(serverId: server.id)
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    func serverInfoAndPowerCard(server: GameServer) -> some View {
        VStack(spacing: 12) {
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
            
            HStack(spacing: 12) {
                StatPill(title: "CPU", value: "\(Int(server.cpuUsage))%")
                StatPill(title: "RAM", value: "\(String(format: "%.1f", server.ramUsedGB))/\(Int(server.ramTotalGB))GB")
                StatPill(title: store.isArabic ? "اللاعبين" : "PLAYERS", value: "\(server.playersOnline)/\(server.config.maxPlayers)")
            }
            
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
        }
        .padding()
        .background(Color(red: 0.10, green: 0.10, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    // إعدادات Nitrado تتكيف حسب نوع اللعبة
    func nitradoDynamicConfigView(index: Int, game: GameType) -> some View {
        let labels = getGameRateLabels(game: game, isArabic: store.isArabic)
        return ScrollView {
            VStack(spacing: 14) {
                RateSliderCard(title: labels.0, value: $store.servers[index].config.primaryRate, range: 1...50)
                RateSliderCard(title: labels.1, value: $store.servers[index].config.secondaryRate, range: 1...50)
                RateSliderCard(title: labels.2, value: $store.servers[index].config.xpMultiplier, range: 1...30)
                RateSliderCard(title: labels.3, value: $store.servers[index].config.thirdRate, range: 1...100)
                RateSliderCard(title: labels.4, value: $store.servers[index].config.weightOrSlots, range: 1...50)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(store.isArabic ? "كلمة مرور السيرفر (اختياري)" : "Server Password (Optional)")
                        .font(.caption.bold())
                        .foregroundColor(.gray)
                    TextField(store.isArabic ? "اتركه فارغاً ليكون عام" : "Leave empty for public", text: $store.servers[index].config.serverPassword)
                        .padding(10)
                        .background(Color.black.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding()
                .background(Color(red: 0.10, green: 0.10, blue: 0.13))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Toggle(isOn: $store.servers[index].config.pvpEnabled) {
                    Text(store.isArabic ? "تفعيل القتال بين اللاعبين (PvP)" : "Enable PvP")
                        .foregroundColor(.white)
                }
                .tint(.amberGold)
                .padding()
                .background(Color(red: 0.10, green: 0.10, blue: 0.13))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Button {
                    store.applyNitradoConfig(serverId: serverId, config: store.servers[index].config)
                } label: {
                    Text(store.isArabic ? "حفظ الإعدادات وتطبيقها" : "Save & Apply Settings")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.amberGold)
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding()
        }
    }
    
    func getGameRateLabels(game: GameType, isArabic: Bool) -> (String, String, String, String, String) {
        switch game {
        case .arkAscended:
            return isArabic
                ? ("مضاعف التجميع (Harvest)", "سرعة الترويض (Taming)", "مضاعف الخبرة (XP)", "سرعة نمو الصغار (Maturation)", "وزن اللاعب (Player Weight)")
                : ("Harvest Multiplier", "Taming Speed", "XP Multiplier", "Baby Mature Speed", "Player Weight")
        case .minecraft:
            return isArabic
                ? ("مستوى الصعوبة (Difficulty)", "مسافة الرؤية (View Distance)", "مضاعف الخبرة (XP)", "سرعة نمو المحاصيل (Tick Speed)", "سعة المخزن (Slots)")
                : ("Difficulty Level", "View Distance", "XP Multiplier", "Random Tick Speed", "Storage Multiplier")
        case .rust:
            return isArabic
                ? ("مضاعف الموارد (Gather Rate)", "معدل الصهر (Smelting)", "سرعة الكرافت (Crafting)", "حجم التكديس (Stack Size)", "معدل اللوت (Loot Rate)")
                : ("Gather Rate", "Smelting Speed", "Crafting Speed", "Stack Multiplier", "Loot Multiplier")
        default:
            return isArabic
                ? ("معدل جمع الموارد", "سرعة التطوير والصيد", "مضاعف الخبرة (XP)", "سرعة البناء والإنتاج", "سعة الحمولة")
                : ("Resource Rate", "Capture/Craft Speed", "XP Multiplier", "Build Speed", "Carry Capacity")
        }
    }
    
    func modsManagerView(index: Int, game: GameType) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(spacing: 10) {
                    Text(store.isArabic ? "إضافة مود / بلوقن (\(game.modSourceLabel))" : "Add Mod (\(game.modSourceLabel))")
                        .font(.subheadline.bold())
                        .foregroundColor(.amberGold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    TextField(store.isArabic ? "معرّف المود (مثال: 928793)" : "Mod ID / Name", text: $newModId)
                        .padding(10)
                        .background(Color.black.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    TextField(store.isArabic ? "اسم المود (اختياري)" : "Mod Title (Optional)", text: $newModName)
                        .padding(10)
                        .background(Color.black.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Button {
                        guard !newModId.isEmpty else { return }
                        let mod = GameMod(
                            modId: newModId.trimmingCharacters(in: .whitespaces),
                            name: newModName.isEmpty ? "Mod #\(newModId)" : newModName
                        )
                        store.servers[index].config.mods.append(mod)
                        store.applyNitradoConfig(serverId: serverId, config: store.servers[index].config)
                        newModId = ""
                        newModName = ""
                    } label: {
                        Label(store.isArabic ? "تثبيت المود على السيرفر" : "Install Mod", systemImage: "plus.app.fill")
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
                
                ForEach(store.servers[index].config.mods.indices, id: \.self) { mIdx in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(store.servers[index].config.mods[mIdx].name)
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                            Text("ID: \(store.servers[index].config.mods[mIdx].modId)")
                                .font(.caption.monospaced())
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Toggle("", isOn: $store.servers[index].config.mods[mIdx].isEnabled)
                            .labelsHidden()
                            .tint(.amberGold)
                        
                        Button {
                            store.servers[index].config.mods.remove(at: mIdx)
                            store.applyNitradoConfig(serverId: serverId, config: store.servers[index].config)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .padding(.leading, 8)
                    }
                    .padding()
                    .background(Color(red: 0.10, green: 0.10, blue: 0.13))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
        }
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
