# 本机 DSH 长期基础约定

## 环境分层（长期有效）
- `files/usr` 是 APK / runtime 可替换层，开发工具也在这里；不要把个人长期内容放进去，也不要随意搬动其中工具。
- `files/home` 是个人长期环境，主要开发区是 `~/workspace`。
- `/storage/emulated/0/DSH` 只用于备份、导出、归档和最终产物；它不支持 symlink，不适合作为主开发区。

## 主要位置
- 项目和小实验：`~/workspace/<项目名>`
- DSH 插件 / UI / 主题包源码：`~/workspace/dsh/packages/`
- 壁纸等素材：`~/workspace/dsh/wallpapers/`
- 个人脚本：`~/workspace/scripts/`
- DSH 用户扩展标准位置：profiles 在 `~/.dsh/profiles/`；用户 Agent preset 在 `~/.dsh/.agent-presets/`；用户 skill 在 `~/.dsh/skills/` 或 `~/.agents/skills/`；插件用 `dsh plugin --profile <name> add <本地路径或包名>` 接入。
- 当前 APK 实际使用 `web` profile；普通会话主要围绕 `~/workspace`。
- DSH 已注册 workspace：`~/workspace`（主开发）和 `/storage/emulated/0/DSH`（备份导出）。

## 已确认可用的开发链
- Node 生态：`node`、`npm`、`corepack`、`pnpm` 均可直接使用。
- Android/Java：`java`、`javac`、`aapt`、`d8`、`r8`、`apksigner` 均可直接使用；APK 构建按 `aapt + javac + d8 + apksigner` 这条链处理。
- 其他基础工具：`git`、`make`、`curl`、`bash`。
- Python：`python3`、`pip3` 已验证可直接使用。
- GitHub：已配置并验证可用的 GitHub 写入能力（创建/管理仓库、GitHub API、需要远端认证的 Git 操作）；优先复用现有本地 GitHub credential，除非凭据明确失效或不可用，不要重新索取、生成或另行配置新的 token。
- `clang` / `gcc` / `cmake` 目前不可用，使用前先确认，不要默认它们存在。

## 已知环境坑（避免重复踩）
- `d8 --output <目录>` 要求目录已经存在，否则报 `Invalid output`。
- runtime 更新后可能重置 `$PREFIX` 下脚本路径；先执行恢复脚本再继续开发。
- 本机是 embedded Termux runtime，不默认标准 Termux 的 `apt` / `pkg` install / upgrade / remove 生命周期可靠；需要新增 runtime 工具或依赖时，优先使用当前已验证的 Mobile 兼容获取与部署方式，除非重新验证，不要把完整 Termux 包管理当作默认能力。
- 共享存储 `/storage/emulated/0/DSH` 不支持符号链接；备份/导出用 tar 或直接复制。
- 如果 `tar -z` 报 `gzip: Cannot exec`，改用 `tar -cf - ... | gzip -c > ...`。
- 不要假设存在完整 Android SDK 或 NDK；当前 APK 构建使用项目内 stub 和上述工具。

## 恢复与备份
- runtime 更新或环境异常后先执行：
  `sh /storage/emulated/0/DSH/tools/dsh-env-restore.sh`
- 已解决过的 Mobile 兼容问题在 runtime / DSH / 插件等相关环境更新后复发时，先查看恢复脚本与 DEV-TOOLS 文档，复用已有修复与恢复路径；旧方案仍适用时，不要从头重新调查或重新设计同一问题。
- 日常备份：
  `sh /storage/emulated/0/DSH/tools/home-backup.sh`
  `sh /storage/emulated/0/DSH/tools/dsh-env-backup.sh`
- Android/Java 工具链备份在 `/storage/emulated/0/DSH/tools/android-toolchain.tar`；恢复时只补缺失项，不要把旧 runtime 整体覆盖回新版。

## 长期原则
- 新内容默认放 `files/home`；不要动 `files/usr`；共享存储只放备份、导出和成品。
- 不要把凭据、API key 或其他秘密写入任何备份、说明或全局指令。
- GitHub credential 属于长期 secret：不得将凭据明文持久写入仓库、git remote URL、日志、文档、普通非 secret 配置或普通备份；public 发布前检查实际待提交内容，避免泄露 secret、私人数据或不宜公开/无法确认再分发条件的第三方内容。
- 修改 DSH profile / skills / presets 后，运行 `dsh-env-backup.sh` 同步备份。
