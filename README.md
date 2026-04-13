# 💣 扫雷 (Minesweeper)

<p align="center">
  <img src="ScreenShot.png" alt="Minesweeper" width="404" height="546">
</p>

经典的 Windows 扫雷游戏 macOS 复刻版，使用 SwiftUI + AppKit 开发。

## ✨ 功能特性

### 🎮 游戏玩法
- ✅ 三种难度等级
  - **初级**：9×9 格，10 个雷
  - **中级**：16×16 格，40 个雷
  - **高级**：30×16 格，99 个雷
- ✅ 左键点击揭开格子
- ✅ 右键点击插旗 → 问号 → 取消
- ✅ 单击数字快速揭开 / 自动插旗
- ✅ 首次点击不会踩雷（3×3 安全区域）
- ✅ 空白区域自动展开（BFS）
- ✅ 游戏失败区分踩雷 / 错误标旗

### 📊 数据统计
- ✅ 游戏次数统计（总局数 / 胜利 / 失败）
- ✅ 胜率自动计算
- ✅ 最快通关时间 🏆
- ✅ 平均通关时间
- ✅ 连胜 / 连败记录 🔥
- ✅ 分难度独立统计
- ✅ 数据自动保存（重启保留）

### 🎨 界面体验
- ✅ 经典 Windows 扫雷视觉风格
- ✅ LED 数字显示剩余雷数和计时器
- ✅ 笑脸按钮重新开始 + 表情联动
- ✅ 难度按钮显示最佳时间
- ✅ 胜利 / 失败边框高亮提示

## 🕹️ 操作方式

| 操作 | 功能 |
|------|------|
| **左键单击** | 揭开格子 |
| **右键单击** | 插旗 → 问号 → 取消（循环） |
| **单击数字** | 快速揭开周围 / 自动插旗 |
| **中键单击** | 同单击数字 |
| **笑脸按钮** | 重新开始当前难度 |
| **📊 图标** | 打开统计面板 |

## ⌨️ 快捷键

| 快捷键 | 功能 |
|--------|------|
| `⌘N` | 新游戏 |
| `Space` | 新游戏 |
| `⌘1` | 初级难度 |
| `⌘2` | 中级难度 |
| `⌘3` | 高级难度 |
| `⇧⌘S` | 打开统计面板 |

## 🔨 编译运行

```bash
# 克隆项目
git clone https://github.com/ahusky/Minesweeper.git
cd Minesweeper

# 编译并运行
./build.sh
open build/Minesweeper.app
```

## 💻 系统要求

- macOS 14.0+
- Swift 5.9+

## 📁 项目结构

```
Minesweeper/
├── Sources/
│   ├── App/
│   │   └── MinesweeperApp.swift      # App 入口、菜单栏、主视图布局
│   ├── Models/
│   │   ├── GameModel.swift           # 游戏逻辑模型
│   │   └── GameStatistics.swift      # 数据统计与持久化
│   └── Views/
│       ├── GameBoardView.swift       # 游戏面板（NSView 绘制 + 鼠标事件）
│       ├── HeaderView.swift          # 顶部信息栏（LED 显示器 + 笑脸按钮）
│       └── StatisticsView.swift      # 统计数据展示面板
├── Resources/
│   └── logo.png                      # 应用图标原图
├── build/                            # 构建产物（.app bundle）
├── build.sh                          # 编译脚本
└── README.md
```

## 📜 许可证

MIT License