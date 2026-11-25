import SwiftUI

struct GameSettingsView: View {
    @Binding var config: FullServerConfig
    let game: GameType
    let canEdit: Bool
    let isArabic: Bool
    let pendingCount: Int
    let onReviewAndSave: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if !canEdit {
                    Text(isArabic ? "🔒 وضع القراءة فقط: المالك قيّد تعديل الإعدادات لحسابك" : "🔒 Read-only mode")
                        .font(.caption.bold())
                        .foregroundColor(.electricCyan)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(Color.electricCyan.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // 1. الإعدادات العامة والمنصات (لكل الألعاب)
                SettingsAccordion(title: isArabic ? "1. الإعدادات العامة والمنصات واللاعبين" : "1. General, Platforms & Players", icon: "globe", defaultOpen: true) {
                    VStack(spacing: 12) {
                        Stepper(value: $config.maxPlayers, in: 2...500, step: 2) {
                            HStack {
                                Text(isArabic ? "الحد الأقصى للاعبين" : "Max Players").foregroundColor(.white)
                                Spacer()
                                Text("\(config.maxPlayers)").font(.headline.monospaced()).foregroundColor(.electricCyan)
                            }
                        }
                        Divider().background(Color.white.opacity(0.1))
                        Stepper(value: $config.autoSaveMinutes, in: 5...120, step: 5) {
                            HStack {
                                Text(isArabic ? "الحفظ التلقائي للعالم (دقائق)" : "Auto-Save Interval (min)").foregroundColor(.white)
                                Spacer()
                                Text("\(config.autoSaveMinutes)").font(.headline.monospaced()).foregroundColor(.electricCyan)
                            }
                        }
                    }
                    .padding().background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    SettingToggleCard(title: isArabic ? "اللعب المشترك (PC + Console / الجوال)" : "Crossplay (PC + Console)", isOn: $config.crossplayEnabled)
                    SettingToggleCard(title: isArabic ? "تفعيل القتال بين اللاعبين (PvP)" : "Enable PvP", isOn: $config.pvpEnabled)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isArabic ? "كلمة مرور السيرفر (اتركها فارغة للعام)" : "Server Password").font(.caption.bold()).foregroundColor(.gray)
                        TextField("Password...", text: $config.serverPassword)
                            .padding(10).background(Color.black.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        Text(isArabic ? "كلمة مرور الأدمن (Admin Password)" : "Admin Password").font(.caption.bold()).foregroundColor(.gray)
                        TextField("Admin Password...", text: $config.adminPassword)
                            .padding(10).background(Color.black.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        Text(isArabic ? "رسالة الترحيب عند الدخول (MOTD)" : "Message of the Day").font(.caption.bold()).foregroundColor(.gray)
                        TextField("MOTD...", text: $config.motdMessage)
                            .padding(10).background(Color.black.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding().background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canEdit)
                
                // 2. الإعدادات التفصيلية الكاملة حسب اللعبة
                Group {
                    switch game {
                    case .arkAscended:
                        arkCompleteSettings
                    case .minecraft:
                        minecraftCompleteSettings
                    case .fivem:
                        fivemCompleteSettings
                    case .rust:
                        rustCompleteSettings
                    case .palworld:
                        palworldCompleteSettings
                    case .cs2:
                        cs2CompleteSettings
                    case .terraria:
                        terrariaCompleteSettings
                    case .valheim:
                        valheimCompleteSettings
                    }
                }
                .disabled(!canEdit)
                
                if canEdit {
                    Button {
                        onReviewAndSave()
                    } label: {
                        Text(pendingCount == 0
                             ? (isArabic ? "جميع الإعدادات محفوظة ✓" : "All Settings Saved ✓")
                             : (isArabic ? "مراجعة وحفظ التعديلات (\(pendingCount))" : "Review & Save (\(pendingCount))"))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(pendingCount == 0 ? AnyShapeStyle(Color.white.opacity(0.1)) : AnyShapeStyle(LinearGradient(colors: [.electricCyan, .neonViolet], startPoint: .leading, endPoint: .trailing)))
                            .foregroundColor(pendingCount == 0 ? .gray : .white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(pendingCount == 0)
                    .padding(.bottom, 80)
                }
            }
            .padding()
        }
    }
    
    // =========================================================
    // كافة إعدادات ARK: Survival Ascended (5 أقسام شاملة)
    // =========================================================
    @ViewBuilder
    var arkCompleteSettings: some View {
        SettingsAccordion(title: isArabic ? "2. التجميع والموارد والخبرة (Rates)" : "2. Harvest, Taming & XP", icon: "hammer.fill", defaultOpen: true) {
            VStack(alignment: .leading, spacing: 8) {
                Text(isArabic ? "الخريطة النشطة (Map)" : "Active Map").font(.caption.bold()).foregroundColor(.gray)
                Picker("Map", selection: $config.mapName) {
                    Text("The Island").tag("TheIsland_WP")
                    Text("Scorched Earth").tag("ScorchedEarth_WP")
                    Text("The Center").tag("TheCenter_WP")
                    Text("Aberration").tag("Aberration_WP")
                    Text("Extinction").tag("Extinction_WP")
                }
                .tint(.electricCyan)
            }
            .padding().frame(maxWidth: .infinity, alignment: .leading).background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 12))
            
            CustomRateSlider(title: isArabic ? "مضاعف التجميع (Harvest Amount)" : "Harvest Amount", value: $config.harvestMultiplier, range: 1...100)
            CustomRateSlider(title: isArabic ? "صحة الموارد (Harvest Health)" : "Harvest Health", value: $config.harvestHealthMultiplier, range: 0.5...20)
            CustomRateSlider(title: isArabic ? "سرعة عودة الموارد (Respawn)" : "Resource Respawn", value: $config.resourceRespawnSpeed, range: 0.1...10)
            CustomRateSlider(title: isArabic ? "سرعة الترويض (Taming Speed)" : "Taming Speed", value: $config.tamingSpeed, range: 1...100)
            CustomRateSlider(title: isArabic ? "مضاعف الخبرة العام (XP)" : "Global XP", value: $config.xpMultiplier, range: 1...50)
            CustomRateSlider(title: isArabic ? "خبرة القتل (Kill XP)" : "Kill XP", value: $config.killXPMultiplier, range: 1...50)
            CustomRateSlider(title: isArabic ? "خبرة التجميع (Harvest XP)" : "Harvest XP", value: $config.harvestXPMultiplier, range: 1...50)
            CustomRateSlider(title: isArabic ? "خبرة التصنيع (Craft XP)" : "Craft XP", value: $config.craftXPMultiplier, range: 1...50)
            CustomRateSlider(title: isArabic ? "جودة اللوت والصناديق (Loot Quality)" : "Loot Quality", value: $config.lootQuality, range: 1...10)
            CustomRateSlider(title: isArabic ? "جودة لوت الصيد (Fishing Loot)" : "Fishing Loot", value: $config.fishingLootQuality, range: 1...10)
            CustomRateSlider(title: isArabic ? "تكديس الموارد (Stack Size)" : "Stack Size", value: $config.stackSizeMultiplier, range: 1...50)
            CustomRateSlider(title: isArabic ? "سرعة نمو المحاصيل (Crop Growth)" : "Crop Growth", value: $config.cropGrowthSpeed, range: 1...20)
            CustomRateSlider(title: isArabic ? "مدة بقاء الوقود (Fuel Interval)" : "Fuel Consumption", value: $config.fuelConsumptionInterval, range: 0.5...10)
        }
        
        SettingsAccordion(title: isArabic ? "3. التفريخ والتربية (Breeding)" : "3. Breeding & Maturation", icon: "heart.fill", defaultOpen: false) {
            CustomRateSlider(title: isArabic ? "سرعة فقس البيض (Egg Hatch)" : "Egg Hatch Speed", value: $config.eggHatchSpeed, range: 1...100)
            CustomRateSlider(title: isArabic ? "سرعة نمو الصغار (Baby Mature)" : "Baby Mature Speed", value: $config.babyMatureSpeed, range: 1...100)
            CustomRateSlider(title: isArabic ? "سرعة التزاوج (Mating Speed)" : "Mating Speed", value: $config.matingSpeed, range: 1...20)
            CustomRateSlider(title: isArabic ? "فترة انتظار التزاوج (Mating Interval)" : "Mating Interval", value: $config.matingInterval, range: 0.01...2)
            CustomRateSlider(title: isArabic ? "استهلاك أكل الصغار (Baby Food)" : "Baby Food Drain", value: $config.babyFoodConsumption, range: 0.1...5)
            CustomRateSlider(title: isArabic ? "مضاعف البصمة (Imprint Multiplier)" : "Imprint Multiplier", value: $config.babyImprintMultiplier, range: 1...20)
            CustomRateSlider(title: isArabic ? "وقت العناية بالصغير (Cuddle Interval)" : "Cuddle Interval", value: $config.babyCuddleInterval, range: 0.05...2)
            SettingToggleCard(title: isArabic ? "السماح لأي عضو بالقبيلة بعمل البصمة" : "Anyone Can Imprint", isOn: $config.anyoneCanImprint)
        }
        
        SettingsAccordion(title: isArabic ? "4. إحصائيات اللاعب (Player Stats)" : "4. Player Stats Multipliers", icon: "figure.run", defaultOpen: false) {
            CustomRateSlider(title: isArabic ? "وزن اللاعب (Weight)" : "Weight", value: $config.playerWeight, range: 1...100)
            CustomRateSlider(title: isArabic ? "صحة اللاعب (Health)" : "Health", value: $config.playerHealth, range: 1...20)
            CustomRateSlider(title: isArabic ? "طاقة اللاعب (Stamina)" : "Stamina", value: $config.playerStamina, range: 1...20)
            CustomRateSlider(title: isArabic ? "أكسجين اللاعب (Oxygen)" : "Oxygen", value: $config.playerOxygen, range: 1...20)
            CustomRateSlider(title: isArabic ? "سرعة الحركة (Speed)" : "Movement Speed", value: $config.playerSpeed, range: 1...10)
            CustomRateSlider(title: isArabic ? "قوة الضرب (Melee Damage)" : "Melee Damage", value: $config.playerDamage, range: 1...20)
            CustomRateSlider(title: isArabic ? "تحمل الحرارة والبرودة (Fortitude)" : "Fortitude", value: $config.playerFortitude, range: 1...20)
            CustomRateSlider(title: isArabic ? "سرعة التصنيع (Crafting Skill)" : "Crafting Skill", value: $config.playerCraftingSpeed, range: 1...20)
        }
        
        SettingsAccordion(title: isArabic ? "5. إحصائيات ومستويات الديناصورات (Dinos)" : "5. Dino Stats & Levels", icon: "lizard.fill", defaultOpen: false) {
            Stepper(value: $config.wildDinoMaxLevel, in: 30...600, step: 30) {
                HStack {
                    Text(isArabic ? "أقصى لفل للديناصورات البرية" : "Max Wild Dino Level").foregroundColor(.white)
                    Spacer()
                    Text("\(config.wildDinoMaxLevel)").font(.headline.monospaced()).foregroundColor(.electricCyan)
                }
            }
            .padding().background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 12))
            
            CustomRateSlider(title: isArabic ? "كثافة ظهور الديناصورات (Dino Count)" : "Dino Count", value: $config.dinoCountMultiplier, range: 0.5...3)
            CustomRateSlider(title: isArabic ? "وزن الديناصورات (Dino Weight)" : "Dino Weight", value: $config.dinoWeight, range: 1...100)
            CustomRateSlider(title: isArabic ? "صحة الديناصورات (Dino Health)" : "Dino Health", value: $config.dinoHealth, range: 1...20)
            CustomRateSlider(title: isArabic ? "طاقة الديناصورات (Dino Stamina)" : "Dino Stamina", value: $config.dinoStamina, range: 1...20)
            CustomRateSlider(title: isArabic ? "ضرر الديناصورات (Dino Damage)" : "Dino Damage", value: $config.dinoDamage, range: 1...20)
            CustomRateSlider(title: isArabic ? "سرعة الديناصورات (Dino Speed)" : "Dino Speed", value: $config.dinoSpeed, range: 1...10)
            SettingToggleCard(title: isArabic ? "تطوير سرعة الطيور (Flyer Speed Leveling)" : "Allow Flyer Speed Leveling", isOn: $config.allowFlyerSpeedLeveling)
            SettingToggleCard(title: isArabic ? "السماح بإطعام التايتن (Raid Dino Feeding)" : "Allow Raid Dino Feeding", isOn: $config.allowRaidDinoFeeding)
        }
        
