---
name: no-messy-workarounds
description: Prevents hacky solutions, pnpm patches, and unstable workarounds. Enforces clean dependency management and rejects unmaintained packages. Use when adding dependencies, integrating third-party packages, or resolving package conflicts.
---

<objective>
Enforce a zero-tolerance policy on hacky solutions that create technical debt. Prevent the introduction of pnpm patches, monkey-patches, unstable 0.x adapters, and other workarounds that paper over fundamental incompatibilities. When a package fight back, replace it — don't patch it.
</objective>

<quick_start>
Before adding any dependency or working around a package issue, run the decision tree in `<red_line>` below. If you hit a red line, stop and propose an alternative.
</quick_start>

<essential_principles>

<principle_1>
<name>Red Lines — Hard Stop</name>

These are absolute prohibitions. If any apply, stop and propose a different approach:

1. **No `pnpm patch` or `patchedDependencies`** — If a package needs patching, it's the wrong package. Patching means you're maintaining fork-specific behavior that will break on upgrade, silently rot in `pnpm-workspace.yaml`, and haunt future `pnpm install` runs.

2. **No 0.x adapter packages** — If the adapter for your ORM/framework/tool is at version 0.x (e.g., `adminjs-drizzle@0.1.2`), it is not production-ready. The API will change, bugs will not be fixed, and you will be the one debugging them. Find an alternative with a stable release.

3. **No monkey-patching node_modules** — If you're modifying files in `node_modules/` at runtime or via postinstall scripts, you've chosen the wrong dependency.

4. **No forcing ESM/CJS compatibility with workarounds** — If a package doesn't properly export for your module system, it's a bug in that package. Don't add `"type": "module"` overrides, synthetic `require()` shims, or build-tool hacks to compensate.

5. **No dependency on unmaintained packages** — Check the package's GitHub: last commit >12 months ago? Open issues piling up with no response? No releases in >6 months? Find an actively maintained alternative.
</principle_1>

<principle_2>
<name>Decision Tree — When Packages Fight Back</name>

When a dependency causes integration issues (type errors, ESM conflicts, missing exports, peer dep mismatches):

```
Package causes problems?
│
├─ Is there a stable alternative?
│   ├─ YES → Switch to the alternative. Done.
│   └─ NO ↓
│
├─ Is the issue a peer dependency mismatch?
│   ├─ YES → Check if it actually breaks at runtime (not just a warning)
│   │        If it works at runtime → proceed, note the warning
│   │        If it breaks → find alternative
│   └─ NO ↓
│
├─ Is the issue in a 0.x / beta / canary package?
│   ├─ YES → You chose an unstable package. Replace it.
│   └─ NO ↓
│
├─ Can the problem be solved with a different architectural approach?
│   ├─ YES → Rethink the approach (e.g., use native tooling instead of a wrapper)
│   └─ NO ↓
│
└─ Is this a genuine bug in a stable, maintained package?
    ├─ YES → File an issue, pin to the last working version, document the pin
    └─ NO  → Re-examine your assumptions. You're probably using it wrong.
```
</principle_2>

<principle_3>
<name>Preferred Alternatives Hierarchy</name>

When replacing a problematic package, prefer in this order:

1. **Use what you already have** — Does your existing stack solve this? (e.g., Drizzle Studio instead of AdminJS, native fetch instead of axios)
2. **Use the official/first-party tool** — ORM's own studio, framework's own admin, platform's own SDK
3. **Use a well-maintained, stable alternative** — High download count, recent commits, stable version (1.0+)
4. **Build it yourself** — If no good option exists, a thin custom implementation is better than a bad dependency. You own the code, you control the bugs.
</principle_3>

<principle_4>
<name>The Smell Test</name>

If you catch yourself doing any of these, stop and reassess:

- Adding a package and immediately patching it
- Creating a `patches/` directory
- Adding `patchedDependencies` to `pnpm-workspace.yaml`
- Writing a postinstall script to "fix" a package
- Adding `// @ts-ignore` above third-party type imports
- Downgrading a package to make another package work
- Installing 3+ packages to make 1 package work
- Spending >15 minutes fighting a single dependency

These are signals that you've chosen the wrong tool. Cut your losses early.
</principle_4>

</essential_principles>

<process>
1. **Before adding any dependency**, check: is it stable (1.0+)? Is it maintained (commits in last 6 months)? Does it properly support your module system?
2. **If a dependency causes issues**, run the Decision Tree in `<principle_2>`.
3. **If you hit a Red Line**, stop. Do not proceed with the problematic approach. Propose an alternative from `<principle_3>`.
4. **Document the decision** — When you choose an alternative, briefly note why in the code or planning docs so future-you doesn't revisit the same bad option.
</process>

<success_criteria>
- Zero `patchedDependencies` in `pnpm-workspace.yaml`
- Zero `patches/` directory entries
- Zero 0.x adapter packages in `package.json` files
- Every dependency can be installed with a clean `pnpm install` with no errors
- No postinstall workarounds or module system hacks
</success_criteria>
