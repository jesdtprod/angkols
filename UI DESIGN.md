# UI Design Standard

## Mandatory instruction for Antigravity and all coding agents

Directly edit the existing application to implement this standard. Do not stop at recommendations, sample screens, or a mockup when implementation is requested.

**STRICT: Do not skip a single applicable page, component, element, or state. The entire application must use one uniform design system.** This includes admin, staff, waiter, kitchen, POS, customer/table ordering, reports, nested dialogs, and mobile views. Specialized workflows may have different layouts, but must use the same visual tokens and interaction conventions.

If a shared element changes, apply the change to every equivalent instance. Do not leave old and new designs mixed together. Do not mark the work complete while an applicable surface remains inconsistent. Identify any blocked surface explicitly instead of silently skipping it.

Preserve business logic, calculations, permissions, routes, data, and working interactions. Do not add dependencies, change authorization, or redesign unrelated workflows merely to restyle a screen.

## 1. Visual reference and implementation approach

- Use the approved Product Registration & Price Management page as the visual reference: dark navy surfaces, subtle blue borders, cyan/blue accents, restrained gradients, rounded cards, and clear typography.
- Use the approved date-preset strip and centered empty-table design as the corresponding references.
- Reuse the existing font family and icon system. Do not introduce competing fonts or icon styles.
- Centralize colors, spacing, type, radius, control dimensions, shadows, and states in shared tokens and classes.
- Consolidate conflicting overrides rather than adding another layer of page-specific CSS or inline styles.
- Use reusable renderers/components for repeated table, modal, toolbar, empty-state, pagination, and skeleton patterns.
- Consistency means a shared visual language, not forcing every workflow into the same page layout.

## 2. Design tokens

Use one shared scale throughout the application:

| Property | Standard |
| --- | --- |
| Spacing | 4, 8, 12, 16, 24, 32px |
| Section separation | 16–24px |
| Page/card/modal padding | 24px desktop; 16px mobile |
| Page title | 20–24px; weight 700 |
| Section/modal title | 18–20px; weight 700 |
| Body and input text | 13–14px; weight 400–500 |
| Button and important cell text | 13–14px; weight 600–700 |
| Secondary text | 12px; weight 400–500 |
| Table heading | 11–12px; weight 700; uppercase |
| Body line height | Approximately 1.45–1.6 |
| Control height | 40–44px; touch targets at least 44px |
| Control radius | 10px |
| Card/modal radius | 14–16px |
| Icons | 18–20px; consistent stroke weight |
| Table cell padding | 12–16px vertical; 16–18px horizontal |

Use comfortable spacing, not excessive empty areas or compressed controls. Allow browser zoom and user text scaling. Do not disable zoom to make a layout fit.

## 3. Color, hierarchy, and readability

- Separate page background, raised panels, inputs, and hover states using subtle surface differences.
- Use blue/cyan for primary actions and information; green for success; amber for warning; red for destructive actions and errors.
- Never communicate meaning through color alone. Add a text label or recognizable icon.
- Keep primary text clearly readable; do not use faint text for essential values or instructions.
- Maintain at least 4.5:1 contrast for normal text and 3:1 for large text and meaningful control boundaries.
- Use restrained shadows and gradients. Avoid unnecessary glow, animation, excessive bold text, and decorative clutter.
- Use plain-language labels, consistent capitalization, and specific action verbs.

## 4. Page composition

Use this order when the section is applicable:

1. Page header: icon, optional eyebrow, title, short description, necessary actions.
2. Relevant KPI cards.
3. Search and filtering controls.
4. Date range, presets, and report actions.
5. Table or task-specific content.
6. Pagination/footer.

- Render only sections that the page actually needs. Do not add irrelevant KPIs, presets, search fields, or actions.
- Keep one clear primary action per task area. Secondary actions must have a distinct purpose.
- Do not repeat the same action in the header, toolbar, empty state, and footer.
- Keep related controls grouped, consistently aligned, and in a predictable order.
- Maintain comparable content widths and page gutters across equivalent screens.

