import SwiftUI

// MARK: - 统计视图
struct StatisticsView: View {
    @ObservedObject var statistics: GameStatistics
    @State private var selectedDifficulty: Difficulty = .beginner
    @State private var showResetAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("📊 游戏统计")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // 难度选择器
            Picker("难度", selection: $selectedDifficulty) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    Text(difficulty.rawValue).tag(difficulty)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // 统计内容
            ScrollView {
                VStack(spacing: 16) {
                    // 当前难度统计
                    difficultyStatsCard(for: selectedDifficulty)
                    
                    // 总体统计
                    overallStatsCard
                }
                .padding()
            }
            
            Divider()
            
            // 底部按钮
            HStack {
                Button("重置当前难度") {
                    showResetAlert = true
                }
                .foregroundColor(.red)
                
                Spacer()
                
                Button("关闭") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()
        }
        .frame(width: 360, height: 520)
        .alert("确认重置", isPresented: $showResetAlert) {
            Button("取消", role: .cancel) { }
            Button("重置", role: .destructive) {
                statistics.resetStats(for: selectedDifficulty)
            }
        } message: {
            Text("确定要重置【\(selectedDifficulty.rawValue)】难度的统计数据吗？此操作不可撤销。")
        }
    }
    
    // MARK: - 当前难度统计卡片
    @ViewBuilder
    private func difficultyStatsCard(for difficulty: Difficulty) -> some View {
        let stats = statistics.stats(for: difficulty)
        
        GroupBox {
            VStack(spacing: 12) {
                // 游戏次数
                HStack {
                    StatItem(title: "总局数", value: "\(stats.gamesPlayed)", icon: "gamecontroller")
                    Spacer()
                    StatItem(title: "胜利", value: "\(stats.gamesWon)", icon: "trophy", color: .green)
                    Spacer()
                    StatItem(title: "失败", value: "\(stats.gamesLost)", icon: "xmark.circle", color: .red)
                }
                
                Divider()
                
                // 胜率和时间
                HStack {
                    StatItem(
                        title: "胜率",
                        value: String(format: "%.1f%%", stats.winRate),
                        icon: "percent"
                    )
                    Spacer()
                    StatItem(
                        title: "最快时间",
                        value: stats.bestTime.map { formatTime($0) } ?? "--",
                        icon: "bolt.fill",
                        color: .orange
                    )
                    Spacer()
                    StatItem(
                        title: "平均时间",
                        value: stats.averageTime.map { formatTime($0) } ?? "--",
                        icon: "clock"
                    )
                }
                
                Divider()
                
                // 连胜/连败
                HStack {
                    StatItem(
                        title: "当前连胜",
                        value: "\(stats.currentWinStreak)",
                        icon: "flame",
                        color: stats.currentWinStreak > 0 ? .orange : .secondary
                    )
                    Spacer()
                    StatItem(
                        title: "最长连胜",
                        value: "\(stats.longestWinStreak)",
                        icon: "crown",
                        color: .yellow
                    )
                    Spacer()
                    StatItem(
                        title: "最长连败",
                        value: "\(stats.longestLoseStreak)",
                        icon: "hand.thumbsdown",
                        color: .gray
                    )
                }
            }
            .padding(.vertical, 8)
        } label: {
            Label("\(difficulty.rawValue) (\(difficulty.cols)×\(difficulty.rows))", systemImage: difficultyIcon(difficulty))
                .font(.subheadline.bold())
        }
    }
    
    // MARK: - 总体统计卡片
    private var overallStatsCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    StatItem(title: "总局数", value: "\(statistics.totalGamesPlayed)", icon: "sum")
                    Spacer()
                    StatItem(title: "总胜利", value: "\(statistics.totalGamesWon)", icon: "trophy.fill", color: .green)
                    Spacer()
                    StatItem(
                        title: "总胜率",
                        value: String(format: "%.1f%%", statistics.overallWinRate),
                        icon: "chart.pie"
                    )
                }
            }
            .padding(.vertical, 8)
        } label: {
            Label("总体统计", systemImage: "chart.bar.xaxis")
                .font(.subheadline.bold())
        }
    }
    
    // MARK: - Helper Methods
    private func formatTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)秒"
        } else {
            let mins = seconds / 60
            let secs = seconds % 60
            return "\(mins)分\(secs)秒"
        }
    }
    
    private func difficultyIcon(_ difficulty: Difficulty) -> String {
        switch difficulty {
        case .beginner: return "1.circle"
        case .intermediate: return "2.circle"
        case .expert: return "3.circle"
        }
    }
}

// MARK: - 统计项组件
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .primary
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            Text(value)
                .font(.system(.title3, design: .rounded).bold())
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 70)
    }
}

