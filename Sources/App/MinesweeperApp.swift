import SwiftUI

@main
struct MinesweeperApp: App {
    @StateObject private var game = GameModel(difficulty: .beginner)
    @StateObject private var statistics = GameStatistics.shared
    @State private var showStatistics = false
    @State private var showHelp = false

    var body: some Scene {
        WindowGroup {
            MainGameView(game: game, statistics: statistics, showStatistics: $showStatistics, showHelp: $showHelp)
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
                
                Button("Statistics...") {
                    showStatistics = true
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
            
            // 帮助菜单
            CommandGroup(replacing: .help) {
                Button("Minesweeper Help") {
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
    @Binding var showStatistics: Bool
    @Binding var showHelp: Bool
    
    private let cellSize: CGFloat = 24
    
    private var boardWidth: CGFloat {
        CGFloat(game.cols) * cellSize
    }

    private var windowTitle: String {
        switch game.gameState {
        case .ready:
            return "Minesweeper - \(game.difficulty.rawValue)"
        case .playing:
            return "Minesweeper - Playing..."
        case .won:
            return "Minesweeper - 🎉 Victory! \(game.elapsedTime)s"
        case .lost:
            return "Minesweeper - 💥 Game Over"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 难度选择栏
            HStack(spacing: 4) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    DifficultyButton(
                        difficulty: difficulty,
                        isSelected: game.difficulty == difficulty,
                        bestTime: statistics.stats(for: difficulty).bestTime
                    ) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            game.changeDifficulty(difficulty)
                        }
                    }
                }
                
                Spacer()
                
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
        .background(Color(nsColor: .controlColor))
        .fixedSize()
        .navigationTitle(windowTitle)
        .sheet(isPresented: $showStatistics) {
            StatisticsView(statistics: statistics)
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
    }
    
    private var borderColor: Color {
        switch game.gameState {
        case .won:
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
    let bestTime: Int?
    let action: () -> Void
    
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(difficulty.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                
                HStack(spacing: 3) {
                    Text("\(difficulty.cols)×\(difficulty.rows)")
                        .font(.system(size: 9))
                    
                    if let best = bestTime {
                        Text("·")
                            .font(.system(size: 9))
                        Text("🏆\(best)s")
                            .font(.system(size: 9))
                    }
                }
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