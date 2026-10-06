# PPPoE 开机自动拨号 · 部署与使用 SOP（v1.0）

> 适用系统：Windows 10 / 11（PowerShell 5.1+，系统自带）
> 目标：登录 Windows 后自动完成 PPPoE 宽带拨号；可选掉线自动重连；全程无感
> 权限要求：普通用户即可，**不需要管理员权限**
> v1.0 起提供图形安装器——**双击 `安装.cmd` 即可完成部署**（第 2 节）。手工/无人值守部署见第 4、6 节。

---

## 1. 前置条件

- 电脑上**已创建好 PPPoE 宽带连接**，平时能手动拨号上网（没有的话安装器会指引创建）
- 知道拨号账号和密码（校园宽带一般是手机号 + 密码）
- 开机时对应的网卡（有线）能随系统自动就绪

## 2. 快速部署（图形安装，推荐）

### 2.1 获取文件

下载仓库 zip 解压到**任意用户目录**（如 `D:\Tools\pppoe-autodial`）。

- ⚠️ 不要放在 `C:\Program Files` 等需要管理员权限的目录
- 若双击 `安装.cmd` 弹出"Windows 已保护你的电脑"（SmartScreen）：点"更多信息 → 仍要运行"；或右键文件 → 属性 → 勾选"解除锁定"

### 2.2 双击 `安装.cmd`，按向导操作

| 步骤 | 你会看到 | 说明 |
|---|---|---|
| 1 | 确认框："检测到拨号连接【×××】…" | 自动解析系统配置找出的 PPPoE 连接；多个时让你输入编号选择 |
| 2 | 输入框："请输入宽带账号" | — |
| 3 | 输入框："请输入宽带密码" | 明文显示，便于核对 |
| 4 | 询问是否启用「掉线自动重连」 | 默认不启用（直接回车即跳过） |
| 5 | （若启用）输入检测间隔 | 默认 15 秒，最小 10；建议用 10/12/15/20/30 这类能整除 60 的值 |
| 6 | 询问是否断线测试 | 建议选"是"：断网约 10 秒自动拨回，一步验证账号密码 |
| 7 | 完成提示 | 列出暂停/卸载/日志三个管理入口 |

### 2.3 验证

重启电脑，登录后什么都不用做——约 5~8 秒应自动联网。也可以直接看 `dial.log`。

## 3. 日常管理（全部双击即可）

| 需求 | 操作 |
|---|---|
| 暂停自动拨号（保留配置） | 双击 **暂停恢复.cmd**，按提示确认 |
| 恢复自动拨号 | 再次双击 **暂停恢复.cmd** |
| 完全卸载 | 双击 **卸载.cmd**（删除任务与凭据） |
| 修改检测间隔 | 编辑 `config.ps1` 中 `$reconnectSeconds` 的数值，再双击 `安装.cmd` 重装一次 |
| 查看运行记录 | 打开 `dial.log`（超过 512KB 自动滚动为 `dial.log.old`） |
| 命令行备查 | `Disable-ScheduledTask -TaskName "AutoDial-<连接名>"` / `Enable-` |

## 4. 无人值守安装（进阶）

```powershell
# 仅开机自动拨号
.\install.ps1 -ConnName "宽带连接" -User "账号" -Pass "密码"

# 同时启用掉线重连（15 秒检测间隔）
.\install.ps1 -ConnName "宽带连接" -User "账号" -Pass "密码" -Reconnect -ReconnectSeconds 15
```

适合批量部署/脚本化场景；执行过程无弹窗，成功输出 `OK: deployed.`。

## 5. 核心概念与原理

| 概念 | 说明 |
|---|---|
| **连接名** | 宽带连接的名字（如"宽带连接"），脚本靠它找到连接 |
| **服务名** | 部分校园网的 PPPoE 服务标识，已保存在连接配置里，**自动化时无需单独传** |
| **PPPoE 接口** | 拨号成功后出现的以连接名命名的网络接口。"是否在线"判断依据 |
| **DPAPI 凭据** | 密码用 Windows 数据保护 API 加密存于 `cred.dat`，绑定"当前用户+本机"，文件不含明文 |

**工作流程**：

```
任务计划（登录触发；可选每 15 秒错峰检测）
   └─ dial-hidden.vbs（静默启动器，保证无窗口闪现）
        └─ dial.ps1
             ├─ 读取 config.ps1 + 解密 cred.dat
             ├─ 检测 PPPoE 接口状态（在线 → 直接退出，幂等）
             ├─ rasdial 拨号，失败自动重试（12 轮）
             └─ 写 dial.log
```

### 坑 0：PPPoE 接口在 Get-NetAdapter 里看不到

拨号成功的接口**不会**出现在 `Get-NetAdapter` 列表里（那里只有物理网卡）。用：

```powershell
Get-NetIPInterface -InterfaceAlias "宽带连接" -AddressFamily IPv4   # 看 ConnectionState
Get-NetIPConfiguration | Where-Object InterfaceAlias -eq "宽带连接"  # 看拿到的 IP
ipconfig  # "PPP 适配器" 段
```

### 坑 1：不要用 Git Bash 执行拨号命令

Git Bash（MSYS2）调用 `rasdial ... /disconnect` 时参数可能被路径转换搞坏——**命令返回成功（退出码 0）但实际没执行**。所有拨号操作**一律在 PowerShell 里执行**，并用接口状态（而不是退出码）验证。

### 坑 2：别用"能不能开网页"判断拨号是否成功

电脑可能同时连着 Wi-Fi，流量不一定走 PPPoE；部分网络还禁 ICMP。唯一可靠标准：`Get-NetIPInterface` 返回 `Connected`。

