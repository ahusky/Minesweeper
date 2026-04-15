import SwiftUI

@main
struct MinesweeperApp: App {
    @StateObject private var game = GameModel(difficulty: .beginner)
    @StateObject private var statistics = GameStatistics.shared
    @StateObject private var leaderboard = LeaderboardManager.shared
    @State private var showStatistics = false
    @State private var showHelp = false
    @State private var showLeaderboard = false

    var body: some Scene {
        WindowGroup {
            MainGameView(
                game: game,
                statistics: statistics,
                leaderboard: leaderboard,
                showStatistics: $showStatistics,
                showHelp: $showHelp,
                showLeaderboard: $showLeaderboard
            )
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
            
            // 游戏菜单
            CommandMenu("Game") {
                Button("New Game") {
                    game.newGame()
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("New Game") {
                    game.newGame()
                }
                .keyboardShortcut(.space, modifiers: [])
                
                Divider()
                
                ForEach(Array(Difficulty.allCases.enumerated()), id: \.element) { index, difficulty in
                    Button {
                        game.changeDifficulty(difficulty)
                    } label: {
                        let checkmark = game.difficulty == difficulty ? "✓ " : "   "
                        Text("\(checkmark)\(difficulty.rawValue) (\(difficulty.cols)×\(difficulty.rows), \(difficulty.mines) mines)")
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                }
                
                Divider()
                
                Button("Leaderboard...") {
                    showLeaderboard = true
                }
                .keyboardShortcut("l", modifiers: .command)
                
                Button("Statistics...") {
                    showStatistics = true
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
            
            // 帮助菜单
            CommandGroup(replacing: .help) {
                Button("扫雷Lite 帮助") {
                    showHelp = true
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }
    }
}

// MARK: - 主游戏视图
struct MainGameView: View {
    @ObservedObject var game: GameModel
    @ObservedObject var statistics: GameStatistics
    @ObservedObject var leaderboard: LeaderboardManager
    @Binding var showStatistics: Bool
    @Binding var showHelp: Bool
    @Binding var showLeaderboard: Bool
    
    @State private var showRecordCelebration = false
    
    private let cellSize: CGFloat = 24
    
    private var boardWidth: CGFloat {
        CGFloat(game.cols) * cellSize
    }

    private var windowTitle: String {
        switch game.gameState {
        case .ready:
            return "扫雷Lite - \(game.difficulty.rawValue)"
        case .playing:
            return "扫雷Lite - 游戏中..."
        case .won:
            let timeStr = String(format: "%.1f", game.elapsedTime)
            if game.isNewAllTimeRecord {
                return "扫雷Lite - 🏆 新纪录! \(timeStr)s"
            } else if game.isNewTodayRecord {
                return "扫雷Lite - ⭐ 今日最佳! \(timeStr)s"
            }
            return "扫雷Lite - 🎉 胜利! \(timeStr)s"
        case .lost:
            return "扫雷Lite - 💥 失败"
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 难度选择栏
                HStack(spacing: 4) {
                    ForEach(Difficulty.allCases, id: \.self) { difficulty in
                        DifficultyButton(
                            difficulty: difficulty,
                            isSelected: game.difficulty == difficulty
                        ) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                game.changeDifficulty(difficulty)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // 排行榜按钮
                    Button(action: { showLeaderboard = true }) {
                        Image(systemName: "trophy")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Leaderboard (⌘L)")
                    
                    // 帮助按钮
                    Button(action: { showHelp = true }) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Help (⌘?)")
                    
                    // 统计按钮
                    Button(action: { showStatistics = true }) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Statistics (⇧⌘S)")
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)

                // 顶部信息栏
                HeaderView(game: game)
                    .frame(width: boardWidth)
                    .padding(.bottom, 6)

                // 游戏面板 + 状态边框
                GameBoardView(game: game)
                    .overlay(
                        RoundedRectangle(cornerRadius: 1)
                            .strokeBorder(borderColor, lineWidth: 3)
                            .animation(.easeInOut(duration: 0.3), value: game.gameState)
                    )
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
                // 3秒后自动关闭
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showRecordCelebration = false
                    }
                }
            }
        }
        .sheet(isPresented: $showStatistics) {
            StatisticsView(statistics: statistics)
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        .sheet(isPresented: $showLeaderboard) {
            LeaderboardView(leaderboard: leaderboard)
        }
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

// MARK: - 难度选择按钮
struct DifficultyButton: View {
    let difficulty: Difficulty
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(difficulty.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                
                Text("\(difficulty.cols)×\(difficulty.rows)")
                    .font(.system(size: 9))
                    .foregroundColor(isSelected ? .white.opacity(0.85) : .secondary)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(buttonBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        isHovered && !isSelected ? Color.gray.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }
    
    private var buttonBackgroundColor: Color {
        if isSelected {
            return Color.accentColor
        } else if isHovered {
            return Color(nsColor: .controlBackgroundColor).opacity(0.8)
        } else {
            return Color.clear
        }
    }
}
