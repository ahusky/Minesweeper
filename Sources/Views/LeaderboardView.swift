import SwiftUI

// MARK: - 排行榜视图
struct LeaderboardView: View {
    @ObservedObject var leaderboard: LeaderboardManager
    @State private var selectedDifficulty: Difficulty = .beginner
    @State private var selectedType: LeaderboardType = .today
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            headerView
            
            Divider()
            
            // 难度选择
            Picker("难度", selection: $selectedDifficulty) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    Text(difficulty.rawValue).tag(difficulty)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 12)
            
            // 今日概览卡片
            todayOverviewCard
                .padding(.horizontal)
                .padding(.top, 12)
            
            // 排行榜类型选择
            Picker("类型", selection: $selectedType) {
                ForEach(LeaderboardType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 12)
            
            // 排行榜列表
            leaderboardList
            
            Divider()
            
            // 底部按钮
            HStack {
                Spacer()
                Button("关闭") { dismiss() }
                    .keyboardShortcut(.escape)
            }
            .padding()
        }
        .frame(width: 380, height: 560)
    }
    
    // MARK: - 标题栏
    private var headerView: some View {
        HStack {
            Text("🏆 排行榜")
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
    }
    
    // MARK: - 今日概览卡片
    private var todayOverviewCard: some View {
        let stats = leaderboard.getTodayStats(for: selectedDifficulty)
        let allTimeBest = leaderboard.getAllTimeBest(for: selectedDifficulty)
        
        return GroupBox {
            HStack(spacing: 20) {
                // 今日最佳
                VStack(spacing: 4) {
                    Text("今日最佳")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let best = stats.bestTime {
                        Text(String(format: "%.1f秒", best))
                            .font(.system(.title2, design: .rounded).bold())
                            .foregroundColor(.orange)
                    } else {
                        Text("--")
                            .font(.system(.title2, design: .rounded).bold())
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)
                
                // 历史最佳
                VStack(spacing: 4) {
                    Text("历史最佳")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let best = allTimeBest {
                        Text(String(format: "%.1f秒", best))
                            .font(.system(.title2, design: .rounded).bold())
                            .foregroundColor(.green)
                    } else {
                        Text("--")
                            .font(.system(.title2, design: .rounded).bold())
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)
                
                // 今日战绩
                VStack(spacing: 4) {
                    Text("今日战绩")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(stats.won)/\(stats.played)")
                        .font(.system(.title2, design: .rounded).bold())
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
        } label: {
            Label("📅 今日概览", systemImage: "calendar")
                .font(.subheadline.bold())
        }
    }
    
    // MARK: - 排行榜列表
    private var leaderboardList: some View {
        let records = getRecordsForCurrentType()
        
        return GroupBox {
            if records.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("暂无记录")
                        .foregroundColor(.secondary)
                    Text("完成一局游戏后将显示在这里")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                            LeaderboardRow(rank: index + 1, record: record, showDate: selectedType != .today)
                            
                            if index < records.count - 1 {
                                Divider()
                                    .padding(.leading, 44)
                            }
                        }
                    }
                }
            }
        } label: {
            HStack {
                Label(leaderboardTitle, systemImage: "list.number")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(records.count) 条记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
    
    private var leaderboardTitle: String {
        switch selectedType {
        case .today: return "今日排行"
        case .allTime: return "历史排行"
        case .recent7Days: return "近7天排行"
        }
    }
    
    private func getRecordsForCurrentType() -> [GameRecord] {
        switch selectedType {
        case .today:
            return leaderboard.getTodayLeaderboard(for: selectedDifficulty)
        case .allTime:
            return leaderboard.getAllTimeLeaderboard(for: selectedDifficulty)
        case .recent7Days:
            return leaderboard.getRecentLeaderboard(for: selectedDifficulty)
        }
    }
}

// MARK: - 排行榜行
struct LeaderboardRow: View {
    let rank: Int
    let record: GameRecord
    let showDate: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // 排名
            rankBadge
            
            // 时间
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
            
            // 排名图标
            if rank <= 3 {
                medalIcon
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var rankBadge: some View {
        ZStack {
            Circle()
                .fill(rankColor.opacity(0.15))
                .frame(width: 32, height: 32)
            
            Text("\(rank)")
                .font(.system(.callout, design: .rounded).bold())
                .foregroundColor(rankColor)
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
    
    @ViewBuilder
    private var medalIcon: some View {
        switch rank {
        case 1:
            Text("🥇")
                .font(.title2)
        case 2:
            Text("🥈")
                .font(.title2)
        case 3:
            Text("🥉")
                .font(.title2)
        default:
            EmptyView()
        }
    }
}

// MARK: - 新纪录庆祝视图
struct NewRecordCelebration: View {
    let isNewTodayRecord: Bool
    let isNewAllTimeRecord: Bool
    let time: Double
    
    var body: some View {
        VStack(spacing: 16) {
            // 图标
            if isNewAllTimeRecord {
                Text("🏆")
                    .font(.system(size: 60))
            } else {
                Text("⭐")
                    .font(.system(size: 60))
            }
            
            // 标题
            Text(isNewAllTimeRecord ? "新纪录！" : "今日最佳！")
                .font(.title.bold())
                .foregroundColor(isNewAllTimeRecord ? .yellow : .orange)
            
            // 时间（精确到0.1秒）
            Text(String(format: "%.1f 秒", time))
                .font(.system(size: 36, weight: .bold, design: .rounded))
            
            // 副标题
            if isNewAllTimeRecord {
                Text("打破历史最佳记录！")
                    .foregroundColor(.secondary)
            } else if isNewTodayRecord {
                Text("创造今日新纪录！")
                    .foregroundColor(.secondary)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(radius: 10)
        )
    }
}
