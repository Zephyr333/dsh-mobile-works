# 开发工具清单与恢复说明

更新时间：整理环境时实测。

## 工具根目录

`PREFIX = /data/user/0/com.dshmobile.shell/files/usr`

这个目录是 Termux 风格的运行时前缀，也是 DSH App 的 shell 环境根。
当前 App 包名对应路径里的 `com.dshmobile.shell`；如果换包名/换设备，路径会变，
恢复脚本优先读环境变量 `TERMUX__PREFIX`，否则使用上述默认值。

## 当前可用工具（留在原处，不搬动）

| 工具 | 实测版本 | 说明 |
|---|---|---|
| bash | 当前 `$PREFIX/bin/bash` | DSH shell 运行时 |
| git | 2.55.0 | 版本管理 |
| node | v24.18.0 | JS 运行时 |
| npm | 11.19.0 | Node 包管理 |
| corepack | 0.35.0 | 已启用 pnpm shim |
| pnpm | 11.21.0 | `dsh plugin` 依赖它，已补好 |
| java / javac | OpenJDK 21.0.12 | Android/Java 编译 |
| aapt | v0.2-android-16.0.0_r4 | Android 资源打包 |
| d8 / r8 | 9.2.4-dev | dex 编译 |
| apksigner | 0.9 | APK 签名 |
| make | 4.4.1 | 构建辅助 |
| curl | 8.12.1 | 网络调试 |
| python3 | 3.14.6 | Python 解释器（Termux deb 手动部署，见下文） |
| pip3 | 26.2.1 | Python 包安装（纯 Python wheel 已验证可用） |

Java 实际位置：
`$PREFIX/lib/jvm/java-21-openjdk/bin/java`（`$PREFIX/bin/java` 是指向它的链接）。

Android 工具 jar：
`$PREFIX/share/java/d8.jar`、`$PREFIX/share/java/apksigner.jar`。

手动补进环境的 Android/Java 工具链已打包到：
`/storage/emulated/0/DSH/tools/android-toolchain.tar`
（包含 `lib/jvm/java-21-openjdk`、`bin/aapt`、`share/java/d8.jar`、
`share/java/apksigner.jar`；restore 脚本会在这些文件缺失时从 tar 解回原位置。）

## 当前不可用 / 未完整安装

- `clang` / `clang++` / `gcc` / `g++`：bin 目录里只剩损坏的符号链接，没有编译器二进制。
- `cmake`：bin 中没有可执行入口。

这些不是当前 Android APK 构建的必要项；`JpgToPng` 项目使用的是
`aapt + javac + d8 + apksigner`。需要时再单独安装，不要挪动现有文件。

## Python 3.14 部署说明（2026-08-16）

来源与方式：Termux stable 仓库（packages-cf.termux.dev，aarch64）的
`python 3.14.6-1` 及 18 个依赖包，用 `apt-get download` 下载、
`dpkg-deb -x` 解包，只把运行 prefix 中缺失的文件拷入
`$PREFIX`（不覆盖任何已有文件，不走 dpkg install 生命周期）。
deb 存档与清单：`/storage/emulated/0/DSH/tools/python-debs/`（含 MANIFEST.txt）。

依赖处理：绝大多数依赖（openssl/zlib/libffi/libexpat/libsqlite/ncurses/
readline/libbz2/libgdbm 等）runtime 基础层本来就有且版本一致，
实际新增的主要是 `lib/libpython3.14.so`、`lib/python3.14/`、`include/python3.14/`
和 bin 下的 python/pip 入口；liblzma 沿用基础层已有的 5.8.0（deb 里的
5.8.3 文件刻意没放）。文档类内容（share/man、share/doc、share/info）未部署。

路径适配：CPython 3.14 的 getpath 从可执行文件位置推导 prefix，实测无需
PYTHONHOME/PYTHONPATH；唯一需要的适配是 SSL CA 默认路径编译成了构建期
prefix，`lib/python3.14/site-packages/sitecustomize.py` 已按
`sys.base_prefix/etc/tls/cert.pem` 自动设置 `SSL_CERT_FILE`（环境未设时才设）。

