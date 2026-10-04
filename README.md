# Serial Scope

通用串口调试与实时数据可视化工具，基于 [Serial Studio v4.0.2](https://github.com/Serial-Studio/Serial-Studio/tree/v4.0.2) 的独立社区 GPL 构建。维护者：ahpasserby。

保留上游 GPL 构建的通用功能：UART 串口、TCP/UDP、BLE、文本/HEX 控制台、Lua/JavaScript/内置解析器、多通道曲线、CSV 记录与回放、手动命令 Action。不限于 STM32 或 PID，也不在应用中写死任何设备协议。

这是社区二开版本，不是官方 Pro 安装包；不包含或解锁 Pro 专属模块。保留上游版权和许可证，未修改授权验证逻辑。上游说明见 [README.upstream.md](README.upstream.md)，许可证见 [LICENSE.md](LICENSE.md) 和 [LICENSES](LICENSES)。

## macOS 使用

从本仓库 Releases 下载 Apple Silicon 构建，解压后把 `Serial-Scope.app` 放到 Applications。社区包使用 ad-hoc 签名，未经过 Apple 公证；从网络下载后 macOS 可能要求在系统设置的“隐私与安全性”中允许打开。

1. 打开应用，选择 UART 和实际串口，设置设备波特率。
2. 只收发数据选择 Console Only；文本 CSV 绘图选择 Quick Plot；自定义协议选择 Parse via Project File。
3. 点击右上角 Connect。控制台和图表页底部都有发送栏：输入文本，点击 Send 或按回车发送；可选择 HEX、行尾和校验方式。图表持续刷新，无需切回控制台。

## 已有配置

- [PID.ssproj](examples/Community/PID.ssproj)
- [UARTdrawing.ssproj](examples/Community/UARTdrawing.ssproj)

这两个文件保留用户现有解析脚本和绘图配置，只移除了本机串口选择及 USB 设备序列号。打开后需要重新选择实际串口。PID 示例读取 49 字节帧（AB + 两个小端 float + 40 字节补零）；不是应用的通用协议限制。配置未额外添加命令按钮。已有 STM32 固件可通过底部发送栏发送 `po=数值#`、`io=数值#`、`do=数值#`；关闭 HEX，不追加换行，一次一条。

## 从源码构建

需要 macOS Command Line Tools 和 Homebrew：

```sh
brew install cmake ninja qtbase qtdeclarative qtsvg qtgraphs qtconnectivity qtserialport qt5compat qttools
./scripts/build-community-macos.sh
```

构建输出位于 `build-community/app/Serial-Scope.app`；用于安装和分发时请继续运行打包脚本。

默认仅构建 GPL 功能，关闭 WebEngine（帮助内容使用 Qt 富文本）、自动更新和 mimalloc。自动更新关闭是为了避免社区版被官方 Pro 安装包替换。使用标准上游构建选项，不需要许可证或商业构建凭据。

```sh
./scripts/package-community-macos.sh
```

打包脚本会复制 Qt 依赖，加入源码来源及许可文件，使用本机 ad-hoc 签名。输出在 `dist/`。对应源码和脚本随 Release tag 提供；第三方依赖说明见 `THIRD_PARTY_COMMUNITY.md`。

## 二开内容

- 独立应用名称、图标、macOS bundle ID 和设置空间，与官方版本并存。
- 通用串口助手功能沿用上游 GPL 实现。
- 提供两份已有设备配置、可复现的 macOS 构建和打包脚本。
- 禁用官方安装包自动更新，保留上游署名及许可证。
- 修复 Homebrew Qt 资源链接及 QML 插件签名，生成可独立运行的 macOS 包。
- 修复 `--uart` 注册设备却未选中端口，以及项目模式未应用该覆盖的问题。

当前发布目标为 macOS Apple Silicon；其他系统的上游构建仍需单独适配验证。

## 验证

```sh
QT_QPA_PLATFORM=offscreen qmltestrunner -input tests/community -o -,txt
node scripts/test-community-projects.js
python3 scripts/test-community-uart.py
```

集成测试创建临时项目和虚拟串口，不操作真实硬件，验证命令行选中端口、二进制拆包/合包、绘图数据、文本/HEX 发送和断开。运行前关闭占用本地 API 端口 7777 的程序。测试进程临时允许向它自己的虚拟串口写入。

本机已验证 macOS 26 / Apple Silicon、Qt 6.11.2：完整构建、GUI 启动、虚拟 UART 双向收发、两个配置的脚本语法、PID 流式解析。真实电机控制效果不属于这次桌面应用验证。
