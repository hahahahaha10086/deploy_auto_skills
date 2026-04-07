# Deployment Execution Checklist v1

## Purpose

This checklist turns the current automatic deployment direction into concrete backend work items.

It focuses on the first execution-oriented batch after the existing AI + skill groundwork:

1. unified deployment context
2. host capability detection
3. deployment gatekeeping
4. session-based command execution

The goal of this phase is not full end-to-end deployment success for every repo.

The goal is to build the minimum execution skeleton that allows the system to:
- understand the repo
- check whether the current host can support deployment
- decide whether auto-deploy is allowed
- execute deployment as an observable session

---

## 1. Phase Goal

After this phase, the backend should be able to say:

- what it knows about the repo
- what it knows about the host environment
- whether deployment is allowed, blocked, or requires preparation
- what commands were executed
- which step failed
- what recent stderr/stdout evidence is available for diagnosis

---

## 2. Files In Scope

### New files

1. [backend/services/deployment_context.py](/E:/project/repo-auto-deployer/backend/services/deployment_context.py)
2. [backend/services/deployment_capabilities.py](/E:/project/repo-auto-deployer/backend/services/deployment_capabilities.py)
3. [backend/services/deployment_gatekeeper.py](/E:/project/repo-auto-deployer/backend/services/deployment_gatekeeper.py)
4. [backend/services/deployment_session_runner.py](/E:/project/repo-auto-deployer/backend/services/deployment_session_runner.py)
5. [backend/services/log_summarizer.py](/E:/project/repo-auto-deployer/backend/services/log_summarizer.py)

### Existing files to update

1. [backend/workers/tasks.py](/E:/project/repo-auto-deployer/backend/workers/tasks.py)
2. [backend/services/execution_planner.py](/E:/project/repo-auto-deployer/backend/services/execution_planner.py)
3. [backend/services/deployment_executor.py](/E:/project/repo-auto-deployer/backend/services/deployment_executor.py)
4. [backend/models/task.py](/E:/project/repo-auto-deployer/backend/models/task.py)
5. [backend/repositories/task_repository.py](/E:/project/repo-auto-deployer/backend/repositories/task_repository.py)

---

## 3. Module Checklist

### 3.1 `deployment_context.py`

#### Goal

Create one shared execution object for the whole deployment lifecycle.

#### Add

- [ ] `DeploymentExecutionContext`
- [ ] `CommandExecutionRecord`
- [ ] `EnvironmentCheckResult`
- [ ] `VerificationResult`
- [ ] `DiagnosticRecord`

#### Required fields

- [ ] `task_id`
- [ ] `repo_url`
- [ ] `repository_path`
- [ ] `scan`
- [ ] `understanding`
- [ ] `selected_skill`
- [ ] `execution_plan`
- [ ] `capabilities`
- [ ] `gate_decision`
- [ ] `environment_checks`
- [ ] `command_history`
- [ ] `verification_results`
- [ ] `diagnostics`
- [ ] `artifacts`
- [ ] `status_summary`

#### Add helper functions

- [ ] `build_deployment_context(...)`
- [ ] `append_command_record(...)`
- [ ] `append_diagnostic(...)`
- [ ] `append_verification(...)`
- [ ] `to_dict()`

#### Tests

- [ ] context initialization
- [ ] record append behavior
- [ ] dict serialization

---

### 3.2 `tasks.py`

#### Goal

Build and persist the deployment context in the worker pipeline.

#### Update

- [ ] create context after scan + understanding + skill + plan
- [ ] persist context snapshot into task strategy
- [ ] pass context forward instead of scattered dicts where possible

#### Add helper functions

- [ ] `_build_task_deployment_context(...)`
- [ ] `_persist_context_snapshot(...)`

#### Tests

- [ ] worker creates deployment context
- [ ] analyze-only path still persists context snapshot
- [ ] strategy contains context core fields

---

### 3.3 `deployment_capabilities.py`

#### Goal

Detect what the current host can actually support before deployment planning and execution.

#### Add core functions

- [ ] `detect_host_capabilities()`
- [ ] `detect_runtime_binaries()`
- [ ] `detect_container_support()`
- [ ] `detect_shell_environment()`
- [ ] `detect_background_process_support()`
- [ ] `check_port_available(port)`

#### Minimum output shape

- [ ] `hostOS`
- [ ] `shell`
- [ ] `python`
- [ ] `node`
- [ ] `java`
- [ ] `go`
- [ ] `docker`
- [ ] `backgroundProcessSupport`
- [ ] `portChecks`

#### Tests

- [ ] runtime binary presence/absence
- [ ] docker and compose detection
- [ ] port availability
- [ ] OS / shell identification

---

### 3.4 `execution_planner.py`

#### Goal

Make the planner environment-aware instead of repo-only.

#### Update

- [ ] accept `capabilities`
- [ ] accept `gate_decision`
- [ ] use host capabilities when choosing deploy mode
- [ ] carry runtime constraints into the final plan
- [ ] carry topology limitations for multi-process repos

#### Add helper functions

- [ ] `_derive_deploy_mode_from_capabilities(...)`
- [ ] `_derive_runtime_constraints(...)`

