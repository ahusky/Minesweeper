import SwiftUI

// MARK: - 帮助视图
struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("📖 游戏帮助")
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
            
            // 标签选择
            Picker("", selection: $selectedTab) {
                Text("基础玩法").tag(0)
                Text("操作技巧").tag(1)
                Text("快捷键").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // 内容区域
            ScrollView {
                switch selectedTab {
                case 0:
                    basicRulesView
                case 1:
                    tipsView
                case 2:
                    shortcutsView
                default:
                    EmptyView()
                }
            }
            
            Divider()
            
            // 底部按钮
            HStack {
                Spacer()
                Button("关闭") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()
        }
        .frame(width: 420, height: 520)
    }
    
    // MARK: - 基础玩法
    private var basicRulesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpSection(title: "🎯 游戏目标", icon: "target") {
                Text("找出并标记所有隐藏的地雷，同时揭开所有安全的格子。")
            }
            
            HelpSection(title: "💣 地雷与数字", icon: "number.circle") {
                VStack(alignment: .leading, spacing: 8) {
                    HelpRow(symbol: "💣", text: "地雷 - 点到就会爆炸，游戏结束")
                    HelpRow(symbol: "1️⃣", text: "数字 - 表示周围 8 格中有几个地雷")
                    HelpRow(symbol: "⬜", text: "空白 - 周围没有地雷，会自动展开")
                }
            }
            
            HelpSection(title: "🚩 标记系统", icon: "flag") {
                VStack(alignment: .leading, spacing: 8) {
                    HelpRow(symbol: "🚩", text: "旗子 - 确定是地雷时插旗标记")
                    HelpRow(symbol: "❓", text: "问号 - 不确定时可标记问号")
                    Text("右键循环切换：隐藏 → 🚩 → ❓ → 隐藏")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            
            HelpSection(title: "🏆 胜利条件", icon: "trophy") {
                Text("揭开所有不是地雷的格子即可获胜。不需要标记所有地雷，只要安全格子全部揭开就赢了！")
            }
            
            HelpSection(title: "💡 首次点击", icon: "hand.tap") {
                Text("首次点击的位置及其周围 3×3 区域保证没有地雷，让你安全开局！")
            }
        }
        .padding()
    }
    
    // MARK: - 操作技巧
    private var tipsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpSection(title: "⚡ 快速揭开", icon: "bolt") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("当一个数字周围已标记的旗子数等于该数字时，点击这个数字可以快速揭开周围所有未标记的格子。")
                    
                    HStack(spacing: 4) {
                        Text("示例：")
                            .foregroundColor(.secondary)
                        Text("数字")
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                        Text("3")
                            .font(.system(.body, design: .monospaced).bold())
                            .foregroundColor(.red)
                        Text("周围有 3 个 🚩 时，点击它会揭开剩余格子")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                    
                    Text("⚠️ 如果旗子标错了，可能会踩雷！")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            HelpSection(title: "🚩 自动插旗", icon: "flag.badge.ellipsis") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("当一个数字周围未揭开的格子数正好等于该数字时，点击这个数字会自动给这些格子插上旗子。")
                    
                    HStack(spacing: 4) {
                        Text("示例：")
                            .foregroundColor(.secondary)
                        Text("数字")
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                        Text("2")
                            .font(.system(.body, design: .monospaced).bold())
                            .foregroundColor(.green)
                        Text("周围只剩 2 个未揭开的格子 → 自动标记为 🚩")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
            }
            
            HelpSection(title: "🖱️ 鼠标技巧", icon: "computermouse") {
                VStack(alignment: .leading, spacing: 8) {
                    HelpRow(symbol: "👆", text: "左键 - 揭开格子 / 快速揭开")
                    HelpRow(symbol: "👇", text: "右键 - 循环切换标记")
                    HelpRow(symbol: "🖲️", text: "中键 - 同左键点击数字的效果")
                }
            }
            
            HelpSection(title: "🧠 推理技巧", icon: "brain") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• 从数字 1 开始分析最容易")
                    Text("• 注意角落和边缘的格子")
                    Text("• 利用已知信息相互印证")
                    Text("• 有时需要「二选一」的运气判断")
                }
                .font(.callout)
            }
        }
        .padding()
    }
    
    // MARK: - 快捷键
    private var shortcutsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpSection(title: "🎮 游戏控制", icon: "gamecontroller") {
                VStack(spacing: 8) {
                    ShortcutRow(keys: ["⌘", "N"], description: "新游戏")
                    ShortcutRow(keys: ["Space"], description: "新游戏")
                }
            }
            
            HelpSection(title: "🎚️ 难度切换", icon: "slider.horizontal.3") {
                VStack(spacing: 8) {
                    ShortcutRow(keys: ["⌘", "1"], description: "初级 (9×9, 10 雷)")
                    ShortcutRow(keys: ["⌘", "2"], description: "中级 (16×16, 40 雷)")
                    ShortcutRow(keys: ["⌘", "3"], description: "高级 (30×16, 99 雷)")
                }
            }
            
            HelpSection(title: "📊 其他", icon: "ellipsis.circle") {
                VStack(spacing: 8) {
                    ShortcutRow(keys: ["⇧", "⌘", "S"], description: "打开统计面板")
                    ShortcutRow(keys: ["⌘", "?"], description: "打开帮助")
                    ShortcutRow(keys: ["Esc"], description: "关闭弹窗")
                }
            }
        }
        .padding()
    }
}

// MARK: - 帮助区块组件
struct HelpSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        GroupBox {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
        }
    }
}

// MARK: - 帮助行组件
struct HelpRow: View {
    let symbol: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(symbol)
                .frame(width: 24)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - 快捷键行组件
struct ShortcutRow: View {
    let keys: [String]
    let description: String
    
    var body: some View {
        HStack {
            HStack(spacing: 2) {
                ForEach(Array(keys.enumerated()), id: \.offset) { index, key in
                    if index > 0 {
                        Text("+")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    Text(key)
                        .font(.system(.caption, design: .rounded).bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .frame(width: 100, alignment: .leading)
            
            Text(description)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}
