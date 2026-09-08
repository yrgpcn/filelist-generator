# 开发与维护笔记（MAINTENANCE）

> 本文档沉淀了 v1.0.x 开发过程中经多轮 AI 交叉审查（Gemini / Claude）迭代出的**设计约束、历史踩坑教训与发布流程**。
> 修改本仓库代码前请先通读，避免重蹈覆辙或无意中破坏已有修复。

## 一、文件职责

| 文件 | 职责 |
| --- | --- |
| `filelist.py` | 主脚本：扫描 → 生成 Excel。单文件、无第三方框架依赖 |
| `生成文件清单.bat` | Windows 双击启动器：探测 Python（py launcher → PATH → 常见安装目录），都找不到时回退独立 exe（`filelist.exe` 或 `filelist-vX.Y.Z.exe`） |
| `filelist_version.txt` | PyInstaller exe 的版本信息文件（**发布时三处版本号需同步**，见第四节） |
| `.github/workflows/` | GitHub Actions：打 tag 后自动构建 exe 并发布 Release |
| `requirements.txt` | 声明 openpyxl 依赖 |

## 二、关键设计约束（改动前必读，勿破坏）

1. **自排除用绝对路径比对**：排除脚本自身与输出文件必须用 `os.path.normcase(os.path.abspath(full))` 与排除集合比对。若改回"按文件名比对"，子目录中的同名文件会被误排除。
2. **超链接必须 percent-encode**：OOXML 中 hyperlink `Target` 按 URI 语义解析——`#` 被当锚点、`%` 被当编码前缀。必须用 `file:///` + `urllib.parse.quote` 编码（`#`→`%23`、`%`→`%25`），否则特殊文件名的链接失效。
3. **Excel 三重安全限制**（改常量前想清楚）：
   - `MAX_SHEET_ROWS = 1_048_575`：单 sheet 行数上限，超出截断并警告；
   - `LINK_SAFE_LIMIT = 32_000`：超链接数量保护（超限自动关闭超链接，防文件损坏）；
   - `MAX_LINK_LENGTH = 255`：单条超链接 Target 长度上限，超长截断、降级为纯文本 + 提示。
4. **日期列写 `datetime` 对象**并设置 `number_format = "YYYY-MM-DD HH:MM"`，不要写成字符串——字符串无法在 Excel 中按日期排序/筛选。
5. **输出文件被占用时自动另存**：清单正被 Excel 打开时 `PermissionError`，脚本会自动改存带时间戳的文件名，不要移除这个兜底。
6. **权限不足目录要有提示**：`os.walk(onerror=...)` 收集无法访问的目录并在结束时报告，不要静默吞掉。

## 三、历史踩坑教训（每条都真实发生过，勿回退）

### 1. `.bat` 里禁用 `chcp 65001`
- **现象**：加 `chcp 65001` 后，双击 .bat 闪退，且文件夹里多出 0KB 乱码文件（如"濚濣牼"）。
- **因果链**：chcp 改变 cmd 代码页 → Python 子进程的 `__file__` / `sys.argv[0]` 路径解码错乱 → `args.output` 变乱码 → `wb.save()` 用乱码路径创建了 0KB 乱码文件；同时 `sys.stdin.isatty()` 行为异常 → 等待逻辑失效 → 窗口一闪而过。
- **修法**：.bat 中**不写 chcp**；所有 echo 用**纯英文**（.bat 若为 UTF-8 编码，中文字符在默认 GBK cmd 下会乱码显示）。

### 2. 双击场景 `sys.stdin.isatty()` 不可靠
- **现象**：双击 .py 或某些 .bat 下 `isatty()` 返回 False，脚本内 `input()` 等待逻辑被跳过 → 完成即退出 → 闪退。
- **修法**：
  - `.bat` 末尾**无条件 `pause >nul`** 兜底（不要做成"仅 errorlevel≠0 才 pause"，双重防御会互相抵消成零防御）；
  - `.py` 的 `__main__` 加全局 try/except + `finally` 中 `isatty()` 时 `input("按回车键退出...")`，EOFError/KeyboardInterrupt 静默处理。

