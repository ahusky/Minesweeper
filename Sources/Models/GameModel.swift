import Foundation
import Combine

// MARK: - 难度等级
enum Difficulty: String, CaseIterable {
    case beginner = "初级"
    case intermediate = "中级"
    case expert = "高级"

    var rows: Int {
        switch self {
        case .beginner: return 9
        case .intermediate: return 16
        case .expert: return 16
        }
    }
    
    var cols: Int {
        switch self {
        case .beginner: return 9
        case .intermediate: return 16
        case .expert: return 30
        }
    }
    
    var mines: Int {
        switch self {
        case .beginner: return 10
        case .intermediate: return 40
        case .expert: return 99
        }
    }
}

// MARK: - 格子状态
enum CellState {
    case hidden, revealed, flagged, questioned
}

// MARK: - 游戏状态
enum GameState {
    case ready, playing, won, lost
    
    var isGameOver: Bool {
        self == .won || self == .lost
    }
    
    var isActive: Bool {
        self == .ready || self == .playing
    }
}

// MARK: - 单元格模型
struct Cell {
    let row: Int
    let col: Int
    var isMine: Bool = false
    var state: CellState = .hidden
    var adjacentMines: Int = 0
    var isExploded: Bool = false
    var isWrongFlag: Bool = false

    var isRevealed: Bool { state == .revealed }
    var isFlagged: Bool { state == .flagged }
    var isQuestioned: Bool { state == .questioned }
    var isHidden: Bool { state == .hidden }
}

// MARK: - 游戏模型
class GameModel: ObservableObject {
    // MARK: Published Properties
    @Published var cells: [[Cell]] = []
    @Published var gameState: GameState = .ready
    @Published var elapsedTime: Int = 0
    @Published var flagCount: Int = 0
    @Published var difficulty: Difficulty = .beginner
    @Published var isMouseDown: Bool = false

    // MARK: Computed Properties
    var rows: Int { difficulty.rows }
    var cols: Int { difficulty.cols }
    var totalMines: Int { difficulty.mines }
    var remainingMines: Int { totalMines - flagCount }

    // MARK: Private Properties
    private var timer: Timer?
    private var minesPlaced = false

    // MARK: - Initialization
    init(difficulty: Difficulty = .beginner) {
        self.difficulty = difficulty
        newGame()
    }
    
    deinit {
        stopTimer()
    }

    // MARK: - Public Methods
    
    func newGame() {
        stopTimer()
        gameState = .ready
        elapsedTime = 0
        flagCount = 0
        minesPlaced = false
        isMouseDown = false
        cells = (0..<rows).map { r in
            (0..<cols).map { c in Cell(row: r, col: c) }
        }
    }

    func changeDifficulty(_ newDifficulty: Difficulty) {
        difficulty = newDifficulty
        newGame()
    }

    func reveal(row: Int, col: Int) {
        guard gameState.isActive else { return }
        guard isValidPosition(row: row, col: col) else { return }
        
        let cell = cells[row][col]
        guard cell.isHidden || cell.isQuestioned else { return }
        
        // 首次点击时布雷并启动计时器
        if !minesPlaced {
            placeMines(excludeRow: row, excludeCol: col)
            startGameIfNeeded()
        }
        
        if cell.isMine {
            cells[row][col].state = .revealed
            cells[row][col].isExploded = true
            gameOver()
            return
        }
        
        floodReveal(row, col)
        checkWin()
    }

    func chordReveal(row: Int, col: Int) {
        guard gameState == .playing else { return }
        
        let cell = cells[row][col]
        guard cell.isRevealed && cell.adjacentMines > 0 else { return }
        
        let flaggedCount = neighbors(row, col).filter { cells[$0.0][$0.1].isFlagged }.count
        guard flaggedCount == cell.adjacentMines else { return }
        
        for (r, c) in neighbors(row, col) {
            if cells[r][c].isHidden || cells[r][c].isQuestioned {
                if cells[r][c].isMine {
                    cells[r][c].state = .revealed
                    cells[r][c].isExploded = true
                    gameOver()
                    return
                }
                floodReveal(r, c)
            }
        }
        checkWin()
    }

    func autoFlag(row: Int, col: Int) {
        guard gameState == .playing else { return }
        
        let cell = cells[row][col]
        guard cell.isRevealed && cell.adjacentMines > 0 else { return }
        
        let neighborCells = neighbors(row, col)
        let flaggedCount = neighborCells.filter { cells[$0.0][$0.1].isFlagged }.count
        let unresolvedCells = neighborCells.filter { cells[$0.0][$0.1].isHidden || cells[$0.0][$0.1].isQuestioned }
        
        if flaggedCount + unresolvedCells.count == cell.adjacentMines {
            for (r, c) in unresolvedCells {
                cells[r][c].state = .flagged
                flagCount += 1
            }
            checkWin()
        }
    }