        SettingsAccordion(title: isArabic ? "6. قوانين العالم والقبائل والبناء" : "6. World Rules, Tribes & Building", icon: "shield.lefthalf.filled", defaultOpen: false) {
            Stepper(value: $config.maxTribePlayers, in: 1...50) {
                HStack {
                    Text(isArabic ? "أقصى عدد لأعضاء القبيلة" : "Max Tribe Members").foregroundColor(.white)
                    Spacer()
                    Text("\(config.maxTribePlayers)").font(.headline.monospaced()).foregroundColor(.electricCyan)
                }
            }
            .padding().background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 12))
            
            CustomRateSlider(title: isArabic ? "سرعة النهار (Day Speed)" : "Day Speed", value: $config.dayTimeSpeed, range: 0.1...5)
            CustomRateSlider(title: isArabic ? "سرعة الليل (Night Speed)" : "Night Speed", value: $config.nightTimeSpeed, range: 0.1...10)
            CustomRateSlider(title: isArabic ? "استهلاك الأكل (Food Drain)" : "Food Drain", value: $config.playerFoodDrain, range: 0.1...3)
            CustomRateSlider(title: isArabic ? "استهلاك الماء (Water Drain)" : "Water Drain", value: $config.playerWaterDrain, range: 0.1...3)
            CustomRateSlider(title: isArabic ? "مباني السرج والمنصات (Platform Multiplier)" : "Platform Structures", value: $config.platformStructureMultiplier, range: 1...10)
            
            SettingToggleCard(title: isArabic ? "السماح بالطيران داخل الكهوف" : "Allow Cave Flyers", isOn: $config.allowCaveFlyers)
            SettingToggleCard(title: isArabic ? "السماح بالبناء داخل الكهوف" : "Allow Cave Building", isOn: $config.allowCaveBuildingPvE)
            SettingToggleCard(title: isArabic ? "إظهار موقع اللاعب على الخريطة" : "Show Player on Map", isOn: $config.showMapPlayerLocation)
            SettingToggleCard(title: isArabic ? "تفعيل المنظور الثالث (Third Person)" : "Allow Third Person", isOn: $config.allowThirdPerson)
            SettingToggleCard(title: isArabic ? "إظهار مؤشر التصويب (Crosshair)" : "Enable Crosshair", isOn: $config.enableCrosshair)
            SettingToggleCard(title: isArabic ? "إظهار أرقام الضرر (Floating Damage)" : "Floating Damage Text", isOn: $config.showFloatingDamage)
            SettingToggleCard(title: isArabic ? "منع تحلل المباني تلقائياً" : "Disable Structure Decay", isOn: $config.disableStructureDecay)
            SettingToggleCard(title: isArabic ? "حماية الهجوم أوفلاين (ORP)" : "Offline Raid Protection", isOn: $config.enableOfflineRaidProtection)
            SettingToggleCard(title: isArabic ? "مكافحة الغش (BattlEye)" : "Enable BattlEye", isOn: $config.allowBattlEye)
        }
    }
    
    // =========================================================
    // كافة إعدادات Minecraft
    // =========================================================
    @ViewBuilder
    var minecraftCompleteSettings: some View {
        SettingsAccordion(title: isArabic ? "2. إعدادات اللعب والصعوبة (Gameplay)" : "2. Gameplay & Difficulty", icon: "cube.fill", defaultOpen: true) {
            VStack(spacing: 12) {
                HStack {
                    Text(isArabic ? "وضع اللعب (Gamemode)" : "Gamemode").foregroundColor(.white)
                    Spacer()
                    Picker("", selection: $config.mcGameMode) {
                        Text("Survival").tag("survival")
                        Text("Creative").tag("creative")
                        Text("Adventure").tag("adventure")
                        Text("Spectator").tag("spectator")
                    }.tint(.electricCyan)
                }
                Divider().background(Color.white.opacity(0.1))
                HStack {
                    Text(isArabic ? "مستوى الصعوبة (Difficulty)" : "Difficulty").foregroundColor(.white)
                    Spacer()
                    Picker("", selection: $config.mcDifficulty) {
                        Text("Peaceful").tag("peaceful")
                        Text("Easy").tag("easy")
                        Text("Normal").tag("normal")
                        Text("Hard").tag("hard")
                    }.tint(.electricCyan)
                }
                Divider().background(Color.white.opacity(0.1))
                HStack {
                    Text(isArabic ? "نوع العالم (Level Type)" : "World Type").foregroundColor(.white)
                    Spacer()
                    Picker("", selection: $config.mcLevelType) {
                        Text("Normal").tag("minecraft:normal")
                        Text("Flat").tag("minecraft:flat")
                        Text("Amplified").tag("minecraft:amplified")
                        Text("Large Biomes").tag("minecraft:large_biomes")
                    }.tint(.electricCyan)
                }
            }
            .padding().background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 12))
            
            SettingToggleCard(title: isArabic ? "وضع الهاردكور (Hardcore)" : "Hardcore Mode", isOn: $config.mcHardcore)
            SettingToggleCard(title: isArabic ? "الاحتفاظ بالأغراض عند الموت (Keep Inventory)" : "Keep Inventory", isOn: $config.mcKeepInventory)
            SettingToggleCard(title: isArabic ? "السماح بالحسابات المكركة (Offline Mode)" : "Allow Cracked Accounts", isOn: Binding(
                get: { !config.mcOnlineMode },
                set: { config.mcOnlineMode = !$0 }
            ))
            SettingToggleCard(title: isArabic ? "تفعيل القائمة البيضاء (Whitelist)" : "Enable Whitelist", isOn: $config.mcWhiteList)
        }
        
        SettingsAccordion(title: isArabic ? "3. إعدادات العالم والأداء والكائنات" : "3. World, Performance & Mobs", icon: "slider.horizontal.3", defaultOpen: true) {
            VStack(spacing: 12) {
                Stepper(value: $config.mcViewDistance, in: 4...32) {
                    HStack {
                        Text(isArabic ? "مسافة الرؤية (View Distance)" : "View Distance").foregroundColor(.white)
                        Spacer()
                        Text("\(config.mcViewDistance) Chunks").foregroundColor(.electricCyan)
                    }
                }
                Divider().background(Color.white.opacity(0.1))
                Stepper(value: $config.mcSimulationDistance, in: 4...32) {
                    HStack {
                        Text(isArabic ? "مسافة المحاكاة (Simulation)" : "Simulation Distance").foregroundColor(.white)
                        Spacer()
                        Text("\(config.mcSimulationDistance) Chunks").foregroundColor(.electricCyan)
                    }
                }
                Divider().background(Color.white.opacity(0.1))
                Stepper(value: $config.mcSpawnProtection, in: 0...64, step: 4) {
                    HStack {
                        Text(isArabic ? "حماية منطقة البداية (Spawn)" : "Spawn Protection").foregroundColor(.white)
                        Spacer()
                        Text("\(config.mcSpawnProtection)").foregroundColor(.electricCyan)
                    }
                }
            }
            .padding().background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 12))
            
            SettingToggleCard(title: isArabic ? "تفعيل عالم النذر (Allow Nether)" : "Allow Nether", isOn: $config.mcAllowNether)
            SettingToggleCard(title: isArabic ? "تفعيل عالم الإند (Allow End)" : "Allow End", isOn: $config.mcAllowEnd)
            SettingToggleCard(title: isArabic ? "تفعيل بلوكات الأوامر (Command Blocks)" : "Enable Command Blocks", isOn: $config.mcEnableCommandBlock)
            SettingToggleCard(title: isArabic ? "السماح بالطيران (Allow Flight)" : "Allow Flight", isOn: $config.mcAllowFlight)
            SettingToggleCard(title: isArabic ? "ظهور الوحوش (Spawn Monsters)" : "Spawn Monsters", isOn: $config.mcSpawnMonsters)
            SettingToggleCard(title: isArabic ? "ظهور الحيوانات (Spawn Animals)" : "Spawn Animals", isOn: $config.mcSpawnAnimals)
            SettingToggleCard(title: isArabic ? "ظهور القرويين (Spawn NPCs)" : "Spawn Villagers", isOn: $config.mcSpawnNPCs)
            SettingToggleCard(title: isArabic ? "تخريب الكريبر والوحوش (Mob Griefing)" : "Mob Griefing", isOn: $config.mcMobGriefing)
            SettingToggleCard(title: isArabic ? "انتشار النار (Fire Spread)" : "Fire Spread", isOn: $config.mcDoFireTick)
        }
    }
    
    // =========================================================
    // كافة إعدادات FiveM (GTA V)
    // =========================================================
    @ViewBuilder
    var fivemCompleteSettings: some View {
        SettingsAccordion(title: isArabic ? "2. إعدادات FiveM و OneSync والمفاتيح" : "2. FiveM, OneSync & Keys", icon: "car.fill", defaultOpen: true) {
            VStack(spacing: 12) {
                HStack {
                    Text(isArabic ? "نظام OneSync" : "OneSync Mode").foregroundColor(.white)
                    Spacer()
                    Picker("", selection: $config.fivemOneSync) {
                        Text("Infinity (On)").tag("on")
                        Text("Legacy").tag("legacy")
                        Text("Off").tag("off")
                    }.tint(.electricCyan)
                }
                Divider().background(Color.white.opacity(0.1))
                HStack {
                    Text(isArabic ? "إصدار اللعبة (Game Build)" : "Game Build").foregroundColor(.white)
                    Spacer()
                    Picker("", selection: $config.fivemGameBuild) {
                        Text("3258 (Bottom Dollar)").tag("3258")
                        Text("3095 (Chop Shop)").tag("3095")
                        Text("2944 (Mercenaries)").tag("2944")
                        Text("2802 (Drug Wars)").tag("2802")
                        Text("2699 (Criminal Ent)").tag("2699")
                    }.tint(.electricCyan)
                }
                Divider().background(Color.white.opacity(0.1))
                Stepper(value: $config.fivemMaxPing, in: 50...1000, step: 25) {
                    HStack {
                        Text(isArabic ? "أقصى بنق مسموح (Max Ping)" : "Max Ping").foregroundColor(.white)
                        Spacer()
                        Text("\(config.fivemMaxPing) ms").foregroundColor(.electricCyan)
                    }
                }
            }
            .padding().background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 12))
            
            SettingToggleCard(title: isArabic ? "تفعيل المحادثة الصوتية (Voice Chat)" : "Enable Voice Chat", isOn: $config.fivemVoiceChat)
            SettingToggleCard(title: isArabic ? "تفعيل لوحة txAdmin" : "Enable txAdmin Panel", isOn: $config.fivemTxAdminEnabled)
            SettingToggleCard(title: isArabic ? "السماح بـ ScriptHook (مودات اللاعب)" : "Allow ScriptHook", isOn: $config.fivemScriptHook)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Cfx.re License Key").font(.caption.bold()).foregroundColor(.gray)
                TextField("cfxk_...", text: $config.fivemLicenseKey)
                    .padding(10).background(Color.black.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 10))
                Text("Steam Web API Key").font(.caption.bold()).foregroundColor(.gray)
                TextField("API Key...", text: $config.fivemSteamWebApiKey)
                    .padding(10).background(Color.black.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding().background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // =========================================================
    // كافة إعدادات Rust
    // =========================================================
    @ViewBuilder
    var rustCompleteSettings: some View {
        SettingsAccordion(title: isArabic ? "2. إعدادات عالم وموارد Rust" : "2. Rust World & Rates", icon: "flame.fill", defaultOpen: true) {
            CustomRateSlider(title: isArabic ? "مضاعف الموارد (Gather Rate)" : "Gather Rate", value: $config.rustGatherRate, range: 1...20)
            CustomRateSlider(title: isArabic ? "سرعة الصهر (Smelting Speed)" : "Smelting Speed", value: $config.rustSmeltingSpeed, range: 1...20)
            CustomRateSlider(title: isArabic ? "سرعة التصنيع (Crafting Speed)" : "Crafting Speed", value: $config.rustCraftingSpeed, range: 1...20)
            CustomRateSlider(title: isArabic ? "تكديس الأغراض (Stack Multiplier)" : "Stack Multiplier", value: $config.rustStackMultiplier, range: 1...20)
            CustomRateSlider(title: isArabic ? "نسبة تحلل المباني (Decay Scale)" : "Decay Scale", value: $config.rustDecayScale, range: 0...2)
            CustomRateSlider(title: isArabic ? "تكلفة صيانة البيت (Upkeep Scale)" : "Upkeep Scale", value: $config.rustUpkeepScale, range: 0...2)
            
            VStack(spacing: 12) {
                Stepper(value: $config.rustWorldSize, in: 1000...6000, step: 500) {
                    HStack {
                        Text(isArabic ? "حجم الخريطة (World Size)" : "World Size").foregroundColor(.white)
                        Spacer()
                        Text("\(config.rustWorldSize)").foregroundColor(.electricCyan)
                    }
                }
                Divider().background(Color.white.opacity(0.1))
                Stepper(value: $config.rustMaxTeamSize, in: 1...16) {
                    HStack {
                        Text(isArabic ? "أقصى حجم للفريق (Team Size)" : "Max Team Size").foregroundColor(.white)
                        Spacer()
                        Text("\(config.rustMaxTeamSize)").foregroundColor(.electricCyan)
                    }
                }
            }
            .padding().background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 12))
            
            SettingToggleCard(title: isArabic ? "تفعيل الإشعاع (Radiation)" : "Enable Radiation", isOn: $config.rustRadiation)
            SettingToggleCard(title: isArabic ? "حدث الهليكوبتر (Patrol Helicopter)" : "Patrol Helicopter Event", isOn: $config.rustHelicopterEvent)
        }
    }
    
    // =========================================================
    // كافة إعدادات Palworld / CS2 / Terraria / Valheim
    // =========================================================
    @ViewBuilder
    var palworldCompleteSettings: some View {
        SettingsAccordion(title: isArabic ? "2. إعدادات عالم Palworld" : "2. Palworld Settings", icon: "pawprint.fill", defaultOpen: true) {
            CustomRateSlider(title: isArabic ? "نسبة صيد الـ Pals (Capture Rate)" : "Pal Capture Rate", value: $config.palCaptureRate, range: 0.5...10)
            CustomRateSlider(title: isArabic ? "معدل ظهور الـ Pals (Spawn Rate)" : "Pal Spawn Rate", value: $config.palSpawnRate, range: 0.5...5)
            CustomRateSlider(title: isArabic ? "مضاعف الخبرة (XP)" : "XP Rate", value: $config.xpMultiplier, range: 1...20)
            CustomRateSlider(title: isArabic ? "سرعة عمل الـ Pals في القاعدة" : "Pal Work Speed", value: $config.palWorkSpeed, range: 0.5...10)
            CustomRateSlider(title: isArabic ? "مضاعف سقوط الموارد (Drop Items)" : "Drop Item Multiplier", value: $config.palDropItemMultiplier, range: 1...10)
            SettingToggleCard(title: isArabic ? "تفعيل هجمات الغزاة على القاعدة (Raids)" : "Enable Base Raids", isOn: $config.palEnableInvader)
        }
    }
    
    @ViewBuilder
    var cs2CompleteSettings: some View {
        SettingsAccordion(title: isArabic ? "2. إعدادات Counter-Strike 2" : "2. CS2 Settings", icon: "scope", defaultOpen: true) {
            VStack(spacing: 12) {
                HStack {
                    Text(isArabic ? "نمط اللعب" : "Game Mode").foregroundColor(.white)
                    Spacer()
                    Picker("", selection: $config.cs2GameMode) {
                        Text("Competitive").tag("Competitive")
                        Text("Premier").tag("Premier")
                        Text("Deathmatch").tag("Deathmatch")
                        Text("Casual").tag("Casual")
                    }.tint(.electricCyan)
                }
                Divider().background(Color.white.opacity(0.1))
                Stepper(value: $config.cs2MaxRounds, in: 10...30, step: 2) {
                    HStack {
                        Text(isArabic ? "عدد الجولات (Max Rounds)" : "Max Rounds").foregroundColor(.white)
                        Spacer()
                        Text("\(config.cs2MaxRounds)").foregroundColor(.electricCyan)
                    }
                }
                Divider().background(Color.white.opacity(0.1))
                Stepper(value: $config.cs2StartMoney, in: 800...16000, step: 800) {
                    HStack {
                        Text(isArabic ? "فلوس البداية (Start Money)" : "Start Money").foregroundColor(.white)
                        Spacer()
                        Text("$\(config.cs2StartMoney)").foregroundColor(.electricCyan)
                    }
                }
            }
            .padding().background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 12))
            SettingToggleCard(title: isArabic ? "تفعيل النيران الصديقة (Friendly Fire)" : "Friendly Fire", isOn: $config.cs2FriendlyFire)
            SettingToggleCard(title: isArabic ? "درع مجاني في البداية (Free Armor)" : "Free Armor", isOn: $config.cs2FreeArmor)
        }
    }
    
    @ViewBuilder
    var terrariaCompleteSettings: some View {
        SettingsAccordion(title: isArabic ? "2. إعدادات عالم Terraria" : "2. Terraria World", icon: "leaf.fill", defaultOpen: true) {
            VStack(spacing: 12) {
                HStack {
                    Text(isArabic ? "حجم العالم" : "World Size").foregroundColor(.white)
                    Spacer()
                    Picker("", selection: $config.terrariaWorldSize) {
                        Text("Small").tag("Small")
                        Text("Medium").tag("Medium")
                        Text("Large").tag("Large")
                    }.tint(.electricCyan)
                }
                Divider().background(Color.white.opacity(0.1))
                HStack {
                    Text(isArabic ? "مستوى الصعوبة" : "Difficulty").foregroundColor(.white)
                    Spacer()
                    Picker("", selection: $config.terrariaDifficulty) {
                        Text("Classic").tag("Classic")
                        Text("Expert").tag("Expert")
                        Text("Master").tag("Master")
                        Text("Journey").tag("Journey")
                    }.tint(.electricCyan)
                }
            }
            .padding().background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    @ViewBuilder
    var valheimCompleteSettings: some View {
        SettingsAccordion(title: isArabic ? "2. إعدادات عالم Valheim" : "2. Valheim Settings", icon: "shield.fill", defaultOpen: true) {
            CustomRateSlider(title: isArabic ? "مضاعف الموارد (Resource Rate)" : "Resource Rate", value: $config.valheimResourceRate, range: 1...5)
            SettingToggleCard(title: isArabic ? "نقل المعادن عبر البوابات (Portal All Items)" : "Portal All Items", isOn: $config.valheimPortalAllItems)
            SettingToggleCard(title: isArabic ? "بناء مجاني بدون موارد (No Build Cost)" : "No Build Cost", isOn: $config.valheimNoBuildCost)
        }
    }
}

// مكون القائمة القابلة للفتح والطي
struct SettingsAccordion<Content: View>: View {
    let title: String
    let icon: String
    @State var isExpanded: Bool
    @ViewBuilder let content: () -> Content
    
    init(title: String, icon: String, defaultOpen: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self._isExpanded = State(initialValue: defaultOpen)
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.electricCyan)
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundColor(.electricCyan)
                }
                .padding()
                .background(Color(red: 0.11, green: 0.15, blue: 0.24))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
            if isExpanded {
                VStack(spacing: 10) {
                    content()
                }
            }
        }
    }
}
