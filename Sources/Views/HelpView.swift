import SwiftUI

// MARK: - 帮助视图
struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("help.title".localized)
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
                Text("help.basicRules".localized).tag(0)
                Text("help.tips".localized).tag(1)
                Text("help.shortcuts".localized).tag(2)
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
                Button("help.close".localized) {
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
            HelpSection(title: "help.objective".localized, icon: "target") {
                Text("help.objectiveText".localized)
            }
            
            HelpSection(title: "help.minesAndNumbers".localized, icon: "number.circle") {
                VStack(alignment: .leading, spacing: 8) {
                    HelpRow(symbol: "💣", text: "help.mineDesc".localized)
                    HelpRow(symbol: "1️⃣", text: "help.numberDesc".localized)
                    HelpRow(symbol: "⬜", text: "help.emptyDesc".localized)
                }
            }
            
            HelpSection(title: "help.flagSystem".localized, icon: "flag") {
                VStack(alignment: .leading, spacing: 8) {
                    HelpRow(symbol: "🚩", text: "help.flagDesc".localized)
                    HelpRow(symbol: "❓", text: "help.questionDesc".localized)
                    Text("help.flagCycle".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            
            HelpSection(title: "help.winCondition".localized, icon: "trophy") {
                Text("help.winConditionText".localized)
            }
            
            HelpSection(title: "help.firstClick".localized, icon: "hand.tap") {
                Text("help.firstClickText".localized)
            }
        }
        .padding()
    }
    
    // MARK: - 操作技巧
    private var tipsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpSection(title: "help.quickReveal".localized, icon: "bolt") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("help.quickRevealText".localized)
                    
                    HStack(spacing: 4) {
                        Text("help.example".localized)
                            .foregroundColor(.secondary)
                        Text("help.number".localized)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                        Text("3")
                            .font(.system(.body, design: .monospaced).bold())
                            .foregroundColor(.red)
                        Text("help.quickRevealExample".localized)
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                    
                    Text("help.quickRevealWarning".localized)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            HelpSection(title: "help.autoFlag".localized, icon: "flag.badge.ellipsis") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("help.autoFlagText".localized)
                    
                    HStack(spacing: 4) {
                        Text("help.example".localized)
                            .foregroundColor(.secondary)
                        Text("help.number".localized)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                        Text("2")
                            .font(.system(.body, design: .monospaced).bold())
                            .foregroundColor(.green)
                        Text("help.autoFlagExample".localized)
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
            }
            
            HelpSection(title: "help.mouseTips".localized, icon: "computermouse") {
                VStack(alignment: .leading, spacing: 8) {
                    HelpRow(symbol: "👆", text: "help.leftClick".localized)
                    HelpRow(symbol: "👇", text: "help.rightClick".localized)
                    HelpRow(symbol: "🖲️", text: "help.middleClick".localized)
                }
            }
            
            HelpSection(title: "help.strategyTips".localized, icon: "brain") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("help.tip1".localized)
                    Text("help.tip2".localized)
                    Text("help.tip3".localized)
                    Text("help.tip4".localized)
                }
                .font(.callout)
            }
        }
        .padding()
    }
    
    // MARK: - 快捷键
    private var shortcutsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpSection(title: "help.gameControl".localized, icon: "gamecontroller") {
                VStack(spacing: 8) {
                    ShortcutRow(keys: ["⌘", "N"], description: "help.newGameShortcut".localized)
                    ShortcutRow(keys: ["Space"], description: "help.newGameShortcut".localized)
                }
            }
            
            HelpSection(title: "help.difficultySwitch".localized, icon: "slider.horizontal.3") {
                VStack(spacing: 8) {
                    ShortcutRow(keys: ["⌘", "1"], description: "help.beginnerShortcut".localized)
                    ShortcutRow(keys: ["⌘", "2"], description: "help.intermediateShortcut".localized)
                    ShortcutRow(keys: ["⌘", "3"], description: "help.expertShortcut".localized)
                }
            }
            
            HelpSection(title: "help.other".localized, icon: "ellipsis.circle") {
                VStack(spacing: 8) {
                    ShortcutRow(keys: ["⇧", "⌘", "S"], description: "help.openStats".localized)
                    ShortcutRow(keys: ["⌘", "?"], description: "help.openHelp".localized)
                    ShortcutRow(keys: ["Esc"], description: "help.closePopup".localized)
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