恢复：`dsh-env-restore.sh` 已包含 Python 段——`$PREFIX/bin/python3.14`
缺失时从 deb 存档解包并只补缺失文件，随后修复 shebang、重建 sitecustomize。
2026-08-16 已实测「删除 python3.14 + lib/python3.14 + include/python3.14
+ bin 入口 → 运行恢复脚本 → python3/pip3/ssl/sqlite3 全部恢复正常」。

pip 范围：`python-pip 26.2.1` + `python-ensurepip-wheels` 已部署；
纯 Python wheel 的 install/uninstall 实测可用。没有编译器工具链，
构建 C/C++ 扩展的 wheel 目前不可行；`python3.14-config` 可用但没有
C 编译器配套。升级/卸载 python 走手工流程，不走 apt/pkg 生命周期。

## 已经修过的问题（含 2026-08-16 的 Mobile 兼容修复）

- 很多 Termux 脚本的 shebang 和内部路径原来指向
  `/data/data/com.termux/files/usr`，在本机实际不存在。
  已经统一修复为当前 `$PREFIX`，所以 `npm/npx/corepack/d8/r8/apksigner`
  现在可以直接运行。
- 这些修复都写进了 `dsh-env-restore.sh`，runtime 更新后重新执行一次即可。
- grep/glob 工具：`@vscode/ripgrep` 没有 android 平台包，已在
  `$PREFIX/lib/node_modules/@deepseek-ai/dsh/node_modules/@vscode/`
  下放置 `ripgrep-android-arm64` 包（Termux 官方 rg 15.2.0 二进制，
  源文件 `tools/rg-15.2.0-arm64`）；dsh web 重启后生效。
- git HTTPS：`~/.gitconfig` 的 `http.sslCAInfo` 指向
  `$PREFIX/etc/tls/cert.pem`，`init.templateDir` 指向
  `$PREFIX/share/git-core/templates`；remote helper 由
  `$PREFIX/bin/git-remote-*` symlink 找回。
- curl/wget HTTPS：`~/.curlrc`（`cacert`）与 `~/.wgetrc`
  （`ca_certificate`）指向同一 CA bundle。
- npm 全局前缀：`~/.npmrc` 设置 `prefix=$PREFIX`，`npm i -g` 安装到
  runtime 层（runtime 更新后需重装全局包）。
- 工具 shell 以 `bash --noprofile --norc -i` 启动：`~/.bashrc`/
  `~/.profile` 不会被读取，环境级修复一律走工具自身的配置文件或
  `$PREFIX/bin` 下的 shim。

## 恢复步骤

    sh /storage/emulated/0/DSH/tools/dsh-env-restore.sh

脚本只做安全修复：
1. 如果 Android/Java 工具链缺失，按缺失项从 `android-toolchain.tar` 解回；
2. 修复 `$PREFIX/bin`、`$PREFIX/libexec`、npm/corepack 启动器里的旧 Termux 路径；
3. 重建 pnpm/pnpx shim；
4. 如果 `~/workspace` 整体缺失，从最新的 home 备份自动恢复；
5. 如果 `~/workspace/JpgToPng` 缺失，从共享 `export/JpgToPng` 快照恢复为真实目录；
6. 从 `backups/dsh-profile` 补回缺失的用户长期内容：settings、home patch、
   `AGENTS.md`、skills、`.agent-presets`、`~/.agents/skills`、每个 profile
   的用户文件和 `@dsh-android` 适配包；
7. 重建 git remote helper symlink（`$PREFIX/bin/git-remote-*`）；
8. 从 `tools/rg-15.2.0-arm64` 重建 `@vscode/ripgrep-android-arm64` 平台包
   （grep/glob 工具的 rg 二进制，位于 runtime 层 node_modules）；
9. 从 `backups/dsh-profile/home-config` 补回缺失的 `~/.gitconfig`、
   `~/.curlrc`、`~/.wgetrc`、`~/.npmrc`，并检查 CA bundle 是否存在；
10. 打印关键工具检查结果。

## 备份步骤

    sh /storage/emulated/0/DSH/tools/home-backup.sh      # 备份 ~/workspace
    sh /storage/emulated/0/DSH/tools/dsh-env-backup.sh   # 备份所有 DSH 用户长期内容

如需连 `.credentials.yaml` 和 `.env` 一起备份（注意保密）：

    sh /storage/emulated/0/DSH/tools/dsh-env-backup.sh --with-credentials
