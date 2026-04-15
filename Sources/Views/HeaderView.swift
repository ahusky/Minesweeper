import SwiftUI

// MARK: - LED 数字显示器（整数）
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
                LEDDigit(char: char)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black)
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.black.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - LED 时间显示器（精确到0.1秒）
struct LEDTimeDisplay: View {
    let value: Double
    
    private var displayText: String {
        let clamped = max(0, min(999.9, value))
        return String(format: "%05.1f", clamped)  // 例如: "012.3"
    }
    
    var body: some View {
        HStack(spacing: 1) {
            ForEach(Array(displayText.enumerated()), id: \.offset) { _, char in
                if char == "." {
                    Text(".")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 1.0, green: 0.15, blue: 0.15))
                        .shadow(color: Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.5), radius: 4)
                        .frame(width: 8, height: 30)
                        .background(Color(red: 0.15, green: 0.02, blue: 0.02))
                } else {
                    LEDDigit(char: char)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black)
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.black.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - 单个 LED 数字
struct LEDDigit: View {
    let char: Character
    
    var body: some View {
        Text(String(char))
            .font(.system(size: 24, weight: .bold, design: .monospaced))
            .foregroundColor(Color(red: 1.0, green: 0.15, blue: 0.15))
            .shadow(color: Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.6), radius: 4)
            .frame(width: 17, height: 30)
            .background(Color(red: 0.15, green: 0.02, blue: 0.02))
    }
}

// MARK: - 笑脸按钮
struct FaceButton: View {
    let gameState: GameState
    let isMouseDown: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var isHovered = false
    @State private var bounceScale: CGFloat = 1.0

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
    
    private var glowColor: Color {
        switch gameState {
        case .won: return .green
        case .lost: return .red
        default: return .clear
        }
    }

    var body: some View {
        Button(action: {
            // 点击动画
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                bounceScale = 0.85
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.1)) {
                bounceScale = 1.0
            }
            action()
        }) {
            Text(faceEmoji)
                .font(.system(size: 26))
                .frame(width: 44, height: 44)
                .background(
                    ZStack {
                        // 底层阴影
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .controlColor))
                            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                        
                        // 3D 边框效果
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                LinearGradient(
                                    colors: isPressed 
                                        ? [Color.gray.opacity(0.6), Color.white.opacity(0.8)] 
                                        : [Color.white.opacity(0.9), Color.gray.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                        
                        // 游戏结束时的光晕
                        if gameState == .won || gameState == .lost {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(glowColor.opacity(0.6), lineWidth: 2)
                                .blur(radius: 4)
                        }
                    }
                )
                .scaleEffect(isPressed ? 0.9 : (isHovered ? 1.05 : bounceScale))
                .animation(.easeInOut(duration: 0.1), value: isPressed)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .help("New Game (⌘N or Space)")
        .onChange(of: gameState) { _, newState in
            // 游戏结束时弹跳动画
            if newState == .won || newState == .lost {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                    bounceScale = 1.15
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.15)) {
                    bounceScale = 1.0
                }
            }
        }
    }
}

// MARK: - 顶部信息栏
struct HeaderView: View {
    @ObservedObject var game: GameModel
    
    @State private var mineCountPulse = false
    @State private var previousMineCount: Int = 0

    var body: some View {
        HStack(spacing: 12) {
            // 剩余地雷数
            HStack(spacing: 6) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.red.opacity(0.8))
                LEDDisplay(game.remainingMines)
            }
            .scaleEffect(mineCountPulse ? 1.05 : 1.0)
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
            
            // 计时器（精确到0.1秒）
            HStack(spacing: 6) {
                LEDTimeDisplay(value: game.elapsedTime)
                Image(systemName: "clock.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.blue.opacity(0.8))
            }
            .help("Time Elapsed")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppColors.controlBackground)
                .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.3), Color.gray.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .onChange(of: game.remainingMines) { oldValue, newValue in
            // 地雷数变化时的脉冲动画
            if oldValue != newValue {
                withAnimation(.easeInOut(duration: 0.15)) {
                    mineCountPulse = true
                }
                withAnimation(.easeInOut(duration: 0.15).delay(0.15)) {
                    mineCountPulse = false
                }
            }
        }
    }
}