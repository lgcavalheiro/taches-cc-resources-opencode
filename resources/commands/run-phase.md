---
description: Execute all remaining plans in a phase one by one until the phase is fully implemented
argument-hint: [phase-directory]
---

<objective>
Execute every unexecuted plan in phase directory `.planning/phases/$ARGUMENTS/` sequentially until the entire phase is complete.

If no $ARGUMENTS provided, auto-detect the current phase by reading `.planning/ROADMAP.md` and finding the phase with "In progress" status.

This automates the full phase execution loop: parse plan, determine strategy, execute, create summary, advance to next plan, repeat until phase done.
</objective>

<context>
Roadmap status: ! `cat .planning/ROADMAP.md 2>/dev/null`
Phase plans: ! `ls .planning/phases/$ARGUMENTS/*-PLAN.md 2>/dev/null | sort`
Phase summaries: ! `ls .planning/phases/$ARGUMENTS/*-SUMMARY.md 2>/dev/null | sort`
</context>

<process>
1. **Resolve phase directory:**
   - If `$ARGUMENTS` is provided: use `.planning/phases/$ARGUMENTS/` as the phase directory
   - If no `$ARGUMENTS`: read `.planning/ROADMAP.md`, find the phase with "In progress" status, extract its directory name (e.g. `01-foundation`)
   - If no roadmap or no in-progress phase found: error and exit with guidance

2. **Discover unexecuted plans:**
   - List all `*-PLAN.md` files in the phase directory
   - List all `*-SUMMARY.md` files in the phase directory
   - Identify plans WITHOUT a matching summary — these are unexecuted
   - If no unexecuted plans remain: inform user the phase is already complete, show summary count, and exit

3. **Phase execution loop** — for each unexecuted plan in order:

   **3a. Announce current plan:**
   ```
   ════════════════════════════════════════
   PHASE EXECUTION: Plan [X] of [Y]
   Phase: [phase-name]
   Plan: [plan-file]
   ════════════════════════════════════════
   ```

   **3b. Execute the plan using the same strategy as /run-plan:**

   Read the plan file. Extract `<objective>`, `<execution_context>`, `<context>`, `<tasks>`, `<verification>`, `<success_criteria>` sections.

   Analyze checkpoint structure. Determine routing strategy:

   **Strategy A: Fully Autonomous (no checkpoints)**
   - Spawn single subagent to execute entire plan
   - Prompt: "Execute plan at [plan_path]. This is a fully autonomous plan (no checkpoints). Read the plan for full objective, context, and tasks. Execute ALL tasks sequentially. Follow all deviation rules and authentication gate protocols from the plan's execution_context. Create SUMMARY.md in same directory as PLAN.md. Do NOT commit changes. Report: tasks completed, files modified."
   - Wait for completion

   **Strategy B: Segmented Execution (verify-only checkpoints)**
   - Parse into segments separated by checkpoints
   - If all checkpoints are checkpoint:human-verify: segment execution enabled
   - For each autonomous segment: spawn subagent with tasks range, read plan for context and deviation rules. Prompt: "Execute tasks [X-Y] from plan at [plan_path]. Read plan for full context. Do NOT create SUMMARY or commit. Report: tasks done, files modified, deviations."
   - For each checkpoint: present to user in main context, wait for response
   - After all segments: aggregate results, create SUMMARY.md

   **Strategy C: Decision-Dependent (has checkpoint:decision or checkpoint:human-action)**
   - Execute in main context
   - Read execution_context and context from plan
   - For each task: if auto, execute and track deviations; if checkpoint:*, present to user and wait
   - After all tasks: create SUMMARY.md

   **3c. Verify plan completion:**
   - Confirm SUMMARY.md was created for the plan
   - If SUMMARY.md missing: warn user, ask how to proceed (retry / skip / stop)

   **3d. Update ROADMAP.md:**
   - Increment plan completion count for the phase
   - If this was the last plan in the phase: mark phase status as "Complete", add completion date

   **3e. Report progress:**
   ```
   Plan [X] of [Y] complete.
   Summary: [path to SUMMARY.md]
   Phase progress: [X]/[Y] plans complete.
   ```

   **3f. Check for issues before continuing:**
   - If the SUMMARY.md has "Issues Encountered" that is not "None", or "Next Phase Readiness" mentions blockers:
     - Present issues to user
     - Ask: "Continue to next plan? (continue / stop / review)"
     - If user says stop: exit with progress summary
     - If user says continue: proceed to next plan

   **3g. Continue loop** — advance to next unexecuted plan and repeat from step 3a

4. **Phase completion:**
   ```
   ════════════════════════════════════════
   PHASE COMPLETE: [phase-name]
   ════════════════════════════════════════

   All [Y] plans executed successfully.
   Summaries:
   - [path to each SUMMARY.md]

   What's next?
   1. Transition to next phase
   2. Review phase accomplishments
   3. Done for now
   ```
</process>

<success_criteria>
- Every PLAN.md in the phase directory has a corresponding SUMMARY.md
- ROADMAP.md reflects phase as "Complete" with full plan count
- No plan was skipped without user acknowledgment
- All checkpoints were presented to user and resolved before continuing
- All deviations tracked in individual SUMMARY.md files
</success_criteria>