### 3. cmd 批处理的变量展开时机
- **现象**：`for /f` 块内 `set "VAR=%%i"` 后，同块内用 `%VAR%` 读不到——cmd 在**解析时**就展开 `%VAR%`（此时变量还是空的）。
- **修法**：判断逻辑直接使用循环变量 `%%i`（如 `echo %%i| findstr ...`），把"读变量"的判断放到块**外**（`if not defined PY` 在块外是安全的）。

### 4. Python 探测必须前置门控 + 严格正则
- **现象**：系统未装 Python 时，`for /f ('python --version 2>&1')` 会捕获 cmd 的**报错文本**（其中含 "python"），用宽松的 `findstr "Python"` 会误匹配 → 错误地把 PY 设为 python。
- **修法**：`where python >nul 2>&1 && (...)` 先确认命令存在；再用 `findstr /r /i "Python [0-9]"` 要求"Python"后紧跟空格+数字（真正的版本号格式），排除 Windows Store 占位符和报错文本。

### 5. 旧示例路径残留会误导用户
- docstring / 注释里的示例路径曾从真实项目路径（"新国都"等）迁移时被遗忘，用户误以为代码没改。**示例路径一律用通用占位符**（如 `D:\要统计的文件夹`）。

## 四、发布流程 Checklist

1. `filelist_version.txt` 中 **3 处版本号**同步更新：`filevers`、`prodvers` 元组 + `FileVersion`、`ProductVersion` 字符串；
2. README 如有新选项/行为变化，同步更新；
3. 提交并打 tag：`git tag vX.Y.Z && git push origin main --tags`；
4. GitHub Actions 自动构建 exe 并发布 Release；
5. 发布后下载 exe 做冒烟测试（见下节）。

## 五、回归测试要点（每次改动后过一遍）

- [x] 文件名含 `#`、`%`、空格、中文：链接可点击、指向正确文件
- [x] 根目录与子目录存在**同名**文件（如两个 filelist.py）：仅根目录被排除，子目录保留
- [x] 超长路径（URI > 255 字符）：降级为纯文本 + 提示，不报错
- [x] `--no-links` / `--no-recursive` 开关行为正确
- [x] 清单文件正被 Excel 打开时重跑：自动时间戳另存，不丢数据
- [ ] 双击 .bat（有/无 Python 两种环境）：不闪退、乱码路径不产生垃圾文件
- [ ] 未装 Python：.bat 正确回退到 filelist.exe

> 2026-09-08（v1.1.0）：前 5 项已通过 CLI / 单元级自动化验证（链接以生成的 Target 正确为准，Excel 内实际点击属 GUI 行为）；后 2 项涉及双击场景，留待人工冒烟。

## 六、GitHub Actions 自动构建（Codex 验证记录）

### 1. 已验证可用（v1.0.2 / v1.1.0 Release 实测通过）
- 工作流 `.github/workflows/build.yml`：Windows runner + Python 3.12 + PyInstaller。
- 触发方式：
  - **push tag `v*`** → 自动构建 exe 并发布 Release；
  - **workflow_dispatch** → 手动触发（Actions 页面 → Build exe → Run workflow），仅构建 artifact，不发布 Release。
- `permissions: contents: write` 必须保留，否则 softprops/action-gh-release 会因无写权限而 403。
- v1.0.2 构建产物已验证：exe 约 9.11 MB，版本属性（FileVersion / CompanyName / LegalCopyright / ProductName）全部正确。
- v1.1.0 构建产物已验证（2026-09-08）：Release 挂载 exe 9.11 MB，FileVersion / ProductVersion = 1.1.0、CompanyName = Kwong Young（经 API 下载核对）。

### 2. 非阻塞警告
当前使用的 `actions/checkout@v4`、`actions/setup-python@v5`、`actions/upload-artifact@v4`、`softprops/action-gh-release@v2` 底层运行在 Node.js 20 上，GitHub 已预告将弃用。功能不受影响，后续可逐个升级到更新的大版本以消除警告。

