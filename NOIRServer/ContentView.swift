import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ServerStore
    @State private var selectedTab = 0
    @State private var showNewServerSheet = false
    @State private var preselectedGame: GameType = .arkAscended
    
    var body: some View {
        if !store.isAuthenticated {
            LoginView()
        } else {
            ZStack(alignment: .bottom) {
                TabView(selection: $selectedTab) {
                    // التبويب 1: الرئيسية + التعديلات الأخيرة
                    HomeDashboardTab(selectedTab: $selectedTab, showNewServerSheet: $showNewServerSheet, preselectedGame: $preselectedGame)
                        .tabItem {
                            Label(store.isArabic ? "الرئيسية" : "Home", systemImage: "house.fill")
                        }
                        .tag(0)
                    
                    // التبويب 2: سيرفراتي + شريط السحب الأفقي لإنشاء سيرفر
                    ServersListTab(showNewServerSheet: $showNewServerSheet, preselectedGame: $preselectedGame)
                        .tabItem {
                            Label(store.isArabic ? "سيرفراتي" : "Servers", systemImage: "server.rack")
                        }
                        .tag(1)
                    
                    // التبويب 3: الإعدادات والصلاحيات
                    SettingsTab()
                        .tabItem {
                            Label(store.isArabic ? "الإعدادات" : "Settings", systemImage: "gearshape.2.fill")
                        }
                        .tag(2)
                }
                .tint(.electricCyan)
                
                if let toast = store.toastMessage {
                    Text(toast)
                        .font(.subheadline.bold())
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(LinearGradient(colors: [.electricCyan, .neonViolet], startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(radius: 10)
                        .padding(.bottom, 65)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .sheet(isPresented: $showNewServerSheet) {
                NewServerSheet(selectedGame: preselectedGame)
            }
            .environment(\.layoutDirection, store.isArabic ? .rightToLeft : .leftToRight)
        }
    }
}

// ---------------------------------------------------------
// التبويب الأول: الرئيسية + سجل التعديلات الأخيرة
// ---------------------------------------------------------
struct HomeDashboardTab: View {
    @EnvironmentObject var store: ServerStore
    @Binding var selectedTab: Int
    @Binding var showNewServerSheet: Bool
    @Binding var preselectedGame: GameType
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // بطاقة الترحيب والموارد السحابية بتدرج عصري
                        cloudHeroCard
                        
                        // اختصارات سريعة
                        HStack(spacing: 12) {
                            QuickActionTile(
                                title: store.isArabic ? "سيرفراتي (\(store.servers.count))" : "My Servers (\(store.servers.count))",
                                subtitle: store.isArabic ? "عرض وإدارة الكل" : "Manage all",
                                icon: "server.rack",
                                colors: [.electricCyan, .blue]
                            ) {
                                selectedTab = 1
                            }
                            
                            if store.isOwner {
                                QuickActionTile(
                                    title: store.isArabic ? "سيرفر جديد" : "New Server",
                                    subtitle: store.isArabic ? "إنشاء لعبة فوراً" : "Deploy game",
                                    icon: "plus.circle.fill",
                                    colors: [.neonViolet, .pink]
                                ) {
                                    preselectedGame = .arkAscended
                                    showNewServerSheet = true
                                }
                            }
                        }
                        
                        // قسم التعديلات الأخيرة (Recent Activity Log)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label(store.isArabic ? "التعديلات الأخيرة" : "Recent Changes", systemImage: "clock.arrow.circlepath")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(store.activityLogs.count)")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.electricCyan.opacity(0.2))
                                    .foregroundColor(.electricCyan)
                                    .clipShape(Capsule())
                            }
                            
                            if store.activityLogs.isEmpty {
                                Text(store.isArabic ? "لا توجد تعديلات مسجلة بعد" : "No recent changes yet")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ForEach(store.activityLogs.prefix(10)) { log in
                                    HStack(spacing: 12) {
                                        Image(systemName: iconForCategory(log.category))
                                            .font(.subheadline)
                                            .foregroundColor(colorForCategory(log.category))
                                            .frame(width: 36, height: 36)
                                            .background(colorForCategory(log.category).opacity(0.15))
                                            .clipShape(Circle())
                                        
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(log.actionDescription)
                                                .font(.caption.bold())
                                                .foregroundColor(.white)
                                            HStack {
                                                Text("\(log.serverName) • \(log.userName)")
                                                    .font(.caption2)
                                                    .foregroundColor(.electricCyan)
                                                Spacer()
                                                Text(log.timestamp, style: .time)
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.cardBg)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("NOIR CLOUD")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.logout()
                    } label: {
                        Label(store.isArabic ? "قفل" : "Lock", systemImage: "lock.fill")
                            .font(.caption.bold())
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    var cloudHeroCard: some View {
        let usedRAM = store.servers.reduce(0) { $0 + $1.ramUsedGB }
        let onlineCount = store.servers.filter { $0.status == .running }.count
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.isArabic ? "أهلاً بك، \(store.currentUserName)" : "Welcome, \(store.currentUserName)")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(store.isDemoMode ? (store.isArabic ? "Oracle Cloud • وضع المعاينة المحفوظ" : "Oracle Cloud • Saved Local Mode") : (store.isArabic ? "متصل بالسيرفر السحابي المباشر" : "Connected to Live Cloud"))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                Text(store.isOwner ? "OWNER" : "MEMBER")
                    .font(.caption2.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.3))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            
            HStack(spacing: 10) {
                HeroStatBox(label: "RAM", value: "\(String(format: "%.1f", usedRAM))/24 GB")
                HeroStatBox(label: store.isArabic ? "شغال" : "ONLINE", value: "\(onlineCount)/\(store.servers.count)")
                HeroStatBox(label: "CPU", value: "4 OCPU")
            }
        }
        .padding()
        .background(LinearGradient(colors: [Color(red: 0.05, green: 0.35, blue: 0.65), Color(red: 0.32, green: 0.15, blue: 0.62)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .electricCyan.opacity(0.15), radius: 12, y: 6)
    }
    
    func iconForCategory(_ cat: String) -> String {
        switch cat {
        case "mod": return "puzzlepiece.extension.fill"
        case "power": return "power"
        case "create": return "plus.circle.fill"
        default: return "slider.horizontal.3"
        }
    }
    
    func colorForCategory(_ cat: String) -> Color {
        switch cat {
        case "mod": return .neonViolet
        case "power": return .emeraldGreen
        case "create": return .electricCyan
        default: return .orange
        }
    }
}

// ---------------------------------------------------------
// التبويب الثاني: سيرفراتي + شريط علوي يُسحب يميناً لإنشاء سيرفر
// ---------------------------------------------------------
struct ServersListTab: View {
    @EnvironmentObject var store: ServerStore
    @Binding var showNewServerSheet: Bool
    @Binding var preselectedGame: GameType
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // القسم العلوي القابل للسحب يميناً ويساراً (إنشاء سيرفر جديد)
                        if store.isOwner {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(store.isArabic ? "إنشاء سيرفر جديد (اسحب يميناً)" : "Create Server (Swipe)")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.electricCyan)
                                    Spacer()
                                    Image(systemName: "arrow.left.and.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        // بطاقة إنشاء سيرفر مخصص
                                        Button {
                                            preselectedGame = .arkAscended
                                            showNewServerSheet = true
                                        } label: {
                                            VStack(spacing: 8) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.title)
                                                    .foregroundColor(.white)
                                                Text(store.isArabic ? "إنشاء سيرفر" : "Create Server")
                                                    .font(.caption.bold())
                                                    .foregroundColor(.white)
                                            }
                                            .frame(width: 115, height: 105)
                                            .background(LinearGradient(colors: [.electricCyan, .neonViolet], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                        }
                                        
                                        // بطاقات الألعاب الجاهزة بأيقوناتها وألوانها
                                        ForEach(GameType.allCases) { game in
                                            Button {
                                                preselectedGame = game
                                                showNewServerSheet = true
                                            } label: {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    HStack {
                                                        Image(systemName: game.icon)
                                                            .font(.title3)
                                                            .foregroundColor(.white)
                                                        Spacer()
                                                        Text(game.shortBadge)
                                                            .font(.caption2.black())
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(Color.black.opacity(0.3))
                                                            .foregroundColor(.white)
                                                            .clipShape(Capsule())
                                                    }
                                                    Spacer()
                                                    Text(game.rawValue)
                                                        .font(.caption.bold())
                                                        .foregroundColor(.white)
                                                        .lineLimit(1)
                                                    Text("\(Int(game.recommendedRAM)) GB RAM")
                                                        .font(.caption2)
                                                        .foregroundColor(.white.opacity(0.8))
                                                }
                                                .padding(12)
                                                .frame(width: 145, height: 105)
                                                .background(LinearGradient(colors: game.themeColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // قائمة السيرفرات المثبتة بأيقونات ألعابها
                        VStack(alignment: .leading, spacing: 12) {
                            Text(store.isArabic ? "جميع السيرفرات (\(store.servers.count))" : "All Servers (\(store.servers.count))")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            ForEach(store.servers) { server in
                                NavigationLink(destination: ServerDetailView(serverId: server.id)) {
                                    GameServerCard(server: server, isArabic: store.isArabic)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(store.isArabic ? "سيرفراتي" : "My Servers")
        }
    }
}

struct GameServerCard: View {
    let server: GameServer
    let isArabic: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // أيقونة اللعبة بتدرج لوني خاص باللعبة (مثل ARK أو Minecraft)
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: server.game.themeColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 52, height: 52)
                    VStack(spacing: 2) {
                        Image(systemName: server.game.icon)
                            .font(.title3)
                            .foregroundColor(.white)
                        Text(server.game.shortBadge)
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(server.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(server.game.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(server.status == .running ? Color.emeraldGreen : Color.red)
                        .frame(width: 8, height: 8)
                    Text(server.status == .running ? (isArabic ? "شغال" : "Online") : (isArabic ? "متوقف" : "Offline"))
                        .font(.caption.bold())
                        .foregroundColor(server.status == .running ? .emeraldGreen : .red)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
            }
            
            Divider().background(Color.white.opacity(0.08))
            
            HStack {
                Label("\(server.ipAddress):\(server.port)", systemImage: "network")
                    .font(.caption.monospaced())
                    .foregroundColor(.electricCyan)
                Spacer()
                Text("RAM: \(String(format: "%.1f", server.ramUsedGB))/\(Int(server.ramTotalGB))GB")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .padding()
        .background(Color.cardBg)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(server.game.themeColors.first?.opacity(0.35) ?? Color.clear, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// ---------------------------------------------------------
// التبويب الثالث: الإعدادات، الصلاحيات، واللغة
// ---------------------------------------------------------
struct SettingsTab: View {
    @EnvironmentObject var store: ServerStore
    @State private var newOwnerPin = ""
    @State private var friendName = ""
    @State private var friendCode = ""
    @State private var allowPower = true
    @State private var allowEdit = true
    @State private var allowMods = false
    @State private var allowConsole = false
    
    @State private var urlInput = ""
    @State private var keyInput = ""
    @State private var demoToggle = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section(store.isArabic ? "المظهر واللغة" : "Language & Account") {
                    Toggle(store.isArabic ? "الواجهة العربية" : "Arabic Interface", isOn: $store.isArabic)
                        .tint(.electricCyan)
                    
                    Button(role: .destructive) {
                        store.logout()
                    } label: {
                        Label(store.isArabic ? "تسجيل الخروج وقفل التطبيق" : "Lock & Sign Out", systemImage: "lock.fill")
                    }
                }
                
                if store.isOwner {
                    Section(store.isArabic ? "إنشاء رمز دخول لأخوياك (مع تحديد القيود)" : "Create Friend Access Code") {
                        TextField(store.isArabic ? "اسم الشخص (مثال: أبو سعود)" : "Friend Name", text: $friendName)
                        TextField(store.isArabic ? "الرمز السري له (مثال: 5566)" : "PIN Code", text: $friendCode)
                            .keyboardType(.numberPad)
                        
                        Toggle(store.isArabic ? "السماح بالتشغيل والإيقاف" : "Allow Power Control", isOn: $allowPower).tint(.electricCyan)
                        Toggle(store.isArabic ? "السماح بتعديل إعدادات السيرفر" : "Allow Edit Settings", isOn: $allowEdit).tint(.electricCyan)
                        Toggle(store.isArabic ? "السماح بإضافة وحذف المودات" : "Allow Manage Mods", isOn: $allowMods).tint(.electricCyan)
                        Toggle(store.isArabic ? "السماح بأوامر الكونسول" : "Allow Console", isOn: $allowConsole).tint(.electricCyan)
                        
                        Button {
                            guard !friendName.isEmpty, !friendCode.isEmpty else { return }
                            let newAccess = AccessCode(
                                id: UUID().uuidString,
                                friendName: friendName,
                                code: friendCode,
                                canPowerControl: allowPower,
                                canEditSettings: allowEdit,
                                canManageMods: allowMods,
                                canUseConsole: allowConsole
                            )
                            store.addFriendCode(newAccess)
                            friendName = ""
                            friendCode = ""
                        } label: {
                            Label(store.isArabic ? "حفظ الرمز وتفعيل القيود" : "Save Access Code", systemImage: "key.fill")
                                .foregroundColor(.electricCyan)
                        }
                    }
                    
                    Section(store.isArabic ? "رموز أخوياك المحفوظة" : "Saved Friend Codes") {
                        ForEach(store.friendCodes) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(item.friendName) • الرمز: \(item.code)")
                                        .font(.subheadline.bold())
                                    Text("تشغيل: \(item.canPowerControl ? "✅" : "❌") | إعدادات: \(item.canEditSettings ? "✅" : "❌") | مودات: \(item.canManageMods ? "✅" : "❌")")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    store.removeFriendCode(id: item.id)
                                } label: {
                                    Image(systemName: "trash").foregroundColor(.red)
                                }
                            }
                        }
                    }
                    
                    Section(store.isArabic ? "رمز المالك الخاص بك" : "Owner PIN") {
                        HStack {
                            TextField(store.isArabic ? "رمز جديد (الحالي: \(store.ownerPin))" : "New PIN", text: $newOwnerPin)
                                .keyboardType(.numberPad)
                            Button(store.isArabic ? "حفظ" : "Save") {
                                store.updateOwnerPin(newPin: newOwnerPin)
                                newOwnerPin = ""
                            }
                            .foregroundColor(.electricCyan)
                        }
                    }
                    
                    Section(store.isArabic ? "ربط السيرفر السحابي (Pterodactyl API)" : "Cloud Server Connection") {
                        Toggle(store.isArabic ? "الوضع المحلي المحفوظ (بدون سيرفر خارجي)" : "Local Saved Mode", isOn: $demoToggle)
                            .tint(.electricCyan)
                        if !demoToggle {
                            TextField("https://panel.yourdomain.com", text: $urlInput)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                            SecureField("ptlc_xxxxxxxxxxxxxxxxxxxx", text: $keyInput)
                        }
                        Button(store.isArabic ? "حفظ إعدادات الربط" : "Save Connection") {
                            store.saveCredentials(url: urlInput, key: keyInput, demo: demoToggle)
                        }
                        .foregroundColor(.electricCyan)
                    }
                }
            }
            .onAppear {
                urlInput = store.panelURL
                keyInput = store.apiKey
                demoToggle = store.isDemoMode
            }
            .navigationTitle(store.isArabic ? "الإعدادات" : "Settings")
        }
    }
}

struct QuickActionTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct HeroStatBox: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundColor(.white.opacity(0.7))
            Text(value).font(.caption.bold()).foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.black.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct NewServerSheet: View {
    @EnvironmentObject var store: ServerStore
    @Environment(\.dismiss) var dismiss
    @State var selectedGame: GameType
    @State private var name = ""
    @State private var ramGB: Double = 16
    
    var body: some View {
        NavigationStack {
            Form {
                Section(store.isArabic ? "بيانات السيرفر الجديد" : "New Server Details") {
                    TextField(store.isArabic ? "اسم السيرفر (مثال: سيرفر العيال)" : "Server Name", text: $name)
                    Picker(store.isArabic ? "اللعبة" : "Game", selection: $selectedGame) {
                        ForEach(GameType.allCases) { game in
                            Text(game.rawValue).tag(game)
                        }
                    }
                    .onChange(of: selectedGame) { newGame in
                        ramGB = newGame.recommendedRAM
                    }
                    
                    VStack(alignment: .leading) {
                        Text("\(store.isArabic ? "الرام المخصص:" : "Allocated RAM:") \(Int(ramGB)) GB")
                        Slider(value: $ramGB, in: 2...24, step: 2)
                            .tint(.electricCyan)
                    }
                }
            }
            .onAppear { ramGB = selectedGame.recommendedRAM }
            .navigationTitle(store.isArabic ? "إنشاء سيرفر" : "Create Server")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(store.isArabic ? "إنشاء وحفظ" : "Create") {
                        let finalName = name.isEmpty ? "NOIR \(selectedGame.shortBadge)" : name
                        store.createNewServer(name: finalName, game: selectedGame, ramGB: ramGB)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(store.isArabic ? "إلغاء" : "Cancel") { dismiss() }
                }
            }
        }
    }
}

extension Color {
    static let appBg = Color(red: 0.04, green: 0.06, blue: 0.11)
    static let cardBg = Color(red: 0.08, green: 0.11, blue: 0.18)
    static let electricCyan = Color(red: 0.0, green: 0.83, blue: 1.0)
    static let neonViolet = Color(red: 0.55, green: 0.36, blue: 0.96)
    static let emeraldGreen = Color(red: 0.16, green: 0.85, blue: 0.52)
}