## 5. Buttons, inputs, dropdowns, and badges

- Use shared primary, secondary, destructive, and icon-button variants with consistent dimensions.
- Define default, hover, focus-visible, active, disabled, and pending states for every interactive component.
- During submission, prevent duplicate actions and show clear progress without moving surrounding content.
- All row action buttons must be icon-only. Provide a specific tooltip and accessible label, such as "Edit stock-in record" rather than just "Action".
- Page actions and modal submission buttons retain readable text labels; the icon-only rule applies to row actions, not every button.
- Use persistent field labels. Placeholders supplement labels; they do not replace them.
- Place validation messages beside the affected field and preserve the user's entered values after an error.
- Use the same dropdown and datepicker styling everywhere, including controls added dynamically.
- Custom controls must support keyboard use, visible focus, correct roles, and expanded/selected states.
- Use one compact badge style with consistent height, padding, radius, text size, and semantic colors.

## 6. Grid tables and column content

- Header, populated rows, and skeleton rows must use exactly the same column definition.
- Distribute ordinary data columns equally across the available width. Reserve a compact, consistent width for Action based on its button count.
- Any necessary exception for long content must be defined in a shared table schema and applied identically to its header, rows, and skeleton—not as an isolated inline override.
- Center the Action heading and all action icons beneath it. Keep action-button gaps consistent.
- Left-align text. Right-align money and numerical amounts, including their headings. Use tabular numerals.
- Keep quantities, currency, and dates consistently formatted. Do not wrap a currency label separately from its amount.
- Place supporting information directly beneath its primary value using consistent spacing and secondary text.
- A cell's content and mobile label must match its column heading. Do not put notes under a heading for status or timestamps under an unrelated heading.
- Use real recorded values. Distinguish zero, unavailable data, not counted, and pending data; do not substitute a misleading zero.
- Allow long names and references to wrap safely. Avoid overlapping cells, clipped actions, and broken amounts.
- Use consistent row separators, hover treatment, row height, and vertical alignment.
- Use semantic table markup where practical. Grid-based tables must retain accessible header/cell relationships.

### Pagination

- Show a consistent footer with the visible row range and filtered record count.
- Use the same previous/next and page-number controls throughout the app.
- Reset or clamp the page when filters change so a valid result does not appear empty.
- Do not display a misleading "1–0" range for an empty result.

## 7. Date ranges and presets

- Display date controls only where date filtering is meaningful.
- Default to the first day of the current month through today, using the application's business timezone: Asia/Manila.
- Use the same compact preset strip: **Presets: This Month · Last 30 Days · All Time**.
- This Month means the first day of the current month through today.
- Last 30 Days means today and the preceding 29 days.
- All Time removes date restrictions; do not silently substitute an arbitrary date window.
- Synchronize preset selection and date inputs. Indicate a custom range when applicable.
- Prevent a reversed range. Apply inclusive business-date boundaries consistently.
- Keep Print PDF and Export PDF beside the report filters using shared button styles.
- Printed and exported reports must use the current filters and the same figures as the displayed report.

## 8. Empty, error, and refreshing states

### Empty table

Keep the table header visible. Center the following inside the table body:

1. Relevant icon in the standard icon container.
2. Specific title, for example "No bank transactions found".
3. A short explanation.
4. One reset action, only when filters are active.

For a page with date-range controls, use **Reset Filters & Date Range**. Otherwise use **Reset Filters**.

- Reset search, dropdown/chip filters, pagination, and any date range to its standard default.
- If there are genuinely no records and no active filters, explain that no records exist yet. Do not show an ineffective reset button.
- Do not duplicate an existing header creation button inside the empty state.
- Do not show fake pagination or zero-value summary results while data is loading.

### Error and stale data

- Loading failure is not an empty dataset. Show a clear error with an appropriate retry action.
- If retaining previously loaded data, clearly label it as the last successful update and indicate refreshing or connection failure.
- Do not hide a failed save behind a success message or discard the user's input.

