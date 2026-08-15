# 梁神模式（liangshen）preset：应用与研究

本目录记录「梁神模式」agent preset 在 DSH Mobile 上的安装、机制验证与日常使用。

## 机制

两阶段锚定 agent preset：

- 第一阶段只暴露官方 Minimal 的双工具（持久 bash + str_replace_editor）与一行 persona，
  清空运行时上下文，只放行用户直接消息，锚定 Minimal 推理轨迹；
- 晋升以首个 minimal-like 推理块为门控（四步兜底），无工具首轮自动晋升；
- 晋升后 wire 切换为 Code Mode（PTC，单一 run_code 工具），workspace 指令与
  skill 目录在晋升后再延迟一步注入。

## 目录内容

- `preset/` — 安装到 `~/.dsh/.agent-presets/liangshen` 的 preset 快照
  - `preset.yml` — preset 元信息
  - `agent.cordis.yml` — agent-plane 组合（改编自 DeepSeek Harness 内置 Minimal/Standard，MIT）
  - `tool-bootstrap.mjs` — 两阶段引导插件（基于 xiaobright/dsh-anchored-standard，MIT，
    含两阶段隔离扩展）
  - `NOTICE` — 上游来源与许可声明
  - `LICENSE` — 上游包 Apache-2.0 许可证文本
- `VERIFICATION.md` — 安装与机制验证记录（设备信息已脱敏）
- `skill-check.txt` — 验证阶段留下的探测标记

## 上游来源（第三方）

- npm 包：`@linxin666/dsh-liangshen`（v0.1.16，Apache-2.0）
- 仓库：https://github.com/zhu1090093659/dsh-web-ui （packages/dsh-liangshen）
- 派生许可：`agent.cordis.yml` 改编自 DeepSeek Harness 内置 preset（MIT）；
  `tool-bootstrap.mjs` 基于 https://github.com/xiaobright/dsh-anchored-standard（MIT）

preset 快照随上游 NOTICE/LICENSE 保留，仅作配置存档与学习材料。本机实际安装仍由
`dsh plugin --profile web add @linxin666/dsh-liangshen` 管理，升级插件时
preset 文件由插件自动更新。

## 验证结论摘要

见 `VERIFICATION.md`：第一阶段 Minimal 锚定、晋升与 PTC 切换、长期指令 / workspace /
skills 延迟注入均实测符合设计。已知 Android 限制：@vscode/ripgrep 没有 android-arm64
平台包，PTC 的 glob/grep 在本机不可用（非本 preset 引入）。
