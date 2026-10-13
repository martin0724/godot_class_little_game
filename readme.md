# class_little_game

一个使用 **Godot 4.5** 开发的游戏项目。

## 项目简介

**潜艇大作战 / Submarine Race** —— 一个直播互动、休闲竞技的派对小游戏，使用 **Godot 4.5** 开发。

观众通过发送弹幕/礼物（对应“加分 / 减分”操作）控制各自的潜水艇向上浮升，最先到达水面（第 20 格）的潜水艇获胜。
项目采用 **GL Compatibility** 渲染后端，兼顾桌面与移动端，兼容性较好、运行门槛低。

## 游戏玩法

- **垂直赛道**：画面自上而下分为蓝天/水面与深海，中间为 20 格垂直网格，水平方向排列 8 条航道。
- **初始状态**：所有潜水艇位于水底（第 0 格），分数为 0。
- **得分与上浮**：每获得 1 分向上浮 1 格；被扣分则下沉 1 格，最低沉至第 0 格（不会为负）。
- **胜利条件**：任意潜水艇到达第 20 格（水面 FINISH 线）即获胜，该潜水艇锁定并停止接受加减分。
- **操作板**：画面底部为每艘潜水艇的独立面板，包含头像色块、玩家名称、实时分数（如 `5/20`）以及 `+` / `-` 按钮。
- **反馈特效**：上浮时喷出水泡粒子并播放上滑音效；得分时数字跳动、艇身闪烁；获胜时艇身闪烁金光、播放小号音效并弹出胜利结算面板（含“再来一局”）。
- **头顶宠物**：每艘潜艇头顶装饰一只卡通宠物（企鹅 / 外星人 / 章鱼 / 螃蟹 / 小鱼 / 海星 / 水母 / 小猫），随潜艇一起浮动摇摆。
- **音效**：全部由代码实时合成（无需音频素材），区分点击、加分、扣分、边界无效与获胜五种。
- **静音开关**：画面**右上角**为全局音效开关（默认开启）。开启静音时按钮变红，状态会写入存档，重启后仍然生效。
- **重置存档**：右上角「重置存档」按钮会弹出确认框；确认后清空全部存档数据（名称/分数/胜场）并把配置恢复默认，随后重建场景。取消则不做任何改变。
- **修改玩家名**：点击底部面板中的玩家名称即可直接编辑（回车或点击别处生效），名称会同步显示在获胜结算面板中，并立即保存到存档。
- **数据持久化**：玩家名称、当前分数、累计胜场与对局数均保存到 `user://save_data.json`（普通 JSON 文件，无第三方依赖）。重启游戏会恢复名称与分数；若上一局已分出胜负，则自动开新一局。面板上会显示「胜N」徽标。
- **再来一局**：原地重置分数与位置并恢复按钮，**保留玩家名称、胜场与静音设置**（不重载场景）。

## 技术栈

