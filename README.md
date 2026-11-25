# Blow 🕯

A birthday, by candlelight. SwiftUI · iOS 17+ · iPhone (foldable-aware).

## 运行

1. 用 Xcode 16 或更新版本打开 `Blow.xcodeproj`
2. Target → Signing & Capabilities：选你的 Team，必要时改 Bundle ID（默认 `app.blow.Blow`）
3. **用真机运行**。模拟器没有麦克风吹气、陀螺仪，火焰 Metal shader 在模拟器上也可能显示异常

如果 `.xcodeproj` 打不开：`brew install xcodegen && xcodegen`，会按 `project.yml` 重新生成。

火焰是 Metal shader，命令行编译需要先装 Metal Toolchain：`xcodebuild -downloadComponent MetalToolchain`（Xcode 升级后要重装）。

## 仪式流程

| 阶段 | 发生什么 |
|---|---|
| 准备 | 名字、年龄、蛋糕文字、六款蛋糕和配套蜡烛（全部免费）、歌曲语言、唱几遍 |
| 落下 | 蜡烛依次从上方落下插进蛋糕（回弹 + 触感），然后逐根点燃 |
| 唱歌 | 合成的八音盒生日歌 + 华尔兹伴奏，歌词逐行高亮；蜡烛随歌变短 |
| 许愿 | 折叠屏：**合上手机**；普通 iPhone：**屏幕朝下扣在桌上**；或点按钮 |
| 吹蜡烛 | 麦克风检测吹气，吹得越用力灭得越多；火焰会被吹歪；兜底可用手指划过 |
| 庆祝 | 暖金色光点飘落，可生成纪念卡分享 |

## 折叠屏姿态

`CeremonyView` 按窗口尺寸判断：

- **tall**：普通 iPhone 或折叠屏外屏
- **tabletop**（大屏 + 横向）：上半屏蛋糕，下半屏歌词，中间留出折痕
- **wide**：展开放平，一个大舞台（右上角按钮在 tabletop / wide 之间切换）
- 许愿阶段从大屏变小屏 = 合上了 → 外屏显示 "Wish sealed"；再打开 → 吹蜡烛

目前 iOS 没有公开的铰链角度 API，所以半折状态靠尺寸判断 + 手动切换。Apple 若开放相关 API，只需改 `CeremonyView` 里的 `posture` 判断。

## 代码结构

```
Blow/
├─ App/          入口、主题色、缓动函数
├─ Models/       Birthday（个性化设置，存 UserDefaults）、样式、多语言歌词
├─ Audio/        生日歌乐谱、离线合成器（零音频素材）、播放器（AVAudioEngine + 混响）
├─ Sensors/      吹气检测（FFT 频谱平坦度 + 响度）、陀螺仪、触感
├─ Cake/         六款蛋糕的绘制（全部用代码画，零图片素材）、蜡烛、静态预览
├─ Ceremony/     仪式状态机（CADisplayLink 驱动）、舞台/火焰/烟、仪式界面
├─ Shaders/      Flame.metal —— 程序化火焰
├─ Setup/        设置页 + 实时蛋糕预览
├─ Card/         纪念卡（ImageRenderer → 分享）
└─ Store/        StoreKit 2 一次性买断 Blow Pro
```

## 蛋糕

六款，各有底座、桌面小物和配套蜡烛，选蛋糕时蜡烛自动跟着换（之后仍可单独改）。预览图见 `docs/cakes.png`。

| 蛋糕 | 样子 | 配套蜡烛 |
|---|---|---|
| Wildflower | 半裸蛋糕，压花、一圈野花，木桩底座 | Beeswax 蜂蜡 |
| Cherry Vintage | 粉色复古裱花、垂幔、樱桃，白瓷高脚盘 | Pearl 细长珍珠白 |
| Noir & Gold | 黑巧淋面、金箔、无花果和莓果，黑金底座 | Gilded 细长金 |
| Confetti | 彩色糖针、粉色淋面、奶油球，薄荷绿底座 | Candy Twist 彩色螺旋 |
| Starry Night | 抹刀奶油画出的星空，山坡上的牧羊人和羊群 | Stardust 金点 |
| Rose Window | 白蛋糕上的彩色玻璃窗，顶面一朵玫瑰窗，金底座 | Altar 祭坛白烛 |

- 每款是 `CakeLooks.swift` 里的一个函数，画在 `CakePainter` 提供的圆柱坐标上（`side` 侧面、`crown` 顶面）
- 调画面不用开模拟器：把 `Cake/`、`Theme.swift`、`Birthday.swift` 用 `swiftc` 编成 macOS 命令行，`ImageRenderer` 直接出 PNG
- Debug 版启动参数 `-blow.cake noir` 可直接指定蛋糕

## 配色与图标

界面像一封信：纸色做按钮和选中态，墨色写字，火漆红只用在开关这类小处和图标上。暖橙色只留给烛光。

| 颜色 | `Theme` 里的名字 | 用在哪 |
|---|---|---|
| 纸 `#F4E9D8` | `paper` | 主按钮、选中的卡片和选项边框、吹气指示条 |
| 墨 `#1B1410` | `ink` | 纸色按钮上的文字 |
| 火漆红 `#BE3048` | `wax` | 开关、付费墙的小图标、App 图标底色 |
| 烛光橙 | `ember` / `glow` | 只用于火焰和它照亮的东西，不要用在按钮上 |

图标由 `tools/AppIcon.swift` 画出（不属于 App target），改完重新生成：

```bash
swiftc -O -parse-as-library tools/AppIcon.swift -o /tmp/appicon && /tmp/appicon Blow/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```

## 需要你调的参数

- **吹气灵敏度**：`BlowDetector.analyze()` 最后三行。聚会环境吵的话调高 `loud` 的门槛
- **每根蜡烛有多难吹灭**：`CeremonyModel.init` 里的 `resistance` 范围
- **火焰形状/颜色**：`Flame.metal`，`w = 0.19 …` 控制胖瘦，`top = base + 0.70 …` 控制高度
- **歌曲速度**：`HappyBirthdayScore.bpm`
- **内购**：App Store Connect 建一个非消耗型商品，ID `app.blow.pro`。现在 Pro 只解锁其他语言的歌和纪念卡去水印，蛋糕和蜡烛全部免费。Debug 版付费墙里有 "Unlock (debug)" 按钮

## 已知限制 / V2

- 歌曲是合成的八音盒，名字不会被"唱"出来（AI 歌声在 V2）
- 非英文歌词上架前请确认版权状态
- 录音祝福、远程收集祝福、生日提醒尚未实现
- 吹气检测、陀螺仪、扣屏许愿只在模拟器上跑通了流程，灵敏度还没在真机上调过
