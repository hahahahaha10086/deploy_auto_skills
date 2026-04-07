# Claude Code Agent Patterns Mapping

## Purpose

This document captures the most relevant engineering ideas from `E:\project\claude-code\src` and maps them to concrete backend changes for `repo-auto-deployer`.

The goal is not to copy Claude Code's full product surface. The goal is to borrow the parts that strengthen our automatic deployment system:

- evidence-driven execution
- unified deployment context
- dynamic capability exposure
- observable command execution
- gated risk checks
- stepwise repair loops

## What Is Worth Borrowing

### 1. Unified tool context

Reference:
- `E:\project\claude-code\src\Tool.ts`

Claude Code keeps tool execution inside a shared context object instead of passing scattered state between isolated functions.

What we should borrow:
- a single deployment execution context object
- shared access to scan result, AI understanding, selected skill, plan, environment checks, logs, diagnostics, and verification state

Why it matters:
- deployment stops being a loose pipeline and becomes a stateful execution session
- retries and repair loops can reuse the same context instead of rebuilding partial state

### 2. Dynamic capability exposure

Reference:
- `E:\project\claude-code\src\tools.ts`

Claude Code does not expose every tool in every environment. It registers the full tool universe, then filters by runtime conditions.

What we should borrow:
- detect deploy capabilities first
- only expose deploy strategies that the current host can actually support

Examples:
- only use Docker paths when Docker is installed
- only use PowerShell-specific execution on Windows
- only use systemd-style service plans on Linux hosts

Why it matters:
- the model stops proposing impossible deployment actions

### 3. Session-based command execution

Reference:
- `E:\project\claude-code\src\bridge\sessionRunner.ts`

Claude Code treats execution as a session with:
- live activity extraction
- stdout/stderr capture
- transcript logging
- permission requests
- structured completion/error states

What we should borrow:
- a dedicated deployment session runner
- per-step command lifecycle tracking
- stderr ring buffer
- raw transcript log on disk
- structured activity stream for UI and diagnostics

Why it matters:
- deployment becomes observable
- failures become diagnosable from evidence, not guesswork

### 4. Gated execution

Reference:
- `E:\project\claude-code\src\utils\permissions\permissions.ts`

Claude Code does not directly execute every requested action. It checks rules, context, and safety conditions first.

What we should borrow:
- deployment gatekeeping before execution
- explicit allow / prepare_first / deny_auto_deploy / manual_review outcomes

Gate examples:
- current host OS is incompatible
- required middleware is missing
- command is destructive or ambiguous
- runtime topology is multi-service but only single-service execution is supported

Why it matters:
- prevents blind deployment attempts

### 5. Lightweight task model with clear terminal states

Reference:
- `E:\project\claude-code\src\Task.ts`

Claude Code keeps task lifecycle simple but explicit.

What we should borrow:
- clearer deployment stage model
- terminal vs recoverable status rules

Suggested deployment stages:
- `understanding`
- `skill_selection`
- `environment_check`
- `prepare`
- `deploy`
- `verify`
- `diagnose`
- `repair`
- `manual_review`
- `finished`

Why it matters:
- makes UI, audit logs, retries, and operator reasoning much clearer

### 6. Output limits and log summarization

Reference:
- `E:\project\claude-code\src\utils\shell\outputLimits.ts`

Claude Code assumes raw shell output must be bounded and summarized.

What we should borrow:
- raw logs stored on disk
- bounded output windows for model input
- extracted recent-error view
- summarized install/build/runtime failures

Why it matters:
- avoids context blow-up
- gives the model the useful error slice instead of megabytes of noise

## Direct Mapping To Our Backend

### A. Deployment execution context

Target files:
- `E:\project\repo-auto-deployer\backend\workers\tasks.py`
- `E:\project\repo-auto-deployer\backend\services\deployment_context.py` (new)

Add a shared `DeploymentExecutionContext` that contains:
- task metadata
- repository scan result
- repo understanding result
- selected skill
- execution plan
- environment checks
- command history
- generated artifacts
- diagnostics
- verification results

### B. Capability detection layer

Target files:
- `E:\project\repo-auto-deployer\backend\services\deployment_capabilities.py` (new)
- `E:\project\repo-auto-deployer\backend\services\execution_planner.py`
- `E:\project\repo-auto-deployer\backend\services\repo_understanding.py`

Add host capability detection for:
- OS and shell type
- Python / Node / Java / Go availability
- Docker / Compose availability
- Redis / Postgres / MySQL availability when relevant
- port availability
- background process support

Use this in planning so the model and planner reason from real host constraints.

### C. Deployment gatekeeper

Target files:
- `E:\project\repo-auto-deployer\backend\services\deployment_gatekeeper.py` (new)
- `E:\project\repo-auto-deployer\backend\services\execution_planner.py`

Add a gate layer that decides:
- `allow`
- `prepare_first`
- `deny_auto_deploy`
- `manual_review`

This should run after understanding and before command execution.

### D. Deployment session runner

Target files:
- `E:\project\repo-auto-deployer\backend\services\deployment_session_runner.py` (new)
- `E:\project\repo-auto-deployer\backend\services\deployment_executor.py`

Move command execution toward a session model with:
- step-by-step command records
- stdout/stderr capture
- per-step status
- transcript file
- recent-error ring buffer
- structured activity output for UI and audit logs

### E. Stage model cleanup

Target files:
- `E:\project\repo-auto-deployer\backend\models\task.py`
- `E:\project\repo-auto-deployer\backend\repositories\task_repository.py`
- `E:\project\repo-auto-deployer\backend\workers\tasks.py`

Formalize stage/state semantics so that deployment and repair loops have predictable transitions.

### F. Log summarization

Target files:
- `E:\project\repo-auto-deployer\backend\services\log_summarizer.py` (new)
- `E:\project\repo-auto-deployer\backend\services\deployment_session_runner.py`

Add bounded model-facing summaries for:
- dependency install failures
- build failures
- runtime startup failures
- health-check failures

## Suggested Implementation Order

### Phase 1

Build the execution foundation:
- `deployment_context.py`
- `deployment_capabilities.py`
- `deployment_gatekeeper.py`

### Phase 2

Build observable execution:
- `deployment_session_runner.py`
- upgrade `deployment_executor.py`

### Phase 3

Clean up lifecycle semantics:
- task stage/status normalization
- audit/event alignment

### Phase 4

Add repair-oriented summarization:
- `log_summarizer.py`
- richer AI diagnosis inputs

## Why This Matters For The Product Direction

Our target system is not a framework matcher.

It is an automatic deployment agent that should behave more like an engineer:

1. gather evidence
2. understand the repo
3. determine the feasible deployment path for the current environment
4. execute step-by-step
5. verify
6. diagnose and repair when something fails

Claude Code's strongest reusable idea is not any single tool.

It is the engineering discipline around:
- shared execution context
- dynamic capability control
- observable sessions
- gated execution
- bounded output

That discipline maps well to the deployment agent we want to build.
