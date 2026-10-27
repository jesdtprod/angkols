# UI Design Standard

## Mandatory instruction for Antigravity and all coding agents

Directly edit the existing application to implement this standard. Do not stop at recommendations, sample screens, or a mockup when implementation is requested.

**STRICT: Do not skip a single applicable page, component, element, or state. The entire application must use one uniform design system.** This includes admin, staff, waiter, kitchen, POS, customer/table ordering, reports, nested dialogs, and mobile views. Specialized workflows may have different layouts, but must use the same visual tokens and interaction conventions.

If a shared element changes, apply the change to every equivalent instance. Do not leave old and new designs mixed together. Do not mark the work complete while an applicable surface remains inconsistent. Identify any blocked surface explicitly instead of silently skipping it.

Preserve business logic, calculations, permissions, routes, data, and working interactions. Do not add dependencies, change authorization, or redesign unrelated workflows merely to restyle a screen.

## 1. Visual reference and implementation approach

- Use the approved Table Service screenshot as the page-header and search-spacing reference: dark navy gradient, rounded blue border, green LIVE OPERATIONS pill and date chip above the title, a small cyan line icon directly before the title, and a muted description below. Reuse the existing `dashboard-header-banner`, `dashboard-title-area`, `dashboard-eyebrow-row`, `dashboard-main-title`, and related classes; place page actions on the right and stack them on mobile. Match the banner's 20px vertical / 24px horizontal desktop padding and 14px gaps from header to search and search to content. Keep the upper and lower search gaps equal; do not add extra hero margins.

- Use the approved Product Registration & Price Management page as the visual reference: dark navy surfaces, subtle blue borders, cyan/blue accents, restrained gradients, rounded cards, and clear typography.
- Use the approved date-preset strip and centered empty-table design as the corresponding references.
- Reuse the existing font family and icon system. Do not introduce competing fonts or icon styles.
- Centralize colors, spacing, type, radius, control dimensions, shadows, and states in shared tokens and classes.
- Consolidate conflicting overrides rather than adding another layer of page-specific CSS or inline styles.
- Use reusable renderers/components for repeated table, modal, toolbar, empty-state, pagination, and skeleton patterns.
- Consistency means a shared visual language, not forcing every workflow into the same page layout.
- All matching inventory, finance, reporting, directory, Table Service, waiter, and kitchen page headers use `renderPageHeader_()` in `app.js`. Supply the existing page icon, title, description, and actions; keep action IDs and permission checks intact. Use `renderPageHeaderSkeleton_()` for their loading headers. The dashboard keeps its selected-date controls and graphs.
- Keep the page header in the top-level page slot, before search, filters, and content. Kitchen and Waiter headers must be siblings before their content shells, including during loading; never nest them inside the ordered content shell. Verify the complete page hierarchy, not just the isolated header.
- Page banners must remain below the sticky top navigation while scrolling. Keep the shared banner at stacking level 10 and its open-datepicker state at 11, below the topbar's 15. Check scrolling with the actual navigation present at desktop and mobile widths.

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
- Monetary readouts use one shared palette across matching table columns, KPI cards, dashboard amounts, table tabs, and POS summaries: sales/prices cyan, costs/COGS amber, expenses/refunds rose, gross profit green, net profit lavender, cash/collections teal, credit/due amounts orange, and balances/stock values blue. Negative monetary values override the category color with red. Keep dates, quantities, percentages, labels, and calculations unchanged. Apply through the shared amount helpers and CSS rather than individual page overrides.
- Loss, write-off and disposal amounts are red even when recorded as positive costs. Table monetary values use weight 700 to match Sales History; supporting notes such as Estimated remain weight 400. Nested price elements must inherit their monetary column's category rather than reverting loss/cost amounts to sales colors.
- Never communicate meaning through color alone. Add a text label or recognizable icon.
- Keep primary text clearly readable; do not use faint text for essential values or instructions.
- Maintain at least 4.5:1 contrast for normal text and 3:1 for large text and meaningful control boundaries.
- Use restrained shadows and gradients. Avoid unnecessary glow, animation, excessive bold text, and decorative clutter.
- Use plain-language labels, consistent capitalization, and specific action verbs.

## 4. Page composition

Use this order when the section is applicable:

1. Page header: icon, optional eyebrow, title, short description, necessary actions.
2. Relevant KPI cards.
3. Search and filtering controls, with date range alongside search in the same desktop row when present.
4. Presets and report actions, grouped with the filters where space allows.
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
- Center status headings and badges in the same column. Apply alignment from the column heading to its corresponding cells; never assume that the last column is an Action column. Shared fractional tracks must use explicit zero minimums so long content cannot give individual rows different column widths.
- Treat grouped desktop row wrappers as separate logical columns when applying alignment and amount colors. Price and stock must never share an amount color. Center stock badges below their heading: healthy stock green, low stock amber, and unavailable stock red.
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
- When a page has both search and a date range, keep search on the left and the date range on the right in one desktop toolbar row. Let search fill remaining space, keep a consistent gap between controls, and align their vertical centers and control heights (42px). Wrap on smaller screens only when needed to preserve readable controls and avoid horizontal scrolling.
- Include type and sort filters in that same toolbar group. Keep search at least 240px wide when sharing a desktop row; never let a full-width date/filter group squeeze it closed. Use shared control sizing rather than page-ID width overrides. On mobile, show full-width search above a two-column date/filter grid.
- Default to the first day of the current month through today, using the application's business timezone: Asia/Manila.
- Use the same compact preset strip: **Presets: This Month · Last 30 Days · All Time**.
- This Month means the first day of the current month through today.
- Last 30 Days means today and the preceding 29 days.
- All Time removes date restrictions; do not silently substitute an arbitrary date window.
- Synchronize preset selection and date inputs. Indicate a custom range when applicable.
- Prevent a reversed range. Apply inclusive business-date boundaries consistently.
- Keep Print PDF and Export PDF beside the report filters using shared button styles.
- All Print PDF buttons use `pdf-print-button`: a dark translucent surface, thin cyan outline, cyan icon/text, and no filled gradient. All Export PDF buttons use `pdf-export-button`: the shared blue gradient, white download icon/text, and subtle blue shadow. Both use 42px height, 10px radius, 16px icons, and an 8px icon/text gap across every page theme.
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
