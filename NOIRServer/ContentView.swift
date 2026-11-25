import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ServerStore
    @State private var showNewServerSheet = false
    @State private var preselectedGame: GameType = .arkAscended
    @State private var showSettingsSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        resourceHeaderCard
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text(store.isArabic ? "سيرفراتي (\(store.servers.count))" : "My Servers (\(store.servers.count))")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Button {
                                    preselectedGame = .arkAscended
                                    showNewServerSheet = true
                                } label: {
                                    Label(store.isArabic ? "إنشاء سيرفر" : "Create", systemImage: "plus.circle.fill")
                                        .font(.subheadline.bold())
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.amberGold)
                                        .foregroundColor(.black)
                                        .clipShape(Capsule())
                                }
                            }
                            
                            ForEach(store.servers) { server in
                                NavigationLink(destination: ServerDetailView(serverId: server.id)) {
                                    ServerCardView(server: server, isArabic: store.isArabic)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text(store.isArabic ? "ألعاب جاهزة للإنشاء الفوري" : "Available Games to Deploy")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(GameType.allCases) { game in
                                    Button {
                                        preselectedGame = game
                                        showNewServerSheet = true
                                    } label: {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Image(systemName: game.icon)
                                                    .font(.title3)
                                                    .foregroundColor(.amberGold)
                                                Spacer()
                                                Image(systemName: "plus.circle")
                                                    .foregroundColor(.gray)
                                            }
                                            Text(game.rawValue)
                                                .font(.caption.bold())
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                            Text("\(store.isArabic ? "الموصى:" : "Rec:") \(Int(game.recommendedRAM))GB RAM")
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                        .padding(12)
                                        .background(Color(red: 0.10, green: 0.10, blue: 0.13))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                if let toast = store.toastMessage {
                    VStack {
                        Spacer()
                        Text(toast)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.amberGold)
                            .foregroundColor(.black)
                            .clipShape(Capsule())
                            .shadow(radius: 10)
                            .padding(.bottom, 20)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("NOIR SERVER")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        store.isArabic.toggle()
                    } label: {
                        Text(store.isArabic ? "EN" : "عربي")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.amberGold)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettingsSheet = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.amberGold)
                    }
                }
            }
            .sheet(isPresented: $showNewServerSheet) {
                NewServerSheet(selectedGame: preselectedGame)
            }
            .sheet(isPresented: $showSettingsSheet) {
                APISettingsSheet()
            }
        }
        .environment(\.layoutDirection, store.isArabic ? .rightToLeft : .leftToRight)
    }
    
    var resourceHeaderCard: some View {
        let totalUsedRAM = store.servers.reduce(0) { $0 + $1.ramUsedGB }
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.isArabic ? "السحابة المجانية • Oracle ARM" : "Free Cloud • Oracle ARM")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(store.isDemoMode ? (store.isArabic ? "وضع المعاينة التجريبي" : "Demo Preview Mode") : (store.isArabic ? "متصل بالسيرفر السحابي" : "Connected to Cloud"))
                        .font(.subheadline.bold())
                        .foregroundColor(.amberGold)
                }
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.amberGold.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Text("N")
                        .font(.title3.bold())
                        .foregroundColor(.amberGold)
                }
            }
            
            HStack(spacing: 12) {
                StatPill(title: "RAM", value: "\(String(format: "%.1f", totalUsedRAM)) / 24 GB")
                StatPill(title: "CPU", value: "4 OCPU")
                StatPill(title: "SERVERS", value: "\(store.servers.count)")
            }
        }
        .padding()
        .background(Color(red: 0.10, green: 0.10, blue: 0.13))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.amberGold.opacity(0.35), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ServerCardView: View {
    let server: GameServer
    let isArabic: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: server.game.icon)
                    .font(.title2)
                    .foregroundColor(.amberGold)
                    .frame(width: 44, height: 44)
                    .background(Color.amberGold.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
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
                        .fill(server.status == .running ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(server.status == .running ? (isArabic ? "شغال" : "Online") : (isArabic ? "متوقف" : "Offline"))
                        .font(.caption.bold())
                        .foregroundColor(server.status == .running ? .green : .red)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            HStack {
                Label("\(server.ipAddress):\(server.port)", systemImage: "network")
                    .font(.caption.monospaced())
                    .foregroundColor(.gray)
                Spacer()
                Text("RAM: \(String(format: "%.1f", server.ramUsedGB))/\(Int(server.ramTotalGB))GB")
                    .font(.caption.bold())
                    .foregroundColor(.amberGold)
            }
        }
        .padding()
        .background(Color(red: 0.10, green: 0.10, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StatPill: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2).foregroundColor(.gray)
            Text(value).font(.caption.bold()).foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
                Section(store.isArabic ? "إعداد السيرفر الجديد" : "New Server Setup") {
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
                            .tint(.amberGold)
                    }
                }
            }
            .onAppear {
                ramGB = selectedGame.recommendedRAM
            }
            .navigationTitle(store.isArabic ? "إنشاء سيرفر" : "Deploy Server")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(store.isArabic ? "إنشاء الآن" : "Deploy") {
                        let finalName = name.isEmpty ? "NOIR \(selectedGame.rawValue)" : name
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

struct APISettingsSheet: View {
    @EnvironmentObject var store: ServerStore
    @Environment(\.dismiss) var dismiss
    @State private var urlInput = ""
    @State private var keyInput = ""
    @State private var demoToggle = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section(store.isArabic ? "وضع التشغيل" : "Connection Mode") {
                    Toggle(store.isArabic ? "وضع المعاينة التجريبي (Demo)" : "Demo Mode", isOn: $demoToggle)
                        .tint(.amberGold)
                }
                
                if !demoToggle {
                    Section(store.isArabic ? "ربط لوحة Pterodactyl" : "Pterodactyl API") {
                        TextField("https://panel.yourdomain.com", text: $urlInput)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                        SecureField("ptlc_xxxxxxxxxxxxxxxxxxxx", text: $keyInput)
                    }
                }
            }
            .onAppear {
                urlInput = store.panelURL
                keyInput = store.apiKey
                demoToggle = store.isDemoMode
            }
            .navigationTitle(store.isArabic ? "إعدادات الربط" : "API Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(store.isArabic ? "حفظ" : "Save") {
                        store.saveCredentials(url: urlInput, key: keyInput, demo: demoToggle)
                        dismiss()
                    }
                }
            }
        }
    }
}

extension Color {
    static let amberGold = Color(red: 0.95, green: 0.72, blue: 0.25)
}
