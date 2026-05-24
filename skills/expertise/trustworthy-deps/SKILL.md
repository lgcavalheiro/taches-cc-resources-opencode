---
name: trustworthy-deps
description: Enforces dependency quality gates — 500+ GitHub stars, updated within past 12 months, not archived. Use before adding any new dependency to the project.
---

<objective>
Prevent unreliable, abandoned, or low-trust dependencies from entering the project. Every new dependency must prove it has community adoption (500+ stars) and active maintenance (updated within 12 months). No exceptions.
</objective>

<quick_start>
Before adding any dependency, run the check script:

```bash
bash .opencode/skills/expertise/trustworthy-deps/scripts/check-dep.sh <package-name>
```

If it prints `APPROVED` — proceed. If it prints `REJECTED` or `FAIL` — find an alternative.
</quick_start>

<essential_principles>

<gates>
<gate_1>
<name>Community Adoption</name>
<rule>500+ GitHub stars</rule>

Stars are a rough proxy for: people use it, people report bugs, people submit PRs, people write about it. A package with <500 stars has not been battle-tested at scale.

**Why 500:** Below 500, the community is too small to reliably catch edge cases, respond to breaking changes in dependencies, or provide support. The package author is essentially alone.
</gate_1>

<gate_2>
<name>Active Maintenance</name>
<rule>At least one commit or release in the past 12 months</rule>

An unmaintained package is a ticking bomb. It will break when its dependencies update, when Node.js releases a new version, or when a security vulnerability is discovered. If nobody is maintaining it, nobody will fix it.

**What counts as active:** Any commit on any branch, a release, or a responsive maintainer answering issues. We use `pushed_at` from GitHub API as the signal.
</gate_2>

<gate_3>
<name>Not Archived</name>
<rule>Repository must not be archived</rule>

Archived repos are explicitly marked as "done" by the maintainer. No further changes will happen. Ever. Do not use them.
</gate_3>
</gates>

<exceptions>
These are exempt from the gates (but still need to pass the smell test):

1. **First-party tools** — `drizzle-kit`, `next`, `react`, `typescript`. If the framework authors made it, trust it.
2. **Type definitions** — `@types/*` packages. These are community-maintained DefinitelyTyped contributions, not standalone packages.
3. **Workspace packages** — `@jobbot/*` internal packages. You own these.
4. **Transitive dependencies** — Only apply gates to packages you directly install. You don't control what your deps depend on.

If exempt, note the exemption when adding the dependency. No need to run the check script.
</exceptions>

</essential_principles>

<process>
1. **Identify the dependency** you're about to add.

2. **Check if exempt** (first-party tool, @types/*, workspace package). If yes, note exemption and proceed.

3. **Run the check script:**
   ```bash
   bash .opencode/skills/expertise/trustworthy-deps/scripts/check-dep.sh <package-name>
   ```

4. **If APPROVED** — proceed with `pnpm add`.

5. **If REJECTED** — do NOT add the dependency. Find an alternative:
   - Search npm for alternatives: `npm search <keyword>`
   - Check alternatives with the script until one passes
   - If no alternative passes, consider building it yourself

6. **Document the decision** — when adding the dep, briefly note the check result (stars, last update) in the commit message or PR description.
</process>

<success_criteria>
- Every non-exempt dependency in `package.json` has 500+ GitHub stars
- Every non-exempt dependency has been updated within the past 12 months
- No archived repositories are in the dependency tree
- `pnpm install` succeeds without patches or workarounds (see `no-messy-workarounds` skill)
</success_criteria>
