> **当前 Project Orchestrator 版本：v2.5**（`manual-pr`，`e753fa739a4b2c8940735c4788518c76625d73b1`）。支持单主 Codex（`agent:codex`）或 Google Antigravity（`agent:antigravity`）+ `max_supported` 并发子 Agent，由 ChatGPT 独立 exact-HEAD 终审；阶段边界：`STAGE_ACCEPTED_READ_ONLY_MANUAL_HANDOFF / AUTONOMOUS_DISPATCH_BLOCKED`（文档/评论不自动派发，未启用自动合并或本地调度器）。以下原有状态与历史记录保持不变，实时任务以 GitHub Issue/PR 为准。

# filelist-generator — Project Orchestrator v2 状态入口

- **协作契约**：v2（2026-11-19），不改变本仓库实际产品版本或现有代码功能。
- **实时任务和进度**：以本仓库 GitHub Issues、Pull Requests 和提交记录为准；此页不复制会过时的任务状态。
- **接手顺序**：README、[当前路由](ROUTING.md)、相关 Issue/PR 及实际验证证据。
- **CI**：仅任务实际使用 CI 或当前验收/合并门禁要求 CI 时才检查；首次采用 Orchestrator 不要求 CI 预检或账号连接。
- **生效边界**：没有自动 Codex 调度或生产/凭据/网络/费用/权限授权；历史日志和旧 PR 仍按原记录追溯。

上游规范：[Project Orchestrator v2](https://github.com/yrgpcn/project-orchestrator/tree/c1838a3e67b01ff5e1fc756fdd594270391af5d5)。
