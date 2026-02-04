---
name: iterate-plan
description: Iteratively refines a plan using fresh subagents until stable. Spawns planning agents in a loop, checking for changes via git diff.
allowed-tools: Read, Bash, Task
---

# Iterative Planning Orchestrator

Orchestrates iterative plan refinement using fresh subagents to avoid context rot.

## Usage

```
/iterate-plan [task-file] [plan-file] [--max-iterations N]
```

**Arguments (from $ARGUMENTS):**
- `task-file` - Path to the high-level task/prompt file (default: `task.md`)
- `plan-file` - Path to the plan file (default: `plan.md`)
- `--max-iterations` - Maximum iterations (default: 5)

## Execution

Execute this loop:

```
iteration = 0
max_iterations = parse from args or 5
task_file = parse from args or "task.md"
plan_file = parse from args or "plan.md"

1. Read task_file content
2. If task_file doesn't exist, error and exit

LOOP:
3. iteration += 1
4. If iteration > max_iterations: exit with "Max iterations reached"

5. Read plan_file content (empty string if doesn't exist)

6. Use Task tool to spawn a fresh general-purpose subagent with this prompt:
   """
   You are a technical planner. Your job is to create or refine an implementation plan.

   ## Task/Requirements
   <task>
   {content of task_file}
   </task>

   ## Current Plan
   <plan>
   {content of plan_file, or "No plan exists yet. Create one."}
   </plan>

   ## Instructions
   - If no plan exists: Create a detailed implementation plan
   - If plan exists: Review critically and improve if needed
   - If you feel the need, use WebSearch to research best practices, APIs, or technologies
   - Be specific and actionable - vague steps are not helpful
   - Write the result to: {plan_file}

   ## Plan Structure
   Use this structure:
   - Overview (1-2 sentences)
   - Requirements (numbered list)
   - Implementation Steps (phased, with clear actions)
   - Dependencies
   - Risks & Mitigations
   - Success Criteria
   - Open Questions

   If the plan is already complete and correct, you may leave it unchanged.
   """

7. After subagent completes, run: git diff --quiet {plan_file}
   - If exit code 0 (no changes): Plan is stable. Exit loop with success.
   - If exit code 1 (changes exist):
     - Run: git add {plan_file} && git commit -m "Refine plan (iteration {iteration})"
     - Continue to step 3

END LOOP
```

## Output

After loop completes, report:
- Number of iterations
- Whether stable or max iterations reached
- Path to final plan
