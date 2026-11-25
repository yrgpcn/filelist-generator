> **当前有效路由：Project Orchestrator v2.5**（`e753fa739a4b2c8940735c4788518c76625d73b1`）。新任务由 `agent:chat`（ChatGPT）负责规划、边界决策与 exact-HEAD 独立终审；执行由单主 `agent:codex` 或 `agent:antigravity`（`task-lease/v1` 互斥）按 `max_supported` 并发协调隔离子 Agent 完成，并自主整改 Tier 1 普通工程问题（不得自我批准）。已停用的 WorkBuddy 仅保留历史归档；Runner/CI 仅在任务实际使用或门禁需要时验证（Actions 外部阻塞时可评估已授权 CircleCI，不绕过 required checks）。完整要求存 GitHub 仓库、用户仅用简短入口、结果回写仓库；Tier 2 自动合并默认关闭，Tier 3 高风险/生产/权限/数据变更须用户明确授权；当前阶段边界为 `STAGE_ACCEPTED_READ_ONLY_MANUAL_HANDOFF / AUTONOMOUS_DISPATCH_BLOCKED`。

# filelist-generator — Project Orchestrator v2 工作路由

- **ChatGPT（agent:chat）**：需求、设计、风险、任务编排、独立审核、合并准备度与用户授权事项。
- **单主 Codex（agent:codex）**：在一次已授权工作包内完整开发、普通缺陷自主修复、必要验证和交付报告；按明确文件边界分派 Codex 子 Agent，独立审核不可自批。
- **实际环境**：本机、浏览器、服务器或外部服务只由具备该访问条件且获授权的 Codex/操作方执行。不使用 WorkBuddy 作为新任务角色。
- **Runner/CI**：独立验证，不是 agent；**首次引入 v2 不检查 CI**，实际使用 CI 或 CI 属于当前必要门禁时才检查可用性。若 GitHub Actions 因账单/额度/runner 无法运行，应主动评估已授权 CircleCI，但不得跳过原生 required checks。
- **GitHub**：Issues/PR/当前 HEAD 和检查结果为可追溯事实来源；无真实执行通道不得把准备好的任务称作已经派发。

**交付优先**：首次任务覆盖完整可交付范围，普通缺陷由主 Codex 在同一工作包自主整改；不处理没有现实影响的极端低概率问题（须记录），核心功能、数据安全与权限边界不豁免。迁移不修改本项目应用、测试脚本、部署或发布权限。
