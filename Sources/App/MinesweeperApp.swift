import SwiftUI
import AppKit

@main
struct MinesweeperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var game = GameModel(difficulty: .beginner)
    @StateObject private var statistics = GameStatistics.shared
    @StateObject private var leaderboard = LeaderboardManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    @State private var showStatsCenter = false
    @State private var showHelp = false

    var body: some Scene {
        WindowGroup {
            MainGameView(
                game: game,
                statistics: statistics,
                leaderboard: leaderboard,
                showStatsCenter: $showStatsCenter,
                showHelp: $showHelp
            )
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
            
            // 游戏菜单
            CommandMenu("menu.game".localized) {
                Button("menu.newGame".localized) {
                    game.newGame()
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("menu.newGame".localized) {
                    game.newGame()
                }
                .keyboardShortcut(.space, modifiers: [])
                
                Divider()
                
                ForEach(Array(Difficulty.allCases.enumerated()), id: \.element) { index, difficulty in
                    Button {
                        game.changeDifficulty(difficulty)
                    } label: {
                        let checkmark = game.difficulty == difficulty ? "✓ " : "   "
                        Text("\(checkmark)\(difficulty.localizedName) (\(difficulty.cols)×\(difficulty.rows), \(difficulty.mines) \("menu.mines".localized))")
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                }
                
                Divider()
                
                Button("menu.statisticsCenter".localized) {
                    showStatsCenter = true
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
            
            // 帮助菜单
            CommandGroup(replacing: .help) {
                Button("app.help".localized) {
                    showHelp = true
                }
                .keyboardShortcut("?", modifiers: .command)
            }
            
            // 语言菜单
            CommandMenu("Language") {
                ForEach(LanguageManager.AppLanguage.allCases, id: \.self) { language in
                    Button {
                        languageManager.currentLanguage = language
                    } label: {
                        let checkmark = languageManager.currentLanguage == language ? "✓ " : "   "
                        Text("\(checkmark)\(language.flag) \(language.displayName)")
                    }
                }
            }
        }
    }
}

// MARK: - 主游戏视图
struct MainGameView: View {
    @ObservedObject var game: GameModel
    @ObservedObject var statistics: GameStatistics
    @ObservedObject var leaderboard: LeaderboardManager
    @ObservedObject var languageManager = LanguageManager.shared
    @Binding var showStatsCenter: Bool
    @Binding var showHelp: Bool
    
    @State private var showRecordCelebration = false
    @State private var boardScale: CGFloat = 1.0
    @State private var refreshID = UUID()
    
    private let cellSize: CGFloat = 28
    
    private var boardWidth: CGFloat {
        CGFloat(game.cols) * cellSize
    }

    private var windowTitle: String {
        let appName = "app.name".localized
        switch game.gameState {
        case .ready:
            return "\(appName) - \(game.difficulty.localizedName)"
        case .playing:
            return "\(appName) - " + "state.playing".localized
        case .won:
            let timeStr = String(format: "%.1f", game.elapsedTime)
            if game.isNewAllTimeRecord {
                return "\(appName) - 🏆 " + "state.newRecord".localized + " \(timeStr)s"
            } else if game.isNewTodayRecord {
                return "\(appName) - ⭐ " + "state.todayBest".localized + " \(timeStr)s"
            }
            return "\(appName) - 🎉 " + "state.won".localized + " \(timeStr)s"
        case .lost:
            return "\(appName) - 💥 " + "state.lost".localized
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 顶部工具栏
                toolbarView
                
                // 顶部信息栏
                HeaderView(game: game)
                    .frame(width: boardWidth)
                    .padding(.bottom, 6)

                // 游戏面板 + 状态边框
                GameBoardView(game: game)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .strokeBorder(borderColor, lineWidth: 3)
                            .animation(.easeInOut(duration: 0.3), value: game.gameState)
                    )
                    .scaleEffect(boardScale)
            }
            .padding(10)
            .background(AppColors.windowBackground)
            
            // 新纪录庆祝弹窗
            if showRecordCelebration && (game.isNewTodayRecord || game.isNewAllTimeRecord) {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showRecordCelebration = false
                        }
                    }
                
                NewRecordCelebration(
                    isNewTodayRecord: game.isNewTodayRecord,
                    isNewAllTimeRecord: game.isNewAllTimeRecord,
                    time: game.elapsedTime
                )
                .transition(.scale.combined(with: .opacity))
                .onTapGesture {
                    withAnimation {
                        showRecordCelebration = false
                    }
                }
            }
        }
        .fixedSize()
        .navigationTitle(windowTitle)
        .onChange(of: game.gameState) { oldValue, newValue in
            if newValue == .won && (game.isNewTodayRecord || game.isNewAllTimeRecord) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showRecordCelebration = true
                }
                // 5秒后自动关闭
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation {
                        showRecordCelebration = false
                    }
                }
            }
            
            // 游戏结束时的轻微缩放动画
            if newValue == .won || newValue == .lost {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    boardScale = 0.98
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.15)) {
                    boardScale = 1.0
                }
            }
        }
        .onChange(of: game.difficulty) { _, _ in
            // 切换难度时的动画
            boardScale = 0.95
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                boardScale = 1.0
            }
        }
        .sheet(isPresented: $showStatsCenter) {
            StatsCenter(statistics: statistics, leaderboard: leaderboard)
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        .id(refreshID)
        .onChange(of: languageManager.currentLanguage) { _, _ in
            // 语言切换时刷新视图
            refreshID = UUID()
        }
    }
    
    // MARK: - 工具栏视图
    private var toolbarView: some View {
        HStack(spacing: 6) {
            // 难度选择按钮组
            HStack(spacing: 4) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    GameDifficultyButton(
                        difficulty: difficulty,
                        isSelected: game.difficulty == difficulty
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            game.changeDifficulty(difficulty)
                        }
                    }
                }
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.controlBackground.opacity(0.5))
            )
            
            Spacer()
            
            // 工具按钮组
            HStack(spacing: 2) {
                ToolbarButton(
                    icon: "questionmark.circle",
                    helpText: "toolbar.help".localized
                ) {
                    showHelp = true
                }
                
                ToolbarButton(
                    icon: "chart.bar.fill",
                    helpText: "toolbar.statistics".localized
                ) {
                    showStatsCenter = true
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }
    
    private var borderColor: Color {
        switch game.gameState {
        case .won:
            if game.isNewAllTimeRecord {
                return Color.yellow.opacity(0.9)
            } else if game.isNewTodayRecord {
                return Color.orange.opacity(0.8)
            }
            return Color.green.opacity(0.8)
        case .lost:
            return Color.red.opacity(0.6)
        default:
            return Color.clear
        }
    }
}

// MARK: - 游戏难度按钮
struct GameDifficultyButton: View {
    let difficulty: Difficulty
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    private var mineIcon: String {
        switch difficulty {
        case .beginner: return "🟢"
        case .intermediate: return "🟡"
        case .expert: return "🔴"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(mineIcon)
                    .font(.system(size: 10))
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(difficulty.localizedName)
                        .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    Text("\(difficulty.cols)×\(difficulty.rows)")
                        .font(.system(size: 9))
                        .foregroundColor(isSelected ? .white.opacity(0.75) : .secondary)
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundColor)
                    .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : .clear, radius: 4, y: 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor
        } else if isHovered {
            return AppColors.controlBackground
        } else {
            return Color.clear
        }
    }
}

// MARK: - 工具栏按钮
struct ToolbarButton: View {
    let icon: String
    let helpText: String
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isHovered ? Color.accentColor : Color.secondary)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHovered ? AppColors.controlBackground : Color.clear)
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .help(helpText)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.08)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.08)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - App Delegate
/// 处理关闭窗口时退出应用（单窗口应用）
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
