# dsh-liangshen 安装与机制验证记录

## 环境与版本
- 设备: Android 16 (SDK 36), aarch64（设备型号已隐去）
- DSH: 0.1.0-rc.6（满足包要求的 >= 0.1.0-rc.5）
- Node: v24.18.0（满足 ^22.19.0 || >=24.0.0）
- 安装包: @linxin666/dsh-liangshen@0.1.16（npm latest，与 GitHub main 分支 packages/dsh-liangshen 内容一致）
- 安装方式: `dsh plugin --profile web add @linxin666/dsh-liangshen`（仅此一个包，未安装 dsh-web-ui-all 或其他仓库插件）

## 备份基线
- 现有机制: `home-backup.sh`、`dsh-env-backup.sh` 均已执行
- 额外回滚快照: `/storage/emulated/0/DSH/backups/liangshen-preinstall-20260816-013813.tar.gz`
- 安装后已再次执行 `dsh-env-backup.sh`，备份了新增的 package.json / pnpm-lock.yaml / pnpm-workspace.yaml / .agent-presets

## 安装后的差异核对
- web profile package.json: 仅新增 `@linxin666/dsh-liangshen` 依赖并追加到 `dsh.profile.bundles`
- `cordis.patch.yml` 与 `node_modules/@dsh-android` 与安装前逐字节一致
- `pnpm ls --depth 0` 只显示 `@linxin666/dsh-liangshen@0.1.16`

## 实际会话证据
验证会话：
- `session-liangshen-verify-001`（新启动的 DSH web 实例，带插件 host row）
- `session-liangshen-skill-defer-001`（skills/长期指令延迟注入专项）
- `session-liangshen-on-current-001`（当前 3080 实际运行进程，未重启）

### 第一阶段（Minimal 锚定）
- 初始 `request/header`:
  - `config.maxTokens = 1024`（bootstrapMaxTokens）
  - `system = "You are a helpful software engineer assistant."`（仅 persona）
  - `tools = [bash, str_replace_editor]`
- 第一阶段进入请求的消息只有 `source.kind = user`；没有 agent-instructions / skill-catalog / runtime context。
- `session-liangshen-verify-001` 第一阶段实际调用 `bash(printf 'LIANGSHEN_ANCHOR_OK')` 成功。
- `session-liangshen-on-current-001` 在当前 3080 进程同样得到初始 header（bash/str_replace_editor, maxTokens=1024），无工具回复正常。

### 晋升与 Code Mode / PTC
- 首次工具调用后的下一份变更 header：
  - `tools = [run_code]`（仅一个 PTC 工具）
  - `config.maxTokens = 256000`（1024 封顶已剥离）
  - `system` 恢复全部 prompt section，persona 末尾包含 `Your working directory is .../liangshen-verify.`
- 实际 run_code 调用成功：
  - 底层 `read` 读取 check.txt 成功
  - 同一 run_code 程序内底层 `bash(printf PTC_BASH_OK)` 成功
- PTC SDK 声明 26 个底层工具：ask_user_question, bash, create_goal, edit, exit_plan_mode, get_goal, glob, grep, interrupt_agent, job_kill, job_list, job_output, list_agents, ralph, read, read_image, send_message, skill, str_replace_editor, subagent, subagent_fork, todo_write, update_goal, web_search, workflow, write。

### 长期指令 / workspace / skills 注入时序
`session-liangshen-skill-defer-001` 的持久事件序列：
- 第一阶段 step：仅 user 消息
- 晋升后第一步：user + `source.kind=plugin`（runtime context）；agent-instructions 和 skill-catalog 被延迟
- 晋升后第二步：`source.kind=agent-instructions`（~/.dsh/AGENTS.md）和 `source.kind=skill-catalog` 同时进入请求
- 模型在第三轮实际看到临时技能目录并回复 `PROBE_SKILL_VISIBLE`；临时技能验证后已删除。

### 已知 Android 限制（非本次安装引入）
- PTC SDK 中的 `glob` / `grep` 底层依赖 `@vscode/ripgrep`；该包按 `process.platform-process.arch` 选择二进制，但 Node on Android 为 `android-arm64`，而 npm 上不存在 `@vscode/ripgrep-android-arm64`，所以这两个搜索工具在本机必然报 `ripgrep launch failed`。
- 这是 DSH runtime 在 Android 上的既有限制；bash、read、write、edit、str_replace_editor 等核心能力不受影响。梁神模式本身安装与运行正常。

## 当前状态
- 当前 3080 进程未重启，因此 host plugin 的 announcement section 尚未挂载，但 `.agent-presets/liangshen` 已落盘并被 live discovery 发现，新建会话已可选并正常使用“梁神模式”。
- 下次完整重启 `dsh web`（或重启 DSH app）后，host plugin row 和“本机已安装 dsh-liangshen”提示 section 会一并生效。
- 旧的开发环境与工具链检查通过：node/npm/pnpm/git/make/curl/java/javac/aapt/d8/r8/apksigner 均在，JpgToPng.apk 未受影响。