### 3. 发布流程（推荐用 GitHub Desktop 操作）
1. 在 `filelist_version.txt` 中同步更新**三处版本号**（`filevers` 元组、`prodvers` 元组、`FileVersion` 字符串、`ProductVersion` 字符串，实际共 4 处文本）。
2. 在 GitHub Desktop 中提交并 push 到 main。
3. 在 History 面板中右键目标提交 → **Create tag on this commit** → 输入标签号（如 `v1.1.0`）→ 确认后 push tag（GitHub Desktop 会自动把 tag 一并推送）。
4. 等待 Actions 自动构建（通常 1-2 分钟），成功后 Release 页面会出现新版本并自动挂载 exe。
5. 下载 exe 做冒烟测试（右键属性确认版本号、双击运行确认功能正常）。

> **注意**：`workflow_dispatch` 手动触发只产出 artifact，不创建 Release。如果只想验证构建是否通过而不发布，用手动触发即可。

### 4. 本机环境特点
- 本机已安装 Python 3.12（`py -3` 可用，openpyxl 3.1.5 已装），可直接跑脚本与回归测试；未装 PyInstaller，exe 仍靠 GitHub Actions 云端构建。
- Git CLI 直连 github.com:443 不通；实测**走本机回环代理可稳定推送**：`git -c http.proxy=http://127.0.0.1:10808 push origin main v1.1.0`（v1.1.0 发布即此方式成功）。代理软件未运行时回退 GitHub Desktop。
- Chrome 下载目录在 `E:\Downloads`（非默认位置）。

### 5. 当前已知遗留
- LICENSE 版权占位符已替换为 `Kwong Young`（与 exe 元数据 CompanyName/LegalCopyright 一致）。
- 标签 `v1.01`：2026-09-08 核实，本地与 GitHub 远端均已不存在（仅 v1.0.0 / v1.0.2），无需再处理。

## 七、仓库整洁度检查（2026-09-08 Codex 记录）

### 1. 文件清单
Git 追踪的 10 个文件全部有用，无冗余：

| 文件 | 用途 |
| --- | --- |
| `filelist.py` | 主脚本 |
| `生成文件清单.bat` | Windows 启动器 |
| `filelist_version.txt` | PyInstaller 版本信息 |
| `.github/workflows/build.yml` | Actions 自动构建 |
| `requirements.txt` | openpyxl 依赖 |
| `.gitignore` | 排除 Python 构建产物 |
| `.gitattributes` | 换行符规范（.bat=CRLF, .py=LF） |
| `README.md` / `MAINTENANCE.md` / `LICENSE` | 文档与许可 |

工作目录干净（无未追踪文件），`.gitignore` 覆盖 `__pycache__/`、`dist/`、`build/`、`*.spec` 等构建产物。

### 2. 标签清理建议
| 标签 | 指向 | 状态 | 建议 |
| --- | --- | --- | --- |
| `v1.0.0` | 初始提交 `694d41c` | 历史版本 | 可保留也可删除，无 Release 挂载 |
| `v1.01` | `4139287`（bat 引号修复） | **格式错误**（无小数点分隔符） | **建议删除**，避免与 `v1.0.1` 混淆 |
| `v1.0.2` | `d796915`（当前 Release） | 正确 | 保留 |

删除方法：GitHub 网页 → Releases/Tags → 找到对应标签 → 删除；或命令行 `git push origin :refs/tags/v1.01`（网络不稳时用网页操作更可靠）。

> 删除标签不影响已有 commit 和 Release 页面内容，但如果该标签曾触发过 Actions 构建，对应 Release 的 exe 会保持不变（Release 是独立于标签存在的）。

## 八、v1.1.0 变更（2026-09-08）

### 1. 新增功能
- **拖曳选择文件夹**：交互模式下先询问目标文件夹（提示拖入窗口，回车使用默认）；同时支持将文件夹作为位置参数传入（对应把文件夹拖到 exe / bat 图标上的用法）。可一次指定多个文件夹，逐个生成各自的清单。
- **子文件夹统计** 工作表：统计每个子文件夹的文件数、大小及大小占比，按大小降序排列，用于快速定位占用空间大的文件夹。
- **生成后自动打开**（`--open` / `--no-open`）：双击等交互场景默认打开，命令行/管道场景默认不打开；输出文件被占用而另存时，打开的是实际保存的时间戳文件（`generate_one` 返回真实保存路径）。
- 拖入路径解析由 `parse_drag_paths` 实现：兼容 Windows 资源管理器投递的带引号含空格路径与手动输入的无引号路径；`filter_existing_dirs` 逐项校验存在性，无效项打印 `[跳过]` 提示。