#### Tests

- [ ] no Docker host does not prefer container path
- [ ] multi-process project carries limitation note
- [ ] capability-aware plan fields are preserved

---

### 3.5 `deployment_gatekeeper.py`

#### Goal

Decide whether automatic deployment should proceed, prepare first, or stop.

#### Add

- [ ] `evaluate_deployment_gate(...)`

#### Output contract

- [ ] `decision`
- [ ] `reasons`
- [ ] `requiredPreparation`
- [ ] `blockedBy`
- [ ] `manualReviewReasons`

#### First batch rules

- [ ] Docker required but unavailable
- [ ] Linux-only project on Windows host
- [ ] multi-process project but only single-service executor support exists
- [ ] missing start command
- [ ] missing required env template
- [ ] port unavailable

#### Tests

- [ ] allow path
- [ ] prepare-first path
- [ ] manual-review path
- [ ] conflicting rules priority

---

### 3.6 `deployment_session_runner.py`

#### Goal

Run deployment as a structured session, not a blind command chain.

#### Add

- [ ] `run_command_step(...)`
- [ ] `run_steps(...)`
- [ ] `_truncate_output(...)`
- [ ] `_build_command_record(...)`

#### Each command step should record

- [ ] `stepName`
- [ ] `command`
- [ ] `cwd`
- [ ] `envOverrides`
- [ ] `startedAt`
- [ ] `finishedAt`
- [ ] `exitCode`
- [ ] `stdoutPreview`
- [ ] `stderrPreview`
- [ ] `status`

#### Tests

- [ ] successful command execution
- [ ] failing command execution
- [ ] output truncation
- [ ] command record correctness

---

### 3.7 `deployment_executor.py`

#### Goal

Make deployment execution context-driven and gate-aware.

#### Update

- [ ] add `execute_deployment_context(context)`
- [ ] stop execution when gate decision is not `allow`
- [ ] execute via `deployment_session_runner`
- [ ] write execution results back into context

#### Add helper functions

- [ ] `_execute_runtime_step(...)`
- [ ] `_verify_deployment_step(...)`

#### Tests

- [ ] gate denial blocks execution
- [ ] gate allow executes session runner
- [ ] execution results are persisted to context

---

### 3.8 `log_summarizer.py`

#### Goal

Prepare bounded, diagnosis-friendly output for later repair loops.

#### Add

- [ ] `summarize_install_failure(...)`
- [ ] `summarize_build_failure(...)`
- [ ] `summarize_runtime_failure(...)`
- [ ] `extract_recent_error_window(...)`

#### Tests

- [ ] pip install failure summary
- [ ] docker build failure summary
- [ ] runtime traceback summary

---

### 3.9 Task stage model cleanup

#### Goal

Align task stages and terminal semantics with a deployment engine lifecycle.

#### Files

- [backend/models/task.py](/E:/project/repo-auto-deployer/backend/models/task.py)
- [backend/repositories/task_repository.py](/E:/project/repo-auto-deployer/backend/repositories/task_repository.py)
- [backend/workers/tasks.py](/E:/project/repo-auto-deployer/backend/workers/tasks.py)

#### Add or normalize stages

- [ ] `understanding`
- [ ] `skill_selection`
- [ ] `environment_check`
- [ ] `prepare`
- [ ] `deploy`
- [ ] `verify`
- [ ] `diagnose`
- [ ] `repair`
- [ ] `manual_review`
- [ ] `finished`

#### Tests

- [ ] recoverable stage transitions
- [ ] terminal stage transitions
- [ ] audit log naming consistency

---

## 4. Recommended Build Order

1. [backend/services/deployment_context.py](/E:/project/repo-auto-deployer/backend/services/deployment_context.py)
2. [backend/services/deployment_capabilities.py](/E:/project/repo-auto-deployer/backend/services/deployment_capabilities.py)
3. [backend/services/deployment_gatekeeper.py](/E:/project/repo-auto-deployer/backend/services/deployment_gatekeeper.py)
4. [backend/workers/tasks.py](/E:/project/repo-auto-deployer/backend/workers/tasks.py)
5. [backend/services/deployment_session_runner.py](/E:/project/repo-auto-deployer/backend/services/deployment_session_runner.py)
6. [backend/services/deployment_executor.py](/E:/project/repo-auto-deployer/backend/services/deployment_executor.py)
7. [backend/services/execution_planner.py](/E:/project/repo-auto-deployer/backend/services/execution_planner.py)
8. [backend/services/log_summarizer.py](/E:/project/repo-auto-deployer/backend/services/log_summarizer.py)

---

## 5. Acceptance Criteria

After this checklist is completed:

- [ ] the worker builds a unified deployment context
- [ ] host capability detection exists and is test-covered
- [ ] deployment gate decisions exist before execution
- [ ] deployment commands execute as observable session steps
- [ ] recent stderr/stdout evidence is retained for diagnosis
- [ ] multi-process repos such as `LuaN1aoAgent` can be classified as deployable, blocked, or partial-auto for explicit reasons

This phase is successful when the system can explain not just what repo it found, but whether the current host can deploy it and where execution failed.
