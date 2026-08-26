# 文件清单生成器 (File List Generator)

一个放进任意文件夹就能用的 **Excel 文件清单**小工具：运行后自动扫描**脚本（或 exe）所在文件夹**，生成 `文件清单.xlsx`。

## 功能特性

- 自动扫描脚本/exe 所在文件夹，生成 Excel 清单
- **文件清单** 工作表：序号、文件名、扩展名、文件大小、修改日期、所在文件夹、完整路径
- **统计汇总** 工作表：文件总数、文件夹总数、总大小、扩展名分布
- 「文件名」列生成**可点击超链接**，使用相对路径，中文长路径也能正常链接
- 可选开关：
  - 是否带超链接（`--links` / `--no-links`）
  - 是否列出隐藏文件和隐藏文件夹（`--hidden` / `--no-hidden`，默认关闭）
  - 是否递归扫描子文件夹（`--recursive` / `--no-recursive`）
- 自动排除工具自身文件（脚本、启动器、exe）和输出的清单文件
- 清单文件正被 Excel 打开时，自动另存为带时间戳的文件，不丢数据
- 跨平台：Windows / macOS / Linux（需 Python 3 + openpyxl）
- 可用 PyInstaller 打包成**独立 exe**，目标电脑无需安装 Python

## 快速开始

### 方式一：使用源码（需要 Python 3）

```bash
# 把 filelist.py 放进任意文件夹，然后：
python filelist.py            # 自动扫描脚本所在文件夹
```

双击运行时会依次询问 3 个问题（直接回车用默认值）：
1. 文件名要可点击的超链接吗？（默认：是）
2. 要列出隐藏文件和隐藏文件夹吗？（默认：否）
3. 要递归扫描子文件夹吗？（默认：是）

### 方式二：独立 exe（无需 Python）

在 [Releases](https://github.com/) 下载 `filelist.exe`，放进任意文件夹双击即可。

> 💡 **首次运行提示**：exe 未做数字签名，Windows SmartScreen 可能会提示“已保护你的电脑”。点击“更多信息 → 仍要运行”即可，这是未签名程序的正常现象，不影响使用。

## 命令行选项

| 选项 | 说明 |
| --- | --- |
| `-s, --source` | 要扫描的文件夹（默认：脚本所在文件夹） |
| `-o, --output` | 输出文件路径（默认：被扫描文件夹/文件清单.xlsx） |
| `--links` / `--no-links` | 是否生成可点击超链接（默认开启） |
| `--hidden` / `--no-hidden` | 是否列出隐藏文件/文件夹（默认关闭） |
| `--recursive` / `--no-recursive` | 是否递归子文件夹（默认开启） |

### 示例

```bash
python filelist.py                       # 默认生成
python filelist.py --no-hidden           # 不列出隐藏文件/文件夹
python filelist.py --no-links            # 不要超链接
python filelist.py -s "D:/下载" -o "D:/下载/我的清单.xlsx"
```

## 从源码打包 exe

```bash
pip install pyinstaller openpyxl
pyinstaller --onefile --name filelist filelist.py
# 生成文件在 dist/filelist.exe
```

## 环境要求

- Python 3.6+
- openpyxl（脚本检测到缺失时会自动尝试安装，也可手动：`pip install openpyxl`）

## 常见问题

- **文件名列没有超链接？** 可能是文件数过多（自动关闭超链接以防 Excel 损坏）或路径过长无法生成安全链接。
- **提示 Python not found？** 电脑未安装 Python，请改用独立 exe，或安装 Python 后重试。
- **生成的清单里没有脚本/exe 自身？** 这是设计如此，工具会跳过自身文件。

## 许可证

[MIT](LICENSE)