### 2. 修正：自排除实现曾违反本文件二.1
- 旧实现在绝对路径比对之外，还额外使用 `skip_names`（小写文件名集合）排除 `filelist.py` 与 `生成文件清单.bat`——目标文件夹子目录中的同名文件会被误排除，正是二.1 所警示的情形。
- 现改为**仅按绝对路径比对**：`scan_folder` 移除 `skip_names` 形参；工具自身与同目录 bat 在 `main` 中统一构建为 `own_paths`（绝对路径集合）传入。回归新增用例：子目录中放置的 `filelist.py` 应予保留。

### 3. 相关回归补充（配合新功能，第五节清单之外）
- [x] 拖入含空格路径 `"D:\a b"`：正确解析为单个路径
- [x] 一次拖入两个文件夹：各自生成 `文件清单.xlsx`，互不干扰
- [x] 拖入不存在的路径：打印 `[跳过]`；全部无效时回退默认文件夹
- [x] 子目录中存在 `filelist.py`：仅根目录的工具文件被排除，子目录同名文件保留
- [x] 相对链接长度 > 255：降级为纯文本并添加 `[路径过长]` 提示，不生成被截断的无效链接

> 2026-09-08：以上 5 项已在改动时通过命令行 / 单元 / 内存级测试完成自动化验证。
> **待人工验证（冒烟）**（v1.1.0 exe 已发布，属 GUI 行为，无法自动验证）：将文件夹拖入 exe 控制台窗口后回车；将文件夹拖到 exe / bat 图标上；生成后 Excel 自动打开。

## 九、v1.1.1 变更（2026-09-08）

### 1. Release exe 文件名带版本号
- 工作流在 PyInstaller 构建后新增重命名步骤：tag 触发时产物命名为 `filelist-vX.Y.Z.exe`（如 `filelist-v1.1.1.exe`），`workflow_dispatch` 无标签时为 `filelist-dev.exe`；Upload artifact 与 Release `files` 均改为通配 `dist/filelist-*.exe`。
- 重命名逻辑已在本地以等价 PowerShell 语句验证两个分支输出正确。

### 2. 启动器兼容带版本号的 exe
- `生成文件清单.bat` 第 5 步回退逻辑：优先使用 `filelist.exe`；不存在时以 `dir /b /a-d /o-d "%~dp0filelist-v*.exe"` 探测最新的 `filelist-vX.Y.Z.exe`。探测逻辑的四个场景（无 exe / 仅带版本 / 两者并存 / 仅版本多份）已在隔离副本中实测通过；主 bat 的 Python / 无 Python 两条控制流路径另行验证。

### 3. 文档与提示语措辞规范化
- v1.1.0 新增内容中的口语化表述统一改为书面表述（如"拖进"→"拖入"、"坏链接"→"无效链接"、"互不串台"→"互不干扰"）。历史既有文本不追溯。

### 4. 踩坑教训：整文件重写启动器时遗漏控制流门控
- **现象**：本轮以整文件重写方式修改 .bat，把回退段从 `if not defined PY ( ... )` 块改为 goto 结构时，遗漏了块末尾的 `goto :end`——按顺序执行的话，检测到 Python 也会继续落入 exe 回退段，正常分支被跳过。
- **发现方式**：重写后逐行核对 diff 时发现缺失跳转标签。
- **修法**：Python 探测成功后 `if defined PY goto :run_py` 显式门控，回退段置于其后。
- **教训**：对 .bat 这类靠标签与顺序执行控制流程的文件，禁止只验证新增片段——修改后必须整体核对控制流（Python 存在与否两条路径都要走到正确出口）；此教训与三.2"双重防御互相抵消"同属 bat 控制流类陷阱。
