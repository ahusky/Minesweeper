import SwiftUI
import AppKit
import Combine

// MARK: - 游戏面板 NSView（CoreGraphics 绘制）
class GameBoardNSView: NSView {
    // MARK: Properties
    var game: GameModel
    var cellSize: CGFloat
    
    private var cancellable: AnyCancellable?
    private var pressedCells: Set<Int> = []

    // MARK: Static Colors
    private static let numberColors: [NSColor] = [
        .clear,                                              // 0 - unused
        NSColor(red: 0, green: 0, blue: 1, alpha: 1),       // 1 - blue
        NSColor(red: 0, green: 0.5, blue: 0, alpha: 1),     // 2 - green
        NSColor(red: 1, green: 0, blue: 0, alpha: 1),       // 3 - red
        NSColor(red: 0, green: 0, blue: 0.5, alpha: 1),     // 4 - dark blue
        NSColor(red: 0.5, green: 0, blue: 0, alpha: 1),     // 5 - maroon
        NSColor(red: 0, green: 0.5, blue: 0.5, alpha: 1),   // 6 - teal
        NSColor(red: 0, green: 0, blue: 0, alpha: 1),       // 7 - black
        NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1), // 8 - gray
    ]

    // MARK: - Initialization
    init(game: GameModel, cellSize: CGFloat) {
        self.game = game
        self.cellSize = cellSize
        super.init(frame: .zero)
        subscribeToChanges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func subscribeToChanges() {
        cancellable?.cancel()
        cancellable = game.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.needsDisplay = true
            }
    }

    // MARK: - NSView Overrides
    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    // MARK: - Helper Methods
    private func cellAt(_ event: NSEvent) -> (Int, Int)? {
        let point = convert(event.locationInWindow, from: nil)
        guard point.x >= 0 && point.y >= 0 else { return nil }
        
        let col = Int(point.x / cellSize)
        let row = Int(point.y / cellSize)
        
        guard row >= 0 && row < game.rows && col >= 0 && col < game.cols else { return nil }
        return (row, col)
    }

    private func cellId(_ row: Int, _ col: Int) -> Int {
        row * game.cols + col
    }

    private func updatePressed(_ row: Int, _ col: Int) {
        pressedCells.removeAll()
        let cell = game.cells[row][col]
        
        if cell.isRevealed && cell.adjacentMines > 0 {
            // 对于已揭开的数字格，高亮周围未解决的格子
            for (nr, nc) in game.unresolvedNeighbors(row: row, col: col) {
                pressedCells.insert(cellId(nr, nc))
            }
        } else if !cell.isRevealed && !cell.isFlagged {
            // 对于未揭开且未标记的格子，高亮当前格子
            pressedCells.insert(cellId(row, col))
        }
    }

    // MARK: - Cursor Management
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }

    override func mouseMoved(with event: NSEvent) {
        updateCursor(for: event)
    }

    override func mouseEntered(with event: NSEvent) {
        updateCursor(for: event)
    }

    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
    }

    private func updateCursor(for event: NSEvent) {
        // 游戏结束时显示默认光标
        guard game.gameState.isActive else {
            NSCursor.arrow.set()
            return
        }
        
        guard let (row, col) = cellAt(event) else {
            NSCursor.arrow.set()
            return
        }
        
        let cell = game.cells[row][col]
        
        if cell.isRevealed {
            // 已揭开的数字格如果还有未解决的邻居，显示手形光标
            if cell.adjacentMines > 0 && !game.unresolvedNeighbors(row: row, col: col).isEmpty {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        } else if cell.isFlagged {
            // 已标记的格子显示默认光标
            NSCursor.arrow.set()
        } else {
            // 未揭开且未标记的格子显示手形光标
            NSCursor.pointingHand.set()
        }
    }

    // MARK: - Mouse Events
    override func mouseDown(with event: NSEvent) {
        // 游戏结束后不再点击重开，让用户通过笑脸按钮或菜单重开
        guard game.gameState.isActive else { return }
        guard let (row, col) = cellAt(event) else { return }
        
        game.isMouseDown = true
        updatePressed(row, col)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard game.isMouseDown else { return }
        
        if let (row, col) = cellAt(event) {
            updatePressed(row, col)
        } else if !pressedCells.isEmpty {
            pressedCells.removeAll()
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        pressedCells.removeAll()
        game.isMouseDown = false
        
        guard game.gameState.isActive else {
            needsDisplay = true
            return
        }
        
        guard let (row, col) = cellAt(event) else {
            needsDisplay = true
            return
        }
        
        let cell = game.cells[row][col]
        
        if cell.isRevealed && cell.adjacentMines > 0 {
            // 对已揭开的数字格执行 chord reveal
            game.chordReveal(row: row, col: col)
            if game.gameState == .playing {
                game.autoFlag(row: row, col: col)
            }
        } else if !cell.isRevealed && !cell.isFlagged {
            // 揭开未标记的格子
            game.reveal(row: row, col: col)
        }
        
        needsDisplay = true
    }

    override func rightMouseDown(with event: NSEvent) {
        // 游戏结束后不响应右键
        guard game.gameState.isActive else { return }
        guard let (row, col) = cellAt(event) else { return }
        game.toggleFlag(row: row, col: col)
    }

    override func otherMouseDown(with event: NSEvent) {
        // 游戏结束后不响应中键
        guard game.gameState == .playing else { return }
        guard let (row, col) = cellAt(event) else { return }
        
        game.chordReveal(row: row, col: col)
        if game.gameState == .playing {
            game.autoFlag(row: row, col: col)
        }
    }

    override func menu(for event: NSEvent) -> NSMenu? { nil }

    // MARK: - Drawing
    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        
        // 背景色
        ctx.setFillColor(NSColor(white: 0.75, alpha: 1.0).cgColor)
        ctx.fill(bounds)

        // 绘制每个格子
        for row in 0..<game.rows {
            guard row < game.cells.count else { continue }
            for col in 0..<game.cols {
                guard col < game.cells[row].count else { continue }
                
                let cell = game.cells[row][col]
                let rect = CGRect(
                    x: CGFloat(col) * cellSize,
                    y: CGFloat(row) * cellSize,
                    width: cellSize,
                    height: cellSize
                )
                let isPressed = pressedCells.contains(cellId(row, col))
                drawCell(cell, in: rect, ctx: ctx, pressed: isPressed)
            }
        }
    }

    private func drawCell(_ cell: Cell, in rect: CGRect, ctx: CGContext, pressed: Bool) {
        if cell.isRevealed {
            drawRevealedCell(cell, in: rect, ctx: ctx)
        } else if cell.isWrongFlag {
            drawWrongFlagCell(in: rect, ctx: ctx)
        } else if pressed && !cell.isFlagged {
            drawPressedCell(in: rect, ctx: ctx)
        } else {
            drawHiddenCell(cell, in: rect, ctx: ctx)
        }
    }

    private func drawPressedCell(in rect: CGRect, ctx: CGContext) {
        ctx.setFillColor(NSColor(white: 0.80, alpha: 1.0).cgColor)
        ctx.fill(rect)
        ctx.setStrokeColor(NSColor(white: 0.68, alpha: 1.0).cgColor)
        ctx.setLineWidth(0.5)
        ctx.stroke(rect)
    }

    private func drawRevealedCell(_ cell: Cell, in rect: CGRect, ctx: CGContext) {
        ctx.setFillColor(NSColor(white: 0.80, alpha: 1.0).cgColor)
        ctx.fill(rect)
        ctx.setStrokeColor(NSColor(white: 0.68, alpha: 1.0).cgColor)
        ctx.setLineWidth(0.5)
        ctx.stroke(rect)
        
        if cell.isMine {
            drawMine(in: rect, ctx: ctx, exploded: cell.isExploded)
        } else if cell.adjacentMines > 0 {
            drawNumber(cell.adjacentMines, in: rect, ctx: ctx)
        }
    }

    private func drawHiddenCell(_ cell: Cell, in rect: CGRect, ctx: CGContext) {
        let borderWidth: CGFloat = 2.5
        
        // 填充背景
        ctx.setFillColor(NSColor(white: 0.75, alpha: 1.0).cgColor)
        ctx.fill(rect)
        
        // 绘制 3D 凸起效果 - 上边和左边高亮
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fill(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: borderWidth))
        ctx.fill(CGRect(x: rect.minX, y: rect.minY, width: borderWidth, height: rect.height))
        
        // 绘制 3D 凸起效果 - 下边和右边阴影
        ctx.setFillColor(NSColor(white: 0.50, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: rect.minX, y: rect.maxY - borderWidth, width: rect.width, height: borderWidth))
        ctx.fill(CGRect(x: rect.maxX - borderWidth, y: rect.minY, width: borderWidth, height: rect.height))
        
        // 绘制标记
        if cell.isFlagged {
            drawFlag(in: rect, ctx: ctx)
        } else if cell.isQuestioned {
            drawQuestion(in: rect, ctx: ctx)
        }
    }

    private func drawWrongFlagCell(in rect: CGRect, ctx: CGContext) {
        ctx.setFillColor(NSColor(white: 0.80, alpha: 1.0).cgColor)
        ctx.fill(rect)
        ctx.setStrokeColor(NSColor(white: 0.68, alpha: 1.0).cgColor)
        ctx.setLineWidth(0.5)
        ctx.stroke(rect)
        
        // 绘制地雷
        drawMineIcon(in: rect, ctx: ctx)
        
        // 绘制红色 X
        let inset = cellSize * 0.15
        ctx.setStrokeColor(NSColor.red.cgColor)
        ctx.setLineWidth(2.5)
        ctx.move(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset))
        ctx.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY - inset))
        ctx.move(to: CGPoint(x: rect.maxX - inset, y: rect.minY + inset))
        ctx.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY - inset))
        ctx.strokePath()
    }

    private func drawMine(in rect: CGRect, ctx: CGContext, exploded: Bool) {
        if exploded {
            // 爆炸的地雷背景为红色
            ctx.setFillColor(NSColor.red.cgColor)
            ctx.fill(rect)
            ctx.setStrokeColor(NSColor(white: 0.68, alpha: 1.0).cgColor)
            ctx.setLineWidth(0.5)
            ctx.stroke(rect)
        }
        drawMineIcon(in: rect, ctx: ctx)
    }

    private func drawMineIcon(in rect: CGRect, ctx: CGContext) {
        let centerX = rect.midX
        let centerY = rect.midY
        let radius = cellSize * 0.25
        
        // 绘制地雷的刺
        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.setLineWidth(2)
        for i in 0..<4 {
            let angle = Double(i) * .pi / 4
            let dx = CGFloat(cos(angle)) * radius * 1.4
            let dy = CGFloat(sin(angle)) * radius * 1.4
            ctx.move(to: CGPoint(x: centerX - dx, y: centerY - dy))
            ctx.addLine(to: CGPoint(x: centerX + dx, y: centerY + dy))
        }
        ctx.strokePath()
        
        // 绘制地雷主体
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.fillEllipse(in: CGRect(x: centerX - radius, y: centerY - radius, width: radius * 2, height: radius * 2))
        
        // 绘制高光
        let highlightRadius = radius * 0.3
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fillEllipse(in: CGRect(
            x: centerX - radius * 0.35 - highlightRadius,
            y: centerY - radius * 0.35 - highlightRadius,
            width: highlightRadius * 2,
            height: highlightRadius * 2
        ))
    }

    private func drawFlag(in rect: CGRect, ctx: CGContext) {
        let centerX = rect.midX
        let poleTop = rect.minY + cellSize * 0.18
        let poleBottom = rect.minY + cellSize * 0.75
        
        // 绘制旗杆
        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.setLineWidth(1.5)
        ctx.move(to: CGPoint(x: centerX, y: poleTop))
        ctx.addLine(to: CGPoint(x: centerX, y: poleBottom))
        ctx.strokePath()
        
        // 绘制旗帜
        ctx.setFillColor(NSColor.red.cgColor)
        ctx.move(to: CGPoint(x: centerX, y: poleTop))
        ctx.addLine(to: CGPoint(x: centerX - cellSize * 0.35, y: poleTop + cellSize * 0.18))
        ctx.addLine(to: CGPoint(x: centerX, y: poleTop + cellSize * 0.35))
        ctx.closePath()
        ctx.fillPath()
        
        // 绘制底座
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.fill(CGRect(x: centerX - cellSize * 0.25, y: poleBottom, width: cellSize * 0.5, height: 2))
        ctx.fill(CGRect(x: centerX - cellSize * 0.15, y: poleBottom - cellSize * 0.06, width: cellSize * 0.3, height: 2))
    }

    private func drawQuestion(in rect: CGRect, ctx: CGContext) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: cellSize * 0.6),
            .foregroundColor: NSColor.black
        ]
        let string = NSAttributedString(string: "?", attributes: attrs)
        let size = string.size()
        string.draw(at: CGPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2))
    }

    private func drawNumber(_ number: Int, in rect: CGRect, ctx: CGContext) {
        let color = (number >= 1 && number <= 8) ? Self.numberColors[number] : NSColor.black
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: cellSize * 0.7, weight: .bold),
            .foregroundColor: color
        ]
        let string = NSAttributedString(string: "\(number)", attributes: attrs)
        let size = string.size()
        string.draw(at: CGPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2))
    }
}

