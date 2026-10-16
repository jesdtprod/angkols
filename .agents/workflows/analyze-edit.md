---
description: Analyze affected surfaces, make focused edits, and verify uniform UI against UI DESIGN.md
---

# Analyze → Edit → Verify

## Strict requirements

- Edit the specific code blocks that need changing. Do not rewrite entire files or the codebase when a focused change is sufficient.
- When implementation is requested, directly implement the change; do not stop at a plan, recommendations, or a mockup.
- Read the repository's `AGENTS.md` and root `UI DESIGN.md` before making applicable changes. Follow their requirements while preserving existing behavior, permissions, calculations, and user changes.
- **Do not skip a single applicable design, element, page, modal, or state.** Every equivalent instance within the affected scope must follow the same shared standard.
- Minimal edits do not mean incomplete coverage. Fix a shared component once where possible, then remove or update conflicting instances so old and new designs do not coexist.
- Never use this workflow to override safety requirements or an explicit user boundary such as "no code yet," "preview only," or "do not deploy."

## 1. Analyze

1. Identify the requested outcome and exact scope. For an application-wide uniformity task, inventory every applicable surface, including admin, staff, POS, waiter, kitchen, customer/table ordering, and reports.
2. Inspect the current implementation, shared styles, renderers, event handlers, responsive rules, and existing design references before editing.
3. Identify all consumers of the element being changed, including dynamically generated and nested components.
4. Create a coverage checklist. Include buttons, dropdowns, datepickers, presets, grids, pagination, badges, modal headers/footers, skeletons, and empty/error states where applicable.
5. Identify existing unrelated work and preserve it. Do not broaden the business workflow or alter data merely to change presentation.

## 2. Edit

1. Apply the shared tokens, components, and visual patterns defined in `UI DESIGN.md`.
2. Make focused edits to the relevant code blocks. Reuse existing dependencies, typography, icons, and controls.
3. Apply equivalent changes consistently across the coverage checklist. Avoid page-specific copies, competing CSS overrides, and unnecessary inline styles.
4. Keep table headers, rows, and skeletons on the same column schema. Distribute data columns evenly, reserve suitable action width, and center icon-only row actions beneath the Action heading.
5. Use the standard modal header/body/footer, spacing, typography, validation, and responsive behavior in every affected modal.
6. Include date presets only where relevant. Use the correct conditional reset action: `Reset Filters & Date Range` when a date range exists, otherwise `Reset Filters`.
7. Remove redundant buttons without removing distinct functionality. Preserve accessible labels, keyboard operation, visible focus, and touch targets.
8. Build skeleton loading from the actual table/page structure. Keep loading, empty, error, refreshing, and populated states distinct.

## 3. Verify

1. Run relevant syntax, regression, and whitespace checks. Verify calculations and interactions when the edited UI depends on them.
2. Visually inspect the actual affected screens on desktop and mobile. A build or HTTP success alone is not visual verification.
3. Check populated, empty, filtered-empty, loading, error, validation, disabled, and modal states where applicable.
4. Check long names/references, large amounts, missing data, multiple action buttons, date boundaries, and pagination after filtering.
5. Verify date presets, reset behavior, accessible action names, modal dismissal, submission feedback, and report print/export when applicable.
6. Check every equivalent consumer for leftover styling differences. Do not verify only the example screen.
7. Mark checklist entries as `Updated`, `Verified`, or `Blocked`. State the precise reason for anything blocked or unverified.

## 4. Deliver

- Summarize what changed, the files/surfaces covered, and the checks actually performed.
- Explicitly report missing access, browser limitations, failed checks, and remaining inconsistencies.
- Do not claim full uniformity or completion while any applicable surface is skipped, blocked, or unverified.
- Do not commit, push, deploy, or change production data unless authorized under the current task and repository instructions.