    func toggleFlag(row: Int, col: Int) {
        guard gameState.isActive else { return }
        guard isValidPosition(row: row, col: col) else { return }
        
        // 首次右键点击也会启动计时器
        startGameIfNeeded()
        
        switch cells[row][col].state {
        case .hidden:
            cells[row][col].state = .flagged
            flagCount += 1
        case .flagged:
            cells[row][col].state = .questioned
            flagCount -= 1
        case .questioned:
            cells[row][col].state = .hidden
        case .revealed:
            break
        }
    }
    
    func neighbors(_ row: Int, _ col: Int) -> [(Int, Int)] {
        var result: [(Int, Int)] = []
        for dr in -1...1 {
            for dc in -1...1 {
                if dr == 0 && dc == 0 { continue }
                let r = row + dr, c = col + dc
                if isValidPosition(row: r, col: c) {
                    result.append((r, c))
                }
            }
        }
        return result
    }

    func unresolvedNeighbors(row: Int, col: Int) -> [(Int, Int)] {
        guard isValidPosition(row: row, col: col) else { return [] }
        let cell = cells[row][col]
        guard cell.isRevealed && cell.adjacentMines > 0 else { return [] }
        return neighbors(row, col).filter { cells[$0.0][$0.1].isHidden || cells[$0.0][$0.1].isQuestioned }
    }

    // MARK: - Private Methods
    
    private func isValidPosition(row: Int, col: Int) -> Bool {
        row >= 0 && row < rows && col >= 0 && col < cols
    }
    
    private func startGameIfNeeded() {
        guard gameState == .ready else { return }
        gameState = .playing
        startTimer()
    }

    private func placeMines(excludeRow: Int, excludeCol: Int) {
        var positions: [(Int, Int)] = []
        for r in 0..<rows {
            for c in 0..<cols {
                // 排除点击位置周围 3x3 区域
                if abs(r - excludeRow) <= 1 && abs(c - excludeCol) <= 1 { continue }
                positions.append((r, c))
            }
        }
        positions.shuffle()
        
        // 放置地雷
        for i in 0..<min(totalMines, positions.count) {
            cells[positions[i].0][positions[i].1].isMine = true
        }
        
        // 计算每个格子周围的地雷数
        for r in 0..<rows {
            for c in 0..<cols {
                if !cells[r][c].isMine {
                    cells[r][c].adjacentMines = countAdjacentMines(r, c)
                }
            }
        }
        minesPlaced = true
    }

    private func countAdjacentMines(_ row: Int, _ col: Int) -> Int {
        neighbors(row, col).filter { cells[$0.0][$0.1].isMine }.count
    }

    private func floodReveal(_ row: Int, _ col: Int) {
        var queue = [(row, col)]
        var visited = Set<Int>()
        
        while !queue.isEmpty {
            let (r, c) = queue.removeFirst()
            let index = r * cols + c
            
            if visited.contains(index) { continue }
            visited.insert(index)
            
            guard cells[r][c].isHidden || cells[r][c].isQuestioned else { continue }
            guard !cells[r][c].isMine else { continue }
            
            cells[r][c].state = .revealed
            
            // 如果周围没有地雷，继续扩展
            if cells[r][c].adjacentMines == 0 {
                for (nr, nc) in neighbors(r, c) {
                    if !visited.contains(nr * cols + nc) {
                        queue.append((nr, nc))
                    }
                }
            }
        }
    }

    private func gameOver() {
        gameState = .lost
        stopTimer()
        
        // 记录统计
        GameStatistics.shared.recordLoss(difficulty: difficulty, time: elapsedTime)
        
        // 显示所有地雷，标记错误的旗子
        for r in 0..<rows {
            for c in 0..<cols {
                if cells[r][c].isMine && !cells[r][c].isFlagged && !cells[r][c].isExploded {
                    cells[r][c].state = .revealed
                }
                if !cells[r][c].isMine && cells[r][c].isFlagged {
                    cells[r][c].isWrongFlag = true
                }
            }
        }
    }

    private func checkWin() {
        // 检查是否所有非地雷格子都已揭开
        for r in 0..<rows {
            for c in 0..<cols {
                if !cells[r][c].isMine && !cells[r][c].isRevealed {
                    return
                }
            }
        }
        
        gameState = .won
        stopTimer()
        
        // 记录统计
        GameStatistics.shared.recordWin(difficulty: difficulty, time: elapsedTime)
        
        // 自动标记所有未标记的地雷
        for r in 0..<rows {
            for c in 0..<cols {
                if cells[r][c].isMine && !cells[r][c].isFlagged {
                    cells[r][c].state = .flagged
                    flagCount += 1
                }
            }
        }
    }

    // MARK: - Timer Management
    
    private func startTimer() {
        guard timer == nil else { return }  // 防止重复启动
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard self.gameState == .playing, self.elapsedTime < 999 else { return }
            self.elapsedTime += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}