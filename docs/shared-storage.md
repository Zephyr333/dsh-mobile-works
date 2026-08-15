# DSH 手机环境：共享存储区

本目录 `/storage/emulated/0/DSH` 只承担 **用户可见的备份、导出、归档和最终产物**，
不作为主要开发区。

## 三层职责

| 位置 | 职责 |
|---|---|
| `files/usr`（`$PREFIX`） | APK / runtime 自己的可替换运行层，开发工具也暂存在这里；不要放个人长期内容 |
| `files/home`（`~`） | 个人长期环境：项目、开发内容、DSH 用户配置、自定义内容 |
| `/storage/emulated/0/DSH` | 共享存储备份/导出/归档区，用于容灾和给用户看的成品 |

## 当前结构

```
/storage/emulated/0/DSH/
├── backups/
│   ├── dsh-profile/          # 用户 DSH 内容备份：settings、profiles、skills、presets、agents skills
│   └── home/                 # ~/workspace 的时间戳 tar.gz 备份
├── export/
│   └── <项目>/               # 项目快照和最终产物的导出副本
├── tools/
│   ├── android-toolchain.tar # Android/Java 工具链备份（按缺失项恢复，不整体覆盖 runtime）
│   ├── dsh-env-backup.sh     # 同步 DSH profile/skills 到 backups/dsh-profile
│   ├── dsh-env-restore.sh    # 更新/重装后修复并恢复缺失内容
│   ├── home-backup.sh        # 备份 ~/workspace 到 backups/home
│   └── DEV-TOOLS.md          # 工具清单
└── README.md
```

## 个人长期内容的位置（files/home）

- 项目和小实验：`~/workspace/<项目名>`
- DSH 插件 / UI / 主题包源码：`~/workspace/dsh/packages/`
- 壁纸等素材：`~/workspace/dsh/wallpapers/`
- 个人脚本和小工具：`~/workspace/scripts/`
- DSH 配置继续用标准位置 `~/.dsh`
  - 插件依赖/补丁：`~/.dsh/profiles/<profile>/`
  - 用户 Agent preset 标准位置：`~/.dsh/.agent-presets/<preset-id>/`
  - 用户全局指令：`~/.dsh/AGENTS.md`
  - 用户 skill 标准位置：`~/.dsh/skills/`
  - 另一官方 skill 根：`~/.agents/skills/`
  - 项目级 skill：`<项目>/.dsh/skills/` 或 `<项目>/.agents/skills/`
  - 项目级指令：`<项目>/AGENTS.md`、`AGENTS.local.md` 等，随项目目录一起备份

共享存储里的 `export/` 只放项目快照与最终产物；日常开发在
`~/workspace`，需要时手动同步快照。

## 开发工具如何保留

工具仍安装在 `$PREFIX` 原位置，不搬动。当前可用：
`bash git node npm corepack pnpm java javac aapt d8 r8 apksigner make curl`。

其中手动补的 Android/Java 工具链已按文件打包到
`tools/android-toolchain.tar`（只含 JDK、aapt、d8.jar、apksigner.jar）。
恢复时按缺失项选择性解包，不会把整个旧 runtime 覆盖回新版。

## runtime 更新时可能受影响的内容和恢复方式

| 内容 | 位置 | 影响 | 恢复 |
|---|---|---|---|
| runtime 自带的 Termux 脚本/链接 | `$PREFIX/bin`、`$PREFIX/libexec`、npm/corepack 启动器 | 更新可能重置路径 | restore 脚本会重写旧路径并重建 pnpm shim |
| 手动补的 Android/Java 工具链 | `$PREFIX/lib/jvm/java-21-openjdk`、`$PREFIX/bin/aapt`、`$PREFIX/share/java/d8.jar`、`$PREFIX/share/java/apksigner.jar` | 可能丢失 | 从 `tools/android-toolchain.tar` 按缺失项解回 |
| DSH 内置 npm 包 | `$PREFIX/lib/node_modules/@deepseek-ai/dsh` | runtime 更新可能替换 | 属于 runtime 层，由更新提供新版；不整体回滚 |
| DSH 用户长期内容 | `~/.dsh/settings.yaml`、`~/.dsh/cordis.patch.yml`、`~/.dsh/AGENTS.md`、所有 `~/.dsh/profiles/*`、`~/.dsh/skills`、`~/.dsh/.agent-presets`、`~/.agents/skills` | 一般保留，重装/异常可能缺失 | 已备份到 `backups/dsh-profile`，restore 按 profile 逐个补缺失 |
| `@dsh-android/*` 适配包 | `~/.dsh/profiles/*/node_modules/@dsh-android` | profile node_modules 可能重建 | 已随各 profile 备份到 `backups/dsh-profile/profiles/<name>/android-packages` |
| 个人 workspace | `~/workspace` | App 卸载会丢失；更新一般不动 | `tools/home-backup.sh` 定期备份；restore 在 workspace 整体缺失时自动恢复最新备份 |
| 会话记录 | `~/.dsh/sessions/` | runtime 数据，不纳入备份 | 不作为开发环境恢复目标 |

## 标准恢复动作

更新后：

    sh /storage/emulated/0/DSH/tools/dsh-env-restore.sh

日常备份：

    sh /storage/emulated/0/DSH/tools/home-backup.sh
    sh /storage/emulated/0/DSH/tools/dsh-env-backup.sh

`home-backup.sh` 会保留源码、构建产物和 `.git`，只排除可重新安装的
`node_modules`。

普通 profile 的 `node_modules` 依赖同样不备份（由 `package.json` 重建）；
如果恢复后某个 profile 的依赖缺失，执行：

    dsh plugin --profile <profile名> install

如果确实需要把 `.credentials.yaml` 和 `~/.dsh/.env` 一起备份到共享存储：

    sh /storage/emulated/0/DSH/tools/dsh-env-backup.sh --with-credentials

这些文件可能包含 API key 等敏感信息，不要外传。
