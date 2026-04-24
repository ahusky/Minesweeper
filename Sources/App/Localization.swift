import Foundation

// MARK: - Localization Helper
extension String {
    /// 获取本地化字符串
    var localized: String {
        Bundle.main.localizedString(forKey: self, value: nil, table: nil)
    }
    
    /// 获取带参数的本地化字符串
    func localized(_ args: CVarArg...) -> String {
        String(format: Bundle.main.localizedString(forKey: self, value: nil, table: nil), arguments: args)
    }
}

// MARK: - Localization Keys
enum L10n {
    // App
    enum App {
        static let name = "app.name".localized
        static let help = "app.help".localized
    }
    
    // Menu
    enum Menu {
        static let game = "menu.game".localized
        static let newGame = "menu.newGame".localized
        static let statisticsCenter = "menu.statisticsCenter".localized
        static let mines = "menu.mines".localized
    }
    
    // Difficulty
    enum Difficulty {
        static let beginner = "difficulty.beginner".localized
        static let intermediate = "difficulty.intermediate".localized
        static let expert = "difficulty.expert".localized
        
        static func name(for difficulty: MinesweeperDifficulty) -> String {
            switch difficulty {
            case .beginner: return beginner
            case .intermediate: return intermediate
            case .expert: return expert
            }
        }
    }
    
    // Window Title
    enum Title {
        static func ready(_ difficulty: String) -> String {
            "title.ready".localized(difficulty)
        }
        static let playing = "title.playing".localized
        static func won(_ time: String) -> String {
            "title.won".localized(time)
        }
        static func wonRecord(_ time: String) -> String {
            "title.wonRecord".localized(time)
        }
        static func wonToday(_ time: String) -> String {
            "title.wonToday".localized(time)
        }
        static let lost = "title.lost".localized
    }
    
    // Stats Center
    enum Stats {
        static let title = "stats.title".localized
        static let overview = "stats.overview".localized
        static let leaderboard = "stats.leaderboard".localized
        static let details = "stats.details".localized
        static let resetData = "stats.resetData".localized
        static let done = "stats.done".localized
        static let confirmReset = "stats.confirmReset".localized
        static let cancel = "stats.cancel".localized
        static let reset = "stats.reset".localized
        static func resetMessage(_ difficulty: String) -> String {
            "stats.resetMessage".localized(difficulty)
        }
        
        static let timeRecords = "stats.timeRecords".localized
        static let todayBest = "stats.todayBest".localized
        static let allTimeBest = "stats.allTimeBest".localized
        static let averageTime = "stats.averageTime".localized
        static let seconds = "stats.seconds".localized
        
        static let battleStats = "stats.battleStats".localized
        static let todayRecord = "stats.todayRecord".localized
        static let totalRecord = "stats.totalRecord".localized
        static let winRate = "stats.winRate".localized
        
        static let streakRecords = "stats.streakRecords".localized
        static let currentStreak = "stats.currentStreak".localized
        static let longestWinStreak = "stats.longestWinStreak".localized
        static let longestLoseStreak = "stats.longestLoseStreak".localized
    }
    
    // Leaderboard
    enum Leaderboard {
        static let today = "leaderboard.today".localized
        static let allTime = "leaderboard.allTime".localized
        static let recent7Days = "leaderboard.recent7Days".localized
        static let todayRanking = "leaderboard.todayRanking".localized
        static let allTimeRanking = "leaderboard.allTimeRanking".localized
        static let recent7DaysRanking = "leaderboard.recent7DaysRanking".localized
        static func records(_ count: Int) -> String {
            "leaderboard.records".localized(count)
        }
        static let noRecords = "leaderboard.noRecords".localized
        static let noRecordsHint = "leaderboard.noRecordsHint".localized
        static let rank1 = "leaderboard.rank1".localized
        static let rank2 = "leaderboard.rank2".localized
        static let rank3 = "leaderboard.rank3".localized
    }
    
    // Details
    enum Details {
        static let totalGames = "details.totalGames".localized
        static let wins = "details.wins".localized
        static let losses = "details.losses".localized
        static let fastest = "details.fastest".localized
        static let average = "details.average".localized
        static let currentWinStreak = "details.currentWinStreak".localized
        static let bestWinStreak = "details.bestWinStreak".localized
        static let worstLoseStreak = "details.worstLoseStreak".localized
        static let allDifficulties = "details.allDifficulties".localized
        static let totalWins = "details.totalWins".localized
        static let overallWinRate = "details.overallWinRate".localized
    }
    
    // Celebration
    enum Celebration {
        static let newRecord = "celebration.newRecord".localized
        static let todayBest = "celebration.todayBest".localized
        static let newRecordSubtitle = "celebration.newRecordSubtitle".localized
        static let todayBestSubtitle = "celebration.todayBestSubtitle".localized
    }
    
    // Help
    enum Help {
        static let title = "help.title".localized
        static let basicRules = "help.basicRules".localized
        static let tips = "help.tips".localized
        static let shortcuts = "help.shortcuts".localized
        static let close = "help.close".localized
        
        static let objective = "help.objective".localized
        static let objectiveText = "help.objectiveText".localized
        static let minesAndNumbers = "help.minesAndNumbers".localized
        static let mineDesc = "help.mineDesc".localized
        static let numberDesc = "help.numberDesc".localized
        static let emptyDesc = "help.emptyDesc".localized
        static let flagSystem = "help.flagSystem".localized
        static let flagDesc = "help.flagDesc".localized
        static let questionDesc = "help.questionDesc".localized
        static let flagCycle = "help.flagCycle".localized
        static let winCondition = "help.winCondition".localized
        static let winConditionText = "help.winConditionText".localized
        static let firstClick = "help.firstClick".localized
        static let firstClickText = "help.firstClickText".localized
        
        static let quickReveal = "help.quickReveal".localized
        static let quickRevealText = "help.quickRevealText".localized
        static let example = "help.example".localized
        static let number = "help.number".localized
        static let quickRevealExample = "help.quickRevealExample".localized
        static let quickRevealWarning = "help.quickRevealWarning".localized
        static let autoFlag = "help.autoFlag".localized
        static let autoFlagText = "help.autoFlagText".localized
        static let autoFlagExample = "help.autoFlagExample".localized
        static let mouseTips = "help.mouseTips".localized
        static let leftClick = "help.leftClick".localized
        static let rightClick = "help.rightClick".localized
        static let middleClick = "help.middleClick".localized
        static let strategyTips = "help.strategyTips".localized
        static let tip1 = "help.tip1".localized
        static let tip2 = "help.tip2".localized
        static let tip3 = "help.tip3".localized
        static let tip4 = "help.tip4".localized
        
        static let gameControl = "help.gameControl".localized
        static let newGameShortcut = "help.newGameShortcut".localized
        static let difficultySwitch = "help.difficultySwitch".localized
        static let beginnerShortcut = "help.beginnerShortcut".localized
        static let intermediateShortcut = "help.intermediateShortcut".localized
        static let expertShortcut = "help.expertShortcut".localized
        static let other = "help.other".localized
        static let openStats = "help.openStats".localized
        static let openHelp = "help.openHelp".localized
        static let closePopup = "help.closePopup".localized
    }
    
    // Toolbar
    enum Toolbar {
        static let help = "toolbar.help".localized
        static let statistics = "toolbar.statistics".localized
    }
}

// Type alias for clarity
typealias MinesweeperDifficulty = Difficulty
