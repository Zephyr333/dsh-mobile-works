# dsh-mobile-works

在 DSH Mobile（Android / Termux 风格 runtime）上长期开发、配置、修复与沉淀的成果集。
本仓库把这些内容整理为可复用、可重建的公开形态；不包含运行时镜像、缓存、备份、
凭据或私人数据。

## 内容一览

| 目录 | 内容 | 说明 |
| --- | --- | --- |
| `JpgToPng/` | 完整 Android APK 项目：JPG→PNG 转换小工具 | 项目内 Android stub + `aapt + javac + d8 + zipalign + apksigner` 无 SDK 构建链，`build.sh` 已实测可重建 APK |
| `liangshen/` | 「梁神模式」agent preset 的应用与研究 | 安装后的 preset 快照（含 NOTICE/LICENSE）与两阶段锚定机制验证记录 |
| `tools/` | DSH Mobile 环境维护工具 | 恢复脚本、备份脚本、开发工具清单（Termux 路径修复、Android/Java 工具链、Python 3.14 部署等） |
| `config-examples/` | DSH 用户配置示例 | home 级 cordis patch、web profile 插件依赖与 Android 适配 patch、settings.yaml |
| `docs/` | 环境约定文档 | files/usr、files/home、共享存储三层结构与备份/恢复说明 |

## 快速入口

- 重建 JpgToPng APK：`sh JpgToPng/build.sh`（详见 `JpgToPng/README.md`）
- 手机环境恢复：`sh tools/dsh-env-restore.sh`（在手机环境内使用；见 `tools/DEV-TOOLS.md`）
- 梁神模式验证记录：`liangshen/VERIFICATION.md`

## 许可与归属

- 本仓库内的原创内容（JpgToPng 源码与构建脚本、`tools/` 脚本、`config-examples/`、
  `docs/`、`liangshen/` 验证记录）暂未附开源许可证，保留所有权利；引用请注明出处。
- `liangshen/preset/` 是第三方包 `@linxin666/dsh-liangshen@0.1.16` 的安装后快照
  （Apache-2.0）；其中 `agent.cordis.yml` 改编自 DeepSeek Harness 内置 Minimal/Standard
  preset（MIT），`tool-bootstrap.mjs` 基于
  [xiaobright/dsh-anchored-standard](https://github.com/xiaobright/dsh-anchored-standard)（MIT）。
  NOTICE 与 LICENSE 已随快照保留，详见 `liangshen/README.md`。

## 有意排除的内容

- 运行时、缓存、node_modules、构建产物、APK 与签名 keystore
- 备份镜像与大型二进制工具链（android-toolchain.tar、python debs、ripgrep 二进制）
- 凭据、API key、私人会话记录与个人设备信息
- 无法确认再分发条件的第三方源码（如 DSH Web UI 源码副本）

## 维护方式

本仓库是手机环境的公开投影：日常开发仍在本机原始位置进行，整理公开版本时再把
公开副本同步到本仓库；不在本仓库中改动正在使用的原始文件。
