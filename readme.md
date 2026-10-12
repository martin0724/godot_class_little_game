# class_little_game

一个使用 **Godot 4.5** 开发的游戏项目。

## 项目简介

`class_little_game` 是一个基于 Godot 引擎的游戏项目，目前处于初始化阶段。
项目采用 **GL Compatibility** 渲染后端，兼顾桌面与移动端，兼容性较好、运行门槛低。

## 技术栈

| 项目 | 说明 |
| --- | --- |
| 引擎 | [Godot 4.5](https://godotengine.org/) |
| 渲染后端 | GL Compatibility（桌面 / 移动端一致） |
| 脚本语言 | GDScript（默认） |
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
├── .godot/              # Godot 引擎缓存与导入数据（已被 .gitignore 忽略）
├── .editorconfig        # 编辑器编码约定（UTF-8）
├── .gitattributes       # Git 文本换行符规范化（LF）
├── .gitignore           # Git 忽略规则
├── icon.svg             # 项目图标
├── icon.svg.import      # Godot 生成的图标导入配置
├── project.godot        # 项目配置文件（引擎参数、主场景等）
└── readme.md            # 项目说明文档（本文件）
```

## 开发约定

- **编码**：所有文件统一使用 **UTF-8** 编码（见 `.editorconfig`）。
- **换行符**：统一使用 **LF**（见 `.gitattributes`，`* text=auto eol=lf`）。
- **缓存**：`.godot/` 与 `android/` 目录不纳入版本控制，克隆后由 Godot 自动重新生成。
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