### 坑 3：控制台黑框闪现（v1.0 已修复）

任务计划直接启动 `powershell.exe` 时，`-WindowStyle Hidden` 挡不住控制台窗口"先创建后隐藏"的瞬间——高频触发时每分钟都闪。v1.0 用 `dial-hidden.vbs` 经 `wscript` 静默拉起（窗口从创建起即隐藏），彻底解决。

### 原理补充：为什么用"错峰触发器"

任务计划服务对重复间隔有 **1 分钟硬下限**（小于 1 分钟会被拒绝注册）。所以 15 秒档的守护由 **4 个错峰触发器**实现：每个都"每 1 分钟重复"，起始点分别错开 15 秒——等效每 15 秒检测一次，且不引入任何常驻进程。

### 原理补充：开机的 3 秒等待

登录触发时网卡/交换机端口可能尚未就绪，脚本会在开机后 2 分钟内首次运行时先等 3 秒再拨号（失败还有重试兜底）；之后的守护检测则立即执行，不做任何等待。

## 6. 手工部署（不用安装器）

适合想理解每一步、或需要排查问题的人。

```powershell
# 1. 确认连接名（方括号里就是连接名；确认段落含 Device=WAN Miniport (PPPOE)）
rasdial
# 或看 %APPDATA%\Microsoft\Network\Connections\Pbk\rasphone.pbk

# 2. 命令行验证拨号（替换连接名/账号/密码）
rasdial "宽带连接" /disconnect
Start-Sleep -Seconds 3
rasdial "宽带连接" "账号" "密码"
(Get-NetIPInterface -InterfaceAlias "宽带连接" -AddressFamily IPv4).ConnectionState   # 应为 Connected

# 3. 写配置（可参考 config.example.ps1；含中文的连接名需以 UTF-8 with BOM 保存）
Copy-Item config.example.ps1 config.ps1
notepad config.ps1     # 填写 $connName / $userName

# 4. 生成加密凭据
$sec = ConvertTo-SecureString '你的密码' -AsPlainText -Force
ConvertFrom-SecureString $sec | Set-Content .\cred.dat -Encoding ASCII

# 5. 单跑脚本测试（在线时应打 "online ... nothing to do" 日志）
powershell -ExecutionPolicy Bypass -File .\dial.ps1

# 6. 注册任务（-Reconnect 启用掉线守护）
powershell -ExecutionPolicy Bypass -File .\register-task.ps1
powershell -ExecutionPolicy Bypass -File .\register-task.ps1 -Reconnect
```

## 7. 故障排查

| 现象 | 可能原因 | 处理 |
|---|---|---|
| 日志 `GAVE UP: all retries failed` | 账号密码错 / 网线未插 / 交换机端口问题 | 按第 6 节第 2 步手工复现，看 rasdial 错误码 |
| 日志 `ERROR: failed to decrypt cred.dat` | 换了 Windows 账户或重装过系统（DPAPI 绑定失效） | 重新运行 `安装.cmd`（重新输入密码），或按第 6 节第 4 步重建 |
| 日志 `ERROR: config.ps1 not found` | 配置文件被删 | 重新运行 `安装.cmd` |
| 日志 `ERROR: cred.dat not found` | 凭据文件被删 | 同上 |
| 开机后没拨号 | 任务被暂停或删除 | 双击 `暂停恢复.cmd` 查看并恢复；或重新运行 `安装.cmd` |
| 每隔一段时间闪黑框 | 使用了 < v1.0 的旧版本 | 升级到 v1.0（含 `dial-hidden.vbs` 静默启动器） |
| 拨上又很快掉线 | 同账号在别处拨入（互踢），或运营商策略 | 与工具无关；断线守护会在下次检测时自动恢复 |

### rasdial 常见退出码

| 代码 | 含义 |
|---|---|
| 0 | 成功 |
| 651 | 设备未就绪（拨号过早，脚本会自动重试） |
| 676 | 线路忙 |
| 678 | 无应答（网线/交换机问题） |
| 691 | 认证失败：账号或密码错误 |
| 720 | PPPoE 会话冲突，稍等重试 |

## 8. 附录：文件清单与速查

```
pppoe-autodial\
├── 安装.cmd            ← 双击：图形安装
├── 暂停恢复.cmd         ← 双击：暂停/恢复自动拨号
├── 卸载.cmd            ← 双击：完全卸载
├── install.ps1          安装向导（含无人值守参数模式）
├── uninstall.ps1        卸载逻辑
├── manage.ps1           暂停/恢复逻辑
├── register-task.ps1    任务注册（-Reconnect 启用守护）
├── dial.ps1             拨号核心（任务实际运行的脚本）
├── dial-hidden.vbs      静默启动器（消除黑框）
├── config.example.ps1   配置模板（config.ps1 由安装器生成）
├── config.ps1           你的配置（安装后生成，含账号）
├── cred.dat             加密凭据（安装后生成）
├── dial.log             运行日志（自动生成）
└── docs\                SOP 与 PRD
```

**常用命令速查（PowerShell）**

```powershell
rasdial                                                     # 列出所有拨号连接
(Get-NetIPInterface -InterfaceAlias "宽带连接" -AddressFamily IPv4).ConnectionState   # 在线状态
Start-ScheduledTask  -TaskName "AutoDial-宽带连接"           # 手动触发一次
Disable-ScheduledTask -TaskName "AutoDial-宽带连接"          # 暂停
Enable-ScheduledTask  -TaskName "AutoDial-宽带连接"          # 恢复
```
