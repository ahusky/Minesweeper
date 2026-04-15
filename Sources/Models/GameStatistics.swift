import Foundation

// MARK: - 单个难度的统计数据
struct DifficultyStats: Codable, Equatable {
    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var gamesLost: Int = 0
    var bestTime: Double? = nil  // 最快完成时间（秒，精确到0.1秒）
    var totalTime: Double = 0     // 总游戏时间（秒）
    var currentWinStreak: Int = 0
    var longestWinStreak: Int = 0
    var currentLoseStreak: Int = 0
    var longestLoseStreak: Int = 0
    
    // 计算属性
    var winRate: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(gamesWon) / Double(gamesPlayed) * 100
    }
    
    var averageTime: Double? {
        guard gamesWon > 0 else { return nil }
        return totalTime / Double(gamesWon)
    }
    
    // 记录一局胜利
    mutating func recordWin(time: Double) {
        gamesPlayed += 1
        gamesWon += 1
        totalTime += time
        
        // 更新最佳时间
        if let currentBest = bestTime {
            bestTime = min(currentBest, time)
        } else {
            bestTime = time
        }
        
        // 更新连胜
        currentWinStreak += 1
        longestWinStreak = max(longestWinStreak, currentWinStreak)
        currentLoseStreak = 0
    }
    
    // 记录一局失败
    mutating func recordLoss(time: Double) {
        gamesPlayed += 1
        gamesLost += 1
        
        // 更新连败
        currentLoseStreak += 1
        longestLoseStreak = max(longestLoseStreak, currentLoseStreak)
        currentWinStreak = 0
    }
    
    // 重置统计
    mutating func reset() {
        self = DifficultyStats()
    }
}

// MARK: - 游戏统计管理器
class GameStatistics: ObservableObject {
    static let shared = GameStatistics()
    
    @Published var beginnerStats = DifficultyStats()
    @Published var intermediateStats = DifficultyStats()
    @Published var expertStats = DifficultyStats()
    
    private let userDefaultsKey = "MinesweeperGameStatistics"
    
    private init() {
        load()
    }
    
    // MARK: - Public Methods
    
    func stats(for difficulty: Difficulty) -> DifficultyStats {
        switch difficulty {
        case .beginner: return beginnerStats
        case .intermediate: return intermediateStats
        case .expert: return expertStats
        }
    }
    
    func recordWin(difficulty: Difficulty, time: Double) {
        switch difficulty {
        case .beginner:
            beginnerStats.recordWin(time: time)
        case .intermediate:
            intermediateStats.recordWin(time: time)
        case .expert:
            expertStats.recordWin(time: time)
        }
        save()
    }
    
    func recordLoss(difficulty: Difficulty, time: Double) {
        switch difficulty {
        case .beginner:
            beginnerStats.recordLoss(time: time)
        case .intermediate:
            intermediateStats.recordLoss(time: time)
        case .expert:
            expertStats.recordLoss(time: time)
        }
        save()
    }
    
    func resetStats(for difficulty: Difficulty) {
        switch difficulty {
        case .beginner:
            beginnerStats.reset()
        case .intermediate:
            intermediateStats.reset()
        case .expert:
            expertStats.reset()
        }
        save()
    }
    
    func resetAllStats() {
        beginnerStats.reset()
        intermediateStats.reset()
        expertStats.reset()
        save()
    }
    
    // MARK: - 总计统计
    
    var totalGamesPlayed: Int {
        beginnerStats.gamesPlayed + intermediateStats.gamesPlayed + expertStats.gamesPlayed
    }
    
    var totalGamesWon: Int {
        beginnerStats.gamesWon + intermediateStats.gamesWon + expertStats.gamesWon
    }
    
    var totalGamesLost: Int {
        beginnerStats.gamesLost + intermediateStats.gamesLost + expertStats.gamesLost
    }
    
    var overallWinRate: Double {
        guard totalGamesPlayed > 0 else { return 0 }
        return Double(totalGamesWon) / Double(totalGamesPlayed) * 100
    }
    
    // MARK: - Persistence
    
    private func save() {
        let data = StatisticsData(
            beginner: beginnerStats,
            intermediate: intermediateStats,
            expert: expertStats
        )
        
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode(StatisticsData.self, from: data) else {
            return
        }
        
        beginnerStats = decoded.beginner
        intermediateStats = decoded.intermediate
        expertStats = decoded.expert
    }
}

// MARK: - 持久化数据结构
private struct StatisticsData: Codable {
    let beginner: DifficultyStats
    let intermediate: DifficultyStats
    let expert: DifficultyStats
}