| 项目 | 说明 |
| --- | --- |
| 引擎 | [Godot 4.5](https://godotengine.org/) |
| 渲染后端 | GL Compatibility（桌面 / 移动端一致） |
| 脚本语言 | GDScript |
| 设计分辨率 | 1280 × 800（`canvas_items` 拉伸，保持宽高比） |
| 版本控制 | Git |

## 环境要求

- **Godot Engine 4.5**（标准版，非 .NET / Mono 版）
  下载地址：https://godotengine.org/download
- Git

> 建议使用与项目 `config/features` 中声明的 **4.5** 保持一致的主版本，
> 避免因引擎版本差异导致的资源或脚本兼容问题。

## 快速开始

### 1. 克隆仓库

```bash
git clone git@github.com:martin0724/godot_class_little_game.git
cd godot_class_little_game
```

### 2. 打开项目

- **方式一（推荐）**：打开 Godot，点击 `导入 (Import)`，选择项目根目录下的 `project.godot` 文件，然后点击 `导入并编辑`。
- **方式二**：命令行直接打开：

```bash
godot --path . --editor
```

### 3. 运行项目

在 Godot 编辑器中按 `F5` 运行，或使用命令行：

```bash
godot --path .
```

## 目录结构

```
class-little-game/
├── .godot/                  # Godot 引擎缓存与导入数据（已被 .gitignore 忽略）
├── docs/
│   └── 游戏玩法说明.txt      # 游戏策划案
├── scenes/
│   └── main.tscn            # 主场景（根节点 Control，挂载 scripts/game.gd）
├── scripts/
│   ├── game.gd              # 主控制器：搭建赛道/潜艇/操作板，处理加减分与胜负
│   ├── submarine.gd         # 潜水艇（矢量绘制、上浮动画、粒子/闪烁特效、挂载宠物）
│   ├── pet.gd               # 头顶宠物装饰（8 种矢量造型）
│   ├── control_panel.gd     # 底部操作面板（头像、名称、分数、+/- 按钮）
│   ├── bubbles.gd           # 轻量级水泡粒子效果
│   ├── data_store.gd         # 数据持久化（自动加载单例 DataStore，JSON 存档）
│   └── sound_manager.gd     # 音效管理器（自动加载单例 SoundManager，合成音效 + 全局静音）
├── theme/
│   └── ui_font.tres         # 系统字体（SystemFont），用于正常显示中文
├── .editorconfig            # 编辑器编码约定（UTF-8）
├── .gitattributes           # Git 文本换行符规范化（LF）
├── .gitignore               # Git 忽略规则
├── icon.svg                 # 项目图标
├── project.godot            # 项目配置文件（引擎参数、主场景等）
└── readme.md                # 项目说明文档（本文件）
```

## 数据存储

存档为普通 JSON 文件，位于 `user://save_data.json`（Windows 下即
`%APPDATA%/Godot/app_userdata/class_little_game/save_data.json`），**不依赖任何第三方插件**。

```
{
  "version": 1,
  "players": [
    { "name": "玩家1", "score": 0, "wins": 0 },
    ... 共 8 名玩家 ...
  ],
  "matches_played": 0,
  "last_winner": -1,
  "settings": { "muted": false }
}
```

- 由自动加载单例 `DataStore`（`scripts/data_store.gd`）统一读写，对外提供
  `get_player_name()` / `set_player_name()` / `get_player_score()` / `set_player_score()` /
  `get_player_wins()` / `record_win()` / `reset_scores()` / `get_setting()` / `set_setting()` 等接口。
- **容错**：加载时会逐字段校验并回退默认值；文件缺失或内容损坏时自动使用默认数据，不会崩溃。
- **惰性加载**：首次访问才读取磁盘，避免自动加载初始化顺序影响结果。
- **重置入口**：右上角「重置存档」按钮 → 确认框 → `DataStore.reset_all()` + `SoundManager.reload_settings()` + 重建场景，一键恢复出厂状态。

## 开发约定

- **编码**：所有文件统一使用 **UTF-8** 编码（见 `.editorconfig`）。
- **换行符**：统一使用 **LF**（见 `.gitattributes`，`* text=auto eol=lf`）。
- **缓存**：`.godot/` 与 `android/` 目录不纳入版本控制，克隆后由 Godot 自动重新生成。
- **字体**：默认 UI 字体由 `theme/ui_font.tres`（SystemFont）提供，以保证中文正常显示。
- **美术**：潜水艇、宠物与背景均由代码矢量绘制，不依赖贴图资源。
- **音效**：由 `sound_manager.gd` 在运行时合成波形（`AudioStreamWAV`），不依赖音频文件；
  该脚本以自动加载（autoload）单例 `SoundManager` 形式注册，可直接全局调用。
  全局静音通过 `AudioServer.set_bus_mute()` 作用于 Master 总线。
- **用户设置**：静音开关与玩家数据统一保存在 `user://save_data.json`（位于系统用户数据目录，不在项目内）。
- **编辑器优先**：`project.godot` 建议通过 Godot 编辑器界面修改，而非手动编辑。

## 提交规范（建议）

- 提交信息简洁明了，说明本次改动的目的。
- 例如：`feat: 添加角色移动脚本`、`fix: 修复跳跃穿墙问题`、`docs: 更新 readme`。

## 相关链接

- 仓库地址：https://github.com/martin0724/godot_class_little_game
- Godot 官方文档：https://docs.godotengine.org/
- Godot 中文文档：https://docs.godotengine.org/zh-cn/4.x/

## 许可证

本项目暂未指定开源许可证。如需对外发布，请补充 `LICENSE` 文件。