## 9. Standard modal anatomy

Every modal must use the same header and footer design, including nested and dynamically created modals.

- Header: shared icon badge, optional eyebrow, title, concise description, and icon-only close button.
- Use consistent padding and a subtle divider between header and body.
- Body: shared form controls, label spacing, validation, and field-group gaps.
- Use equal-width form columns when appropriate; long references, descriptions, and notes use full width.
- Footer: shared divider and padding; Cancel followed by the primary action, right-aligned on desktop.
- Do not duplicate footer submission actions in the body.
- Keep long modal bodies scrollable and the header/footer reachable. Do not let content extend beyond the viewport.
- Stack fields and actions consistently on small screens; ensure sufficient touch targets.
- Provide an accessible dialog name, initial focus, focus containment, and focus restoration after closing.
- Support Escape and backdrop closing when safe. Protect unsaved changes where the workflow requires it.
- Destructive confirmations must clearly describe the target and consequences and default to a safe choice.

## 10. Structure-based skeleton loading

Build skeletons from the actual page and table schema, not a generic loading rectangle.

- Match the real header, KPIs, toolbar, columns, alignment, padding, and approximate row height.
- Use image placeholders only in columns that contain images.
- Match primary/secondary text stacks, badges, amounts, and centered action-icon groups.
- Use a small representative number of rows and reserve stable space to minimize layout shifts.
- Use subtle animation and honor `prefers-reduced-motion`.
- Mark the region busy for assistive technology; decorative skeletons must not be announced as real content.
- Never show "No records found" while a request is pending.
- Keep loading, empty, error, refreshing, and populated states distinct.
- Prevent stale requests from overwriting newer filters, branches, accounts, or views.

## 11. Responsive and accessible interaction

- Verify desktop, tablet, and mobile—not just one screenshot size.
- Preserve all data and actions on small screens. Use a consistent labeled-card pattern or a deliberately scrollable table for dense comparisons.
- Do not shrink text to unreadable sizes, hide necessary actions, or force the entire page to scroll horizontally.
- Ensure keyboard operation, visible focus, accessible names, and logical tab order.
- Make tooltips supplementary; essential instructions must remain available without hover.
- Respect reduced motion and avoid flashing effects.
- Keep status changes and errors understandable to screen-reader users.

## 12. Strict implementation and acceptance checklist

Before editing, inventory every page, table, toolbar, button variant, dropdown, datepicker, badge, modal, pagination footer, and loading/empty/error state. Include role-specific, hidden, nested, and dynamically rendered surfaces.

Maintain a coverage checklist with each surface marked **Updated**, **Verified**, or **Blocked**. A blocked or unverified surface is not complete. Do not silently omit anything.

- [ ] Shared tokens and components replace conflicting one-off designs.
- [ ] Every applicable page follows the same visual standard.
- [ ] Every table header, row, and skeleton uses the same column structure.
- [ ] All row actions are icon-only, accessible, and centered under Action.
- [ ] Relevant date ranges and presets work consistently.
- [ ] Empty tables use the correct conditional reset wording and behavior.
- [ ] No redundant action buttons remain.
- [ ] All modal headers and footers follow the standard.
- [ ] Spacing, typography, borders, padding, and alignment are uniform.
- [ ] Long content, large amounts, missing values, and multiple actions remain readable.
- [ ] Populated, empty, filtered-empty, loading, refreshing, error, validation, and disabled states are checked.
- [ ] Desktop and mobile layouts are visually verified.
- [ ] Permissions, business logic, data, and existing workflows are preserved.
- [ ] Relevant automated checks pass; print/export behavior is verified where applicable.

**Completion rule:** Do not claim the entire application is uniform based on one updated page, a successful build, or syntax checks. Report the files changed, surfaces covered, actual verification performed, and every remaining blocker. No skipped design is acceptable under a claim of completion.
