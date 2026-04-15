import Foundation

// MARK: - 单局游戏记录
struct GameRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let difficulty: String  // 使用 String 存储以便 Codable
    let time: Double        // 完成时间（秒，精确到0.1秒）
    let date: Date          // 游戏完成时间
    let isWin: Bool
    
    init(difficulty: Difficulty, time: Double, isWin: Bool) {
        self.id = UUID()
        self.difficulty = difficulty.rawValue
        self.time = time
        self.date = Date()
        self.isWin = isWin
    }
    
    var difficultyEnum: Difficulty? {
        Difficulty.allCases.first { $0.rawValue == difficulty }
    }
    
    // 判断是否是今天的记录
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    // 格式化时间（精确到0.1秒）
    var formattedTime: String {
        if time < 60 {
            return String(format: "%.1f秒", time)
        } else {
            let mins = Int(time) / 60
            let secs = time.truncatingRemainder(dividingBy: 60)
            return String(format: "%d分%.1f秒", mins, secs)
        }
    }
    
    // 格式化日期
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 每日最佳记录
struct DailyBest: Codable, Equatable {
    let date: Date
    var beginnerBest: Double?
    var intermediateBest: Double?
    var expertBest: Double?
    
    init(date: Date = Date()) {
        self.date = Calendar.current.startOfDay(for: date)
    }
    
    func bestTime(for difficulty: Difficulty) -> Double? {
        switch difficulty {
        case .beginner: return beginnerBest
        case .intermediate: return intermediateBest
        case .expert: return expertBest
        }
    }
    
    mutating func updateBest(for difficulty: Difficulty, time: Double) {
        switch difficulty {
        case .beginner:
            if beginnerBest == nil || time < beginnerBest! {
                beginnerBest = time
            }
        case .intermediate:
            if intermediateBest == nil || time < intermediateBest! {
                intermediateBest = time
            }
        case .expert:
            if expertBest == nil || time < expertBest! {
                expertBest = time
            }
        }
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - 排行榜类型
enum LeaderboardType: String, CaseIterable {
    case today = "今日"
    case allTime = "历史"
    case recent7Days = "近7天"
}

// MARK: - 排行榜管理器
class LeaderboardManager: ObservableObject {
    static let shared = LeaderboardManager()
    
    @Published var records: [GameRecord] = []
    @Published var todayBest: DailyBest = DailyBest()
    @Published var allTimeBest: [Difficulty: Double] = [:]
    
    private let recordsKey = "MinesweeperGameRecords"
    private let todayBestKey = "MinesweeperTodayBest"
    private let maxRecords = 500  // 最多保留500条记录
    
    private init() {
        load()
        checkNewDay()
    }
    
    // MARK: - 记录新游戏
    
    func recordGame(difficulty: Difficulty, time: Double, isWin: Bool) {
        let record = GameRecord(difficulty: difficulty, time: time, isWin: isWin)
        records.insert(record, at: 0)  // 新记录放在最前面
        
        // 限制记录数量
        if records.count > maxRecords {
            records = Array(records.prefix(maxRecords))
        }
        
        if isWin {
            // 更新今日最佳
            checkNewDay()
            todayBest.updateBest(for: difficulty, time: time)
            
            // 更新历史最佳
            if allTimeBest[difficulty] == nil || time < allTimeBest[difficulty]! {
                allTimeBest[difficulty] = time
            }
        }
        
        save()
    }
    
    // MARK: - 查询方法
    
    /// 获取指定难度的今日最佳时间
    func getTodayBest(for difficulty: Difficulty) -> Double? {
        checkNewDay()
        return todayBest.bestTime(for: difficulty)
    }
    
    /// 获取指定难度的历史最佳时间
    func getAllTimeBest(for difficulty: Difficulty) -> Double? {
        return allTimeBest[difficulty]
    }
    
    /// 获取今日排行榜（胜利记录，按时间排序）
    func getTodayLeaderboard(for difficulty: Difficulty, limit: Int = 10) -> [GameRecord] {
        return records
            .filter { $0.isToday && $0.isWin && $0.difficulty == difficulty.rawValue }
            .sorted { $0.time < $1.time }
            .prefix(limit)
            .map { $0 }
    }
    
    /// 获取历史排行榜
    func getAllTimeLeaderboard(for difficulty: Difficulty, limit: Int = 10) -> [GameRecord] {
        return records
            .filter { $0.isWin && $0.difficulty == difficulty.rawValue }
            .sorted { $0.time < $1.time }
            .prefix(limit)
            .map { $0 }
    }
    
    /// 获取近7天排行榜
    func getRecentLeaderboard(for difficulty: Difficulty, days: Int = 7, limit: Int = 10) -> [GameRecord] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return records
            .filter { $0.isWin && $0.difficulty == difficulty.rawValue && $0.date >= startDate }
            .sorted { $0.time < $1.time }
            .prefix(limit)
            .map { $0 }
    }
    
    /// 判断是否打破今日记录
    func isNewTodayRecord(difficulty: Difficulty, time: Double) -> Bool {
        checkNewDay()
        guard let currentBest = todayBest.bestTime(for: difficulty) else { return true }
        return time < currentBest
    }
    
    /// 判断是否打破历史记录
    func isNewAllTimeRecord(difficulty: Difficulty, time: Double) -> Bool {
        guard let currentBest = allTimeBest[difficulty] else { return true }
        return time < currentBest
    }
    
    /// 获取今日游戏统计
    func getTodayStats(for difficulty: Difficulty) -> (played: Int, won: Int, bestTime: Double?) {
        let todayRecords = records.filter { $0.isToday && $0.difficulty == difficulty.rawValue }
        let played = todayRecords.count
        let won = todayRecords.filter { $0.isWin }.count
        let bestTime = getTodayBest(for: difficulty)
        return (played, won, bestTime)
    }
    
    // MARK: - 私有方法
    
    private func checkNewDay() {
        if !todayBest.isToday {
            todayBest = DailyBest()
        }
    }
    
    private func save() {
        // 保存记录
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: recordsKey)
        }
        
