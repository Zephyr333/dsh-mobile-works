# JpgToPng

在 DSH Mobile 上从零开发的 Android APK 小工具：选择一张 JPG/JPEG 图片，转成 PNG 保存。
本机（Android 16, aarch64）已实测构建并安装运行。

## 特点

- 无 Android SDK / Gradle：使用项目内最小 `android.*` stub 源码 +
  系统自带 `aapt + javac + d8 + zipalign + apksigner` 工具链
- SAF 文件选择（ACTION_OPEN_DOCUMENT / ACTION_CREATE_DOCUMENT），不需要存储权限
- 纯代码 UI（无 XML 布局），单 Activity

## 目录

- `app/src/main/java/com/example/jpgtopng/MainActivity.java` — 应用逻辑
- `app/stub/src/android/**` — 最小 android.* stub（仅编译所需签名）
- `app/res/values/strings.xml` — 应用名资源
- `app/AndroidManifest.xml` — minSdk 24 / targetSdk 28
- `build.sh` — 一键构建脚本

## 构建

    sh build.sh

`build.sh` 在 `app/build/` 下生成 `JpgToPng.apk`。签名 keystore 首次运行时自动生成
（密码随机生成并打印一次，或用环境变量 `JPGTOPNG_KS_PASS` 指定）。keystore 与所有
构建产物位于 `app/build/`，已被 .gitignore 排除，不要提交。

关键步骤（与 build.sh 一致）：

1. `javac` 编译 stub 源码，`jar` 打包为 android-stub.jar
2. `javac -source 1.8 -target 1.8 -cp android-stub.jar` 编译 MainActivity
3. `d8 --release --min-api 24` 生成 classes.dex
4. `aapt package -S res -I /system/framework/framework-res.apk` 生成 unsigned APK
   （借用设备 framework-res.apk 提供 `@android:` 资源，需在真机环境执行）
5. `jar uf` 加入 classes.dex，`zipalign -f 4` 对齐
6. `keytool` 生成本地 keystore，`apksigner` 签名并 verify

## 已知边界

- 使用本地开发 keystore 签名，非正式发布签名。
- targetSdk 28，仅实现基础 SAF 流程；功能简单，实测可用。
