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
- Android/Java：`java`、`javac`、`aapt`、`d8`、`r8`、`zipalign`、`apksigner` 均可直接使用；APK 构建按 `aapt + javac + d8 + zipalign + apksigner` 这条链处理。
- 其他基础工具：`git`、`make`、`curl`、`bash`。
- Python：`python3`、`pip3` 已验证可直接使用。
- GitHub：已配置并验证可用的 GitHub 写入能力（创建/管理仓库、GitHub API、需要远端认证的 Git 操作）；优先复用现有本地 GitHub credential，除非凭据明确失效或不可用，不要重新索取、生成或另行配置新的 token。
- DSH 文件搜索：`tools.grep`、`tools.glob` 已在当前 Mobile 环境中修复并验证可用；遇到旧记录称其不可用时，以当前环境为准。
- `clang` / `gcc` / `cmake` 目前不可用，使用前先确认，不要默认它们存在。

## 已知环境坑（避免重复踩）
- `d8 --output <目录>` 要求目录已经存在，否则报 `Invalid output`。
- runtime 更新后可能重置 `$PREFIX` 下脚本路径；先执行恢复脚本再继续开发。
- 本机是 embedded Termux runtime，不默认标准 Termux 的 `apt` / `pkg` install / upgrade / remove 生命周期可靠；需要新增 runtime 工具或依赖时，优先使用当前已验证的 Mobile 兼容获取与部署方式，除非重新验证，不要把完整 Termux 包管理当作默认能力。
- 共享存储 `/storage/emulated/0/DSH` 不支持符号链接；备份/导出用 tar 或直接复制。
- 如果 `tar -z` 报 `gzip: Cannot exec`，改用 `tar -cf - ... | gzip -c > ...`。
- 不要假设存在完整 Android SDK 或 NDK；无 SDK 的 APK 构建可用项目内最小 android stub 配合 `aapt + javac + d8 + zipalign + apksigner` 完成（构建链见 DEV-TOOLS.md）。

## 恢复与备份
- runtime 更新或环境异常后先执行：
  `sh /storage/emulated/0/DSH/tools/dsh-env-restore.sh`
- 已解决过的 Mobile 兼容问题在 runtime / DSH / 插件等相关环境更新后复发时，先查看恢复脚本与 DEV-TOOLS 文档，复用已有修复与恢复路径；旧方案仍适用时，不要从头重新调查或重新设计同一问题。
- 日常备份：
  `sh /storage/emulated/0/DSH/tools/home-backup.sh`
  `sh /storage/emulated/0/DSH/tools/dsh-env-backup.sh`
- Android/Java 工具链备份在 `/storage/emulated/0/DSH/tools/android-toolchain.tar`；恢复时只补缺失项，不要把旧 runtime 整体覆盖回新版。

## Git 回退安全网（长期原则）
- 每个新会话开始先检查当前 workspace 的 Git 状态；确定实际修改目标后，确认目标属于哪个 Git repo，以及当前工作区是否 clean。
- 修改已有文件前确保存在可回退基线：
  - 已有 Git 且当前状态 clean 时，现有 HEAD 即基线；
  - 准备修改的是正常项目/代码目录但尚无 Git 时，在合理的项目根建立本地 Git，并在实际修改前保存 baseline；
  - 不因为 workspace 根、HOME 或共享存储本身没有 Git，就给整个目录建立巨型仓库。
- DSH 动手前若存在未知的未提交修改，不得直接丢弃、覆盖、reset 或 clean；本次任务会涉及这些已有修改时，先以安全方式保护当前状态，再开始新的修改。
- 修改过程中按有意义的小阶段留下本地 Git commit，使最近几个阶段能独立回退；不要求每条命令或每次 edit 都 commit，也不为增加 commit 数量制造无意义历史。
- Git commit 默认用于本地撤销、diff 和后续会话接手，不等于 GitHub 发布；除非用户明确要求同步/发布或任务本身要求远端操作，否则不自动 push。
- 回退时优先保护已有用户状态，不默认使用可能破坏未知修改的 destructive Git 操作。
- Secret、runtime、cache、backup/archive 和普通构建产物不因这套规则进入 Git；继续遵循现有的 secret、restore、backup 和环境分层规则。

## 长期原则
- 新内容默认放 `files/home`；不要动 `files/usr`；共享存储只放备份、导出和成品。
- 不要把凭据、API key 或其他秘密写入任何备份、说明或全局指令。
- GitHub credential 属于长期 secret：不得将凭据明文持久写入仓库、git remote URL、日志、文档、普通非 secret 配置或普通备份；public 发布前检查实际待提交内容，避免泄露 secret、私人数据或不宜公开/无法确认再分发条件的第三方内容。
- 修改 DSH profile / skills / presets 后，运行 `dsh-env-backup.sh` 同步备份。
