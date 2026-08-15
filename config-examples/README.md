# DSH 配置示例

从本机 DSH Mobile 环境复制的公开配置示例（不含任何凭据）。

- `home-cordis.patch.yml` — `~/.dsh/cordis.patch.yml`：启用用户全局指令 ~/.dsh/AGENTS.md
- `settings.yaml` — `~/.dsh/settings.yaml`：默认模型、默认 preset、权限预设等
- `profile-web/package.json` — web profile 的插件依赖与 bundles
- `profile-web/cordis.patch.yml` — web profile 的 Android 适配 patch：
  @dsh-android/dsh-shell-termux 提供 bash 能力 seam，@dsh-android/dsh-client-ui-responsive
  提供响应式 UI（M1.1 形态，替代早期临时 patch）
- `profile-web/pnpm-workspace.yaml` — 依赖发布年龄豁免

注意：路径按本机包名（com.dshmobile.shell）书写；换包名 / 换设备需按实际
`$PREFIX` 调整。实际生效配置仍在手机 `~/.dsh` 内，本目录只是公开示例副本。