// MARK: - NSViewRepresentable 桥接
struct GameBoardNSViewWrapper: NSViewRepresentable {
    @ObservedObject var game: GameModel
    let cellSize: CGFloat
    let boardWidth: CGFloat
    let boardHeight: CGFloat

    func makeNSView(context: Context) -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: boardWidth, height: boardHeight))
        let boardView = GameBoardNSView(game: game, cellSize: cellSize)
        boardView.frame = container.bounds
        boardView.autoresizingMask = [.width, .height]
        container.addSubview(boardView)
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let boardView = nsView.subviews.first as? GameBoardNSView else { return }
        
        let gameChanged = boardView.game !== game
        boardView.game = game
        boardView.cellSize = cellSize
        
        if gameChanged {
            boardView.subscribeToChanges()
        }
        boardView.needsDisplay = true
    }
}

// MARK: - SwiftUI 包装视图
struct GameBoardView: View {
    @ObservedObject var game: GameModel
    let cellSize: CGFloat = 24

    var body: some View {
        let width = CGFloat(game.cols) * cellSize
        let height = CGFloat(game.rows) * cellSize
        
        GameBoardNSViewWrapper(
            game: game,
            cellSize: cellSize,
            boardWidth: width,
            boardHeight: height
        )
        .frame(width: width, height: height)
    }
}