import SwiftUI

// MARK: - 统计中心（整合统计 + 排行榜）
struct StatsCenter: View {
    @ObservedObject var statistics: GameStatistics
    @ObservedObject var leaderboard: LeaderboardManager
    @State private var selectedDifficulty: Difficulty = .beginner
    @State private var selectedTab: StatsTab = .overview
    @State private var showResetAlert = false
    @State private var animateContent = false
    @Environment(\.dismiss) private var dismiss
    
    enum StatsTab: String, CaseIterable {
        case overview = "概览"
        case leaderboard = "排行榜"
        case details = "详细"
        
        var icon: String {
            switch self {
            case .overview: return "chart.pie.fill"
            case .leaderboard: return "trophy.fill"
            case .details: return "list.bullet.clipboard.fill"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            headerView
            
            // 难度选择 + 标签页（合并为一个区域）
            VStack(spacing: 12) {
                // 难度选择按钮组
                difficultySelector
                
                // 自定义标签栏
                tabBar
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.controlBackground.opacity(0.5))
            
            // 内容区域
            ScrollView {
                VStack(spacing: 16) {
                    switch selectedTab {
                    case .overview:
                        overviewContent
                    case .leaderboard:
                        leaderboardContent
                    case .details:
                        detailsContent
                    }
                }
                .padding(16)
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 10)
            
            Divider()
            
            // 底部按钮
            footerView
        }
        .frame(width: 420, height: 600)
        .background(AppColors.windowBackground)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                animateContent = true
            }
        }
        .onChange(of: selectedTab) { _, _ in
            animateContent = false
            withAnimation(.easeOut(duration: 0.25)) {
                animateContent = true
            }
        }
        .onChange(of: selectedDifficulty) { _, _ in
            animateContent = false
            withAnimation(.easeOut(duration: 0.2)) {
                animateContent = true
            }
        }
        .alert("确认重置", isPresented: $showResetAlert) {
            Button("取消", role: .cancel) { }
            Button("重置", role: .destructive) {
                statistics.resetStats(for: selectedDifficulty)
                leaderboard.clearRecords(for: selectedDifficulty)
            }
        } message: {
            Text("确定要重置【\(selectedDifficulty.rawValue)】的所有数据吗？包括统计和排行榜记录，此操作不可撤销。")
        }
    }
    
    // MARK: - 标题栏
    private var headerView: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.title2)
                    .foregroundStyle(.linearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                Text("统计中心")
                    .font(.headline)
            }
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.panelBackground)
    }
    
    // MARK: - 难度选择器
    private var difficultySelector: some View {
        HStack(spacing: 8) {
            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                DifficultyChip(
                    difficulty: difficulty,
                    isSelected: selectedDifficulty == difficulty
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDifficulty = difficulty
                    }
                }
            }
        }
    }
    
    // MARK: - 自定义标签栏
    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(StatsTab.allCases, id: \.self) { tab in
                TabButton(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppColors.controlBackground)
        )
    }
    
    // MARK: - 底部按钮
    private var footerView: some View {
        HStack {
            Button(action: { showResetAlert = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                    Text("重置数据")
                }
                .font(.callout)
                .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button("完成") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding(16)
    }
    
    // MARK: - 概览内容
    private var overviewContent: some View {
        let stats = statistics.stats(for: selectedDifficulty)
        let todayStats = leaderboard.getTodayStats(for: selectedDifficulty)
        let allTimeBest = leaderboard.getAllTimeBest(for: selectedDifficulty)
        
        return VStack(spacing: 16) {
            // 时间记录卡片
            StatsCard(title: "时间记录", icon: "clock.fill", iconColor: .blue) {
                HStack(spacing: 0) {
                    StatCell(
                        emoji: "⭐",
                        value: todayStats.bestTime.map { String(format: "%.1f", $0) } ?? "--",
                        unit: "秒",
                        label: "今日最佳",
                        valueColor: .orange
                    )
                    
                    Divider().frame(height: 50)
                    
                    StatCell(
                        emoji: "🏆",
                        value: allTimeBest.map { String(format: "%.1f", $0) } ?? "--",
                        unit: "秒",
                        label: "历史最佳",
                        valueColor: .yellow
                    )
                    
                    Divider().frame(height: 50)
                    
                    StatCell(
                        emoji: "⏱️",
                        value: stats.averageTime.map { String(format: "%.1f", $0) } ?? "--",
                        unit: "秒",
                        label: "平均时间",
                        valueColor: .blue
                    )
                }
            }
            
            // 战绩卡片
            StatsCard(title: "战绩统计", icon: "gamecontroller.fill", iconColor: .green) {
                HStack(spacing: 0) {
                    StatCell(
                        emoji: "📅",
                        value: "\(todayStats.won)/\(todayStats.played)",
                        unit: nil,
                        label: "今日战绩",
                        valueColor: .green
                    )
                    
                    Divider().frame(height: 50)
                    
                    StatCell(
                        emoji: "📊",
                        value: "\(stats.gamesWon)/\(stats.gamesPlayed)",
                        unit: nil,
                        label: "总战绩",
                        valueColor: .primary
                    )
                    
                    Divider().frame(height: 50)
                    
                    StatCell(
                        emoji: "📈",
                        value: String(format: "%.1f", stats.winRate),
                        unit: "%",
                        label: "胜率",
                        valueColor: stats.winRate >= 50 ? .green : .orange
                    )
                }
            }
            
            // 连胜卡片
            StatsCard(title: "连胜记录", icon: "flame.fill", iconColor: .orange) {
                HStack(spacing: 0) {
                    StatCell(
                        emoji: "🔥",
                        value: "\(stats.currentWinStreak)",
                        unit: nil,
                        label: "当前连胜",
                        valueColor: stats.currentWinStreak > 0 ? .orange : .secondary
                    )
                    
                    Divider().frame(height: 50)
                    
                    StatCell(
                        emoji: "👑",
                        value: "\(stats.longestWinStreak)",
                        unit: nil,
                        label: "最长连胜",
                        valueColor: .yellow
                    )
                    
                    Divider().frame(height: 50)
                    
                    StatCell(
                        emoji: "💀",
                        value: "\(stats.longestLoseStreak)",
                        unit: nil,
                        label: "最长连败",
                        valueColor: .gray
                    )
                }
            }
        }
    }
    
    // MARK: - 排行榜内容
    @State private var leaderboardType: LeaderboardType = .today
    
    private var leaderboardContent: some View {
        VStack(spacing: 16) {
            // 排行榜类型选择
            HStack(spacing: 8) {
                ForEach(LeaderboardType.allCases, id: \.self) { type in
                    LeaderboardTypeChip(
                        type: type,
                        isSelected: leaderboardType == type
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            leaderboardType = type
                        }
                    }
                }
            }
            
            // 排行榜列表
            let records = getRecords()
            
            StatsCard(
                title: leaderboardTitle,
                icon: "list.number",
                iconColor: .purple,
                trailingText: "\(records.count) 条记录"
            ) {
                if records.isEmpty {
                    VStack(spacing: 12) {
                        Text("🏆")
                            .font(.system(size: 48))
                            .opacity(0.4)
                        Text("暂无记录")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("完成游戏后将显示在这里")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, minHeight: 180)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                            LeaderboardRow(
                                rank: index + 1,
                                record: record,
                                showDate: leaderboardType != .today
                            )
                            
                            if index < records.count - 1 {
                                Divider()
                                    .padding(.leading, 48)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var leaderboardTitle: String {
        switch leaderboardType {
        case .today: return "今日排行"
        case .allTime: return "历史排行"
        case .recent7Days: return "近7天排行"
        }
    }
    
    private func getRecords() -> [GameRecord] {
        switch leaderboardType {
        case .today:
            return leaderboard.getTodayLeaderboard(for: selectedDifficulty)
        case .allTime:
            return leaderboard.getAllTimeLeaderboard(for: selectedDifficulty)
        case .recent7Days:
            return leaderboard.getRecentLeaderboard(for: selectedDifficulty)
        }
    }
    
    // MARK: - 详细统计内容
    private var detailsContent: some View {
        VStack(spacing: 16) {
            // 当前难度详细
            difficultyDetailCard(for: selectedDifficulty)
            
            // 总体统计
            overallStatsCard
        }
    }
    
    private func difficultyDetailCard(for difficulty: Difficulty) -> some View {
        let stats = statistics.stats(for: difficulty)
        
        return StatsCard(
            title: "\(difficulty.rawValue) (\(difficulty.cols)×\(difficulty.rows))",
            icon: "square.grid.3x3.fill",
            iconColor: .indigo
        ) {
            VStack(spacing: 12) {
                // 基础数据
                HStack {
                    DetailItem(icon: "gamecontroller", title: "总局数", value: "\(stats.gamesPlayed)")
                    Spacer()
                    DetailItem(icon: "checkmark.circle", title: "胜利", value: "\(stats.gamesWon)", color: .green)
                    Spacer()
                    DetailItem(icon: "xmark.circle", title: "失败", value: "\(stats.gamesLost)", color: .red)
                }
                
                Divider()
                
                // 时间数据
                HStack {
                    DetailItem(icon: "bolt.fill", title: "最快", value: stats.bestTime.map { formatTime($0) } ?? "--", color: .orange)
                    Spacer()
                    DetailItem(icon: "clock", title: "平均", value: stats.averageTime.map { formatTime($0) } ?? "--")
                    Spacer()
                    DetailItem(icon: "percent", title: "胜率", value: String(format: "%.1f%%", stats.winRate))
                }
                
                Divider()
                
                // 连胜数据
                HStack {
                    DetailItem(icon: "flame", title: "当前连胜", value: "\(stats.currentWinStreak)", color: stats.currentWinStreak > 0 ? .orange : .secondary)
                    Spacer()
                    DetailItem(icon: "crown", title: "最长连胜", value: "\(stats.longestWinStreak)", color: .yellow)
                    Spacer()
                    DetailItem(icon: "hand.thumbsdown", title: "最长连败", value: "\(stats.longestLoseStreak)", color: .gray)
                }
            }
        }
    }
    
    private var overallStatsCard: some View {
        StatsCard(title: "全部难度汇总", icon: "chart.bar.xaxis", iconColor: .teal) {
            HStack {
                DetailItem(icon: "sum", title: "总局数", value: "\(statistics.totalGamesPlayed)")
                Spacer()
                DetailItem(icon: "trophy.fill", title: "总胜利", value: "\(statistics.totalGamesWon)", color: .green)
                Spacer()
                DetailItem(icon: "chart.pie", title: "总胜率", value: String(format: "%.1f%%", statistics.overallWinRate))
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        if seconds < 60 {
            return String(format: "%.1fs", seconds)
        } else {
            let mins = Int(seconds) / 60
            let secs = seconds.truncatingRemainder(dividingBy: 60)
            return String(format: "%dm%.1fs", mins, secs)
        }
    }
}

// MARK: - 难度选择芯片
struct DifficultyChip: View {
    let difficulty: Difficulty
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(difficulty.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                Text("\(difficulty.cols)×\(difficulty.rows)")
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : (isHovered ? AppColors.controlBackground : Color.clear))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - 标签按钮
struct TabButton: View {
    let tab: StatsCenter.StatsTab
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 12))
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(isSelected ? AppColors.panelBackground : Color.clear)
                    .shadow(color: isSelected ? .black.opacity(0.1) : .clear, radius: 2, y: 1)
            )
            .foregroundColor(isSelected ? .primary : .secondary)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - 排行榜类型选择芯片
struct LeaderboardTypeChip: View {
    let type: LeaderboardType
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    private var icon: String {
        switch type {
        case .today: return "sun.max.fill"
        case .allTime: return "crown.fill"
        case .recent7Days: return "calendar"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(type.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : (isHovered ? AppColors.controlBackground : AppColors.controlBackground.opacity(0.5)))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - 统计卡片
struct StatsCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    var trailingText: String? = nil
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 14, weight: .semibold))
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Spacer()
                
                if let trailing = trailingText {
                    Text(trailing)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            content()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.panelBackground)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

// MARK: - 统计单元格
struct StatCell: View {
    let emoji: String
    let value: String
    let unit: String?
    let label: String
    let valueColor: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(emoji)
                .font(.title2)
            
            HStack(spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundColor(valueColor)
                if let unit = unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 详细项目
struct DetailItem: View {
    let icon: String
    let title: String
    let value: String
    var color: Color = .primary
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16))
            Text(value)
                .font(.system(.callout, design: .rounded).bold())
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 65)
    }
}

// MARK: - 排行榜行
struct LeaderboardRow: View {
    let rank: Int
    let record: GameRecord
    let showDate: Bool
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 排名徽章
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                if rank <= 3 {
                    Text(medalEmoji)
                        .font(.system(size: 18))
                } else {
                    Text("\(rank)")
                        .font(.system(.callout, design: .rounded).bold())
                        .foregroundColor(rankColor)
                }
            }
            
            // 时间和日期
            VStack(alignment: .leading, spacing: 2) {
                Text(record.formattedTime)
                    .font(.system(.body, design: .rounded).bold())
                if showDate {
                    Text(record.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 排名标签
            if rank <= 3 {
                Text(rankLabel)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(rankColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(rankColor.opacity(0.15))
                    )
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? AppColors.controlBackground.opacity(0.5) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .secondary
        }
    }
    
    private var medalEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }
    
    private var rankLabel: String {
        switch rank {
        case 1: return "第一名"
        case 2: return "第二名"
        case 3: return "第三名"
        default: return ""
        }
    }
}

// MARK: - 新纪录庆祝视图
struct NewRecordCelebration: View {
    let isNewTodayRecord: Bool
    let isNewAllTimeRecord: Bool
    let time: Double
    
    @State private var scale: CGFloat = 0.8
    @State private var rotation: Double = -5
    
    var body: some View {
        VStack(spacing: 20) {
            // 图标动画
            Text(isNewAllTimeRecord ? "🏆" : "⭐")
                .font(.system(size: 72))
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                        scale = 1.0
                        rotation = 0
                    }
                }
            
            // 标题
            Text(isNewAllTimeRecord ? "新纪录！" : "今日最佳！")
                .font(.title.bold())
                .foregroundStyle(
                    isNewAllTimeRecord
                        ? LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            
            // 时间
            HStack(spacing: 4) {
                Text(String(format: "%.1f", time))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text("秒")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .offset(y: 8)
            }
            
            // 副标题
            Text(isNewAllTimeRecord ? "打破历史最佳记录！" : "创造今日新纪录！")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding(36)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.panelBackground)
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: isNewAllTimeRecord ? [.yellow.opacity(0.5), .orange.opacity(0.3)] : [.orange.opacity(0.5), .red.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
    }
}