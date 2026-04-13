import SwiftUI

// MARK: - LED 数字显示器
struct LEDDisplay: View {
    let value: Int
    let digits: Int

    init(_ value: Int, digits: Int = 3) {
        self.value = value
        self.digits = digits
    }

    private var displayText: String {
        let clamped = max(-99, min(999, value))
        if clamped < 0 {
            return "-" + String(format: "%0\(digits - 1)d", abs(clamped))
        } else {
            return String(format: "%0\(digits)d", clamped)
        }
    }

    var body: some View {
        HStack(spacing: 1) {
            ForEach(Array(displayText.suffix(digits).enumerated()), id: \.offset) { _, char in
                Text(String(char))
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 1.0, green: 0.15, blue: 0.15))
                    .frame(width: 17, height: 30)
                    .background(Color(red: 0.2, green: 0.02, blue: 0.02))
            }
        }
        .padding(3)
        .background(Color.black)
        .cornerRadius(2)
    }
}

// MARK: - 笑脸按钮
struct FaceButton: View {
    let gameState: GameState
    let isMouseDown: Bool
    let action: () -> Void
    
    @State private var isPressed = false

    private var faceEmoji: String {
        if isPressed {
            return "😮"
        }
        switch gameState {
        case .ready:
            return "🙂"
        case .playing:
            return isMouseDown ? "😮" : "🙂"
        case .won:
            return "😎"
        case .lost:
            return "😵"
        }
    }

    var body: some View {
        Text(faceEmoji)
            .font(.system(size: 24))
            .frame(width: 40, height: 40)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(nsColor: .controlColor))
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(
                            LinearGradient(
                                colors: isPressed ? [Color.gray, Color.white] : [Color.white, Color.gray],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                }
            )
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.08), value: isPressed)
            .onTapGesture {
                action()
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
            .help("New Game (⌘N or Space)")
    }
}

// MARK: - 顶部信息栏
struct HeaderView: View {
    @ObservedObject var game: GameModel

    var body: some View {
        HStack {
            // 剩余地雷数
            LEDDisplay(game.remainingMines)
                .help("Remaining Mines")
            
            Spacer()
            
            // 笑脸按钮
            FaceButton(
                gameState: game.gameState,
                isMouseDown: game.isMouseDown
            ) {
                game.newGame()
            }
            
            Spacer()
            
            // 计时器
            LEDDisplay(game.elapsedTime)
                .help("Time Elapsed")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            ZStack {
                Color(nsColor: .controlColor)
                Rectangle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color(white: 0.45), Color.white],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
        )
    }
}