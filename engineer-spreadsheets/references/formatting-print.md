# Professional Formatting, Print, and Release

Use these rules for professional user-facing workbooks, recurring inputs and controls, formal or accessible outputs, print or PDF delivery, and controlled releases. User instructions and the governing template take precedence; the active runtime owns supported objects and visual tooling. Do not impose a fixed house style.

## Choose the output architecture

- Keep working sheets optimized for traceability and repeatable formulas. Create dedicated output, print, or accessible-data sheets when the audience does not need mechanics, the working layout is too dense, formal pagination or branding is required, or one model serves several audiences.
- Keep raw and reusable data sheets to one primary rectangular region with stable unique headers. Allow multiple presentation blocks only when their boundaries and relationship are evident.
- Match density to audience: expert working models may be compact; executive, client, public, mobile, and accessible outputs should be selective, readable, and summary-led.
- Prefer visible or grouped calculations over hidden logic. Disclose technical hidden content needed to understand, reproduce, or review an output.

## Make inputs and controls operable

- Give inputs a label and unit. For recurring or material inputs, also record the permitted type or range, source or basis, owner when relevant, and effective date when time-sensitive.
- Use redundant editable-cell cues: consistent fill or boundary, dark readable text, validation where useful, and unlocked status only when protection is intentionally used. Font color alone is insufficient.
- Test pasted and existing values; validation is not a complete integrity control. Keep validation lists maintained and show actionable input messages or errors when the platform supports them.
- Make a scenario selector show its current value and available choices, drive one authoritative scenario variable, appear on every important output, and fail visibly when invalid. Avoid unexplained `1/0` switches.
- Use protection only to reduce accidental edits. Do not describe it as confidentiality, encryption, or access control.

## Choose structures and annotations deliberately

- Use native Tables for row-growing datasets, repeated imports, filtering, calculated columns, and structured-data workflows. Use traditional ranges for fixed time-series or statement blocks where stable formula-copy patterns are easier to audit.
- Use names selectively for global assumptions, critical controls, scenario selectors, validation lists, key outputs, and print areas. Avoid mass naming, ambiguous workbook-versus-sheet scope, and names that conceal external links.
- In current Excel, use threaded Comments for collaboration and review and Notes for durable cell-specific assumptions, sources, or explanations. Other platforms may model annotations differently; inspect their actual object semantics.
- Keep material methodology, operating instructions, and limitations visible on an Overview or control sheet rather than burying them in annotations.

## Apply hierarchy and accessibility

- Use one primary readable font, a small hierarchy of sizes, a restrained semantic palette, structural borders, and whitespace before decoration. Apply fill and color for meaning, not novelty.
- Keep labels left-aligned, numeric values right-aligned, comparable precision consistent, units visible, and actual-versus-forecast status explicit.
- Pair every status color with text, symbol, border, or placement. Avoid red-only negatives and ensure meaningful charts and images have labels or alt text where supported.
- Run the target application's accessibility checker when available and inspect its findings rather than treating execution as proof. Test meaningful hyperlink text, keyboard navigation, reading order, headers, and alternative access to chart conclusions and underlying data.
- Follow the governing accessibility policy. When WCAG AA applies, target at least 4.5:1 contrast for ordinary text and 3:1 for large text and essential graphical elements.

## Engineer print and PDF output

- Remove unnecessary printed content, reorganize or split the schedule, choose orientation or paper size, and adjust margins before severe scaling.
- For a wide schedule, default to one page wide with automatic height. Force one page total only for a deliberately compact summary, scorecard, dashboard, or form.
- Define recurring print areas and repeat essential column headings. Include report or entity, period, units, page number, and controlled version or status when each page must stand alone.
- Use manual page breaks for meaningful sections and automatic pagination for uniform listings. Excel ignores manual breaks under `Fit to` page settings; when manual breaks are contractual, use compatible percentage scaling and inspect the final layout.
- For long listings, show applied filters, sort order, source and extract time, row count, control total, units, and exception status when relevant.
- Inspect every final PDF page at 100% zoom for clipping, blank or unintended pages, unreadable scaling, page order, orphaned headings or totals, repeated headers, footer consistency, grayscale meaning, hidden content, reporting date, version, and applicable accessibility or tagging requirements.
- Treat a PDF or image as visual evidence only. It does not prove formulas, hidden content, calculation state, or workbook fidelity.

## Govern controlled and issued work

- For recurring, material, regulated, or formally issued work, record the owner, reporting period, version or status, source cutoff, review evidence location, open exceptions, and relevant compatibility requirements.
- Use a change log only when changes are material or native version history is insufficient. Prefer the governing workflow or version-history system to ceremonial workbook tabs.
- Never invent preparer, reviewer, approval, risk classification, retention period, access policy, or decommissioning criteria. Use `not determined` or report the missing governance fact when it matters.
- Preserve approved workbook and issued PDF evidence only when required by the user's or organization's policy and within authorized storage. Prevent silent replacement through the governing workflow; do not create unrequested copies or exports from connected surfaces.
- For an authorized status transition, retain the approver or review evidence, artifact identity, timestamp, and explicit acceptance of any open exception in the governing workflow. A workbook label alone is not release evidence.
