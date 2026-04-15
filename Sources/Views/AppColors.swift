import SwiftUI
import AppKit

// MARK: - 应用颜色定义
enum AppColors {
    /// 窗口背景色 - 自适应深浅模式
    /// 浅色模式: 暖灰色 (避免纯白)
    /// 深色模式: 深灰色 (避免纯黑)
    static var windowBackground: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                // 深色模式: #2D2D2D (深灰，不是纯黑)
                return NSColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1.0)
            } else {
                // 浅色模式: #F0F0F0 (暖灰，不是纯白)
                return NSColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1.0)
            }
        })
    }
    
    /// 面板背景色 - 用于弹窗等
    static var panelBackground: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                // 深色模式: 稍浅的深灰
                return NSColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1.0)
            } else {
                // 浅色模式: 稍深的浅灰
                return NSColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
            }
        })
    }
    
    /// 控件背景色
    static var controlBackground: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1.0)
            } else {
                return NSColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1.0)
            }
        })
    }
}