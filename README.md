# dsh-mobile-works

DSH Mobile 开发连续性 / 迁移 / 重建的长期资产库。

本仓库保存这台 Android 设备上 DSH Mobile 环境的长期维护资产，用于：

- runtime 更新、换机、重装后的环境与能力恢复；
- 继续开发 DSH Mobile 插件 / preset / 脚本 / 项目时的复用起点。

不保存：运行时本体、缓存、node_modules、备份镜像、实验项目与历史研究记录、
私人数据与凭据、无法确认再分发条件的第三方内容。

## 内容

| 目录 | 内容 | 用途 |
| --- | --- | --- |
| `tools/` | dsh-env-restore.sh、dsh-env-backup.sh、home-backup.sh、DEV-TOOLS.md | 环境恢复与备份脚本、已修问题清单、无 SDK APK 构建链 |
| `config-examples/` | 实际 DSH 配置副本（home 级 patch、web profile、settings） | 迁移 / 重建时的配置基线 |
| `docs/` | 环境分层约定（dsh-environment.md）与共享存储说明（shared-storage.md） | 理解文件布局、恢复入口与备份策略 |

## 恢复入口

- 换机 / 重装 / runtime 更新后：`sh tools/dsh-env-restore.sh`
- 日常备份：`tools/home-backup.sh`（workspace）、`tools/dsh-env-backup.sh`（DSH 用户内容）
- 能力与修复知识：`tools/DEV-TOOLS.md`（工具链、Python 部署、ripgrep 修复、无 SDK APK 构建链、已修问题）

## 已验证的开发能力

- Node：node / npm / corepack / pnpm
- Android/Java：java / javac / aapt / d8 / r8 / zipalign / apksigner
  （无 Android SDK 的 APK 构建链见 `tools/DEV-TOOLS.md`）
- Python：python3 / pip3（Termux deb 手动部署，恢复方法见 `tools/DEV-TOOLS.md`）
- Git / make / curl / bash；DSH 文件搜索 tools.grep / tools.glob 已修复可用
- 不可用：clang / gcc / cmake（无需为 APK 构建补齐）

## 环境分层

三层结构（详见 `docs/`）：

- `files/usr`（$PREFIX）：APK / runtime 可替换层，不放置个人长期内容；
- `files/home`（~）：个人长期环境，主开发区 `~/workspace`；
- `/storage/emulated/0/DSH`：备份 / 导出 / 归档与最终产物（不支持 symlink）。

## 不在 GitHub 的私有恢复资产

以下资产位于本机共享存储，不宜进入公开仓库，迁移时需自行携带：

- `/storage/emulated/0/DSH/tools/android-toolchain.tar` —— Android/Java 工具链备份
  （JDK、aapt、d8.jar、apksigner.jar），restore 脚本按缺失项从中解回；
- `/storage/emulated/0/DSH/tools/python-debs/` —— Python 3.14 的 Termux deb 存档，
  restore 脚本用它重建 python3；
- `/storage/emulated/0/DSH/tools/rg-15.2.0-arm64` —— ripgrep 二进制源文件，
  restore 脚本用它重建 grep/glob 平台包；
- `/storage/emulated/0/DSH/backups/` —— 私有备份镜像，不进入本仓库。

## 许可

本仓库内容为本机自研与维护，暂未附开源许可证，保留所有权利；引用请注明出处。