        // 保存今日最佳
        if let encoded = try? JSONEncoder().encode(todayBest) {
            UserDefaults.standard.set(encoded, forKey: todayBestKey)
        }
        
        // 保存历史最佳（转换为可编码格式）
        let allTimeBestData = Dictionary(uniqueKeysWithValues: allTimeBest.map { ($0.key.rawValue, $0.value) })
        UserDefaults.standard.set(allTimeBestData, forKey: "MinesweeperAllTimeBest")
    }
    
    private func load() {
        // 加载记录
        if let data = UserDefaults.standard.data(forKey: recordsKey),
           let decoded = try? JSONDecoder().decode([GameRecord].self, from: data) {
            records = decoded
        }
        
        // 加载今日最佳
        if let data = UserDefaults.standard.data(forKey: todayBestKey),
           let decoded = try? JSONDecoder().decode(DailyBest.self, from: data) {
            todayBest = decoded
        }
        
        // 加载历史最佳
        if let dict = UserDefaults.standard.dictionary(forKey: "MinesweeperAllTimeBest") as? [String: Double] {
            allTimeBest = Dictionary(uniqueKeysWithValues: dict.compactMap { key, value in
                guard let difficulty = Difficulty.allCases.first(where: { $0.rawValue == key }) else { return nil }
                return (difficulty, value)
            })
        }
    }
    
    /// 清除所有记录
    func clearAllRecords() {
        records = []
        todayBest = DailyBest()
        allTimeBest = [:]
        save()
    }
    
    /// 清除指定难度的记录
    func clearRecords(for difficulty: Difficulty) {
        // 删除该难度的所有记录
        records.removeAll { $0.difficulty == difficulty.rawValue }
        
        // 清除今日最佳
        switch difficulty {
        case .beginner:
            todayBest.beginnerBest = nil
        case .intermediate:
            todayBest.intermediateBest = nil
        case .expert:
            todayBest.expertBest = nil
        }
        
        // 清除历史最佳
        allTimeBest.removeValue(forKey: difficulty)
        
        save()
    }
}
