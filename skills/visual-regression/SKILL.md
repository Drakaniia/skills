---
name: visual-regression
description: Use when a user provides a reference image (screenshot, Figma export, mockup) and wants a component implemented or fixed to match it exactly — pixel-perfect visual alignment from a design spec.
license: Apache-2.0
compatibility: OpenCode >= 1.0, Claude Code >= 2.0, Codex CLI, Cursor, Gemini CLI
allowed-tools:
  - read
  - grep
  - glob
  - write
  - edit
  - bash
metadata:
  language: language-agnostic
  tags: visual-regression, pixel-perfect, testing, playwright, visual-testing, e2e-testing, component-testing
---

# Visual Regression — Reference-to-Test Workflow

Implement pixel-perfect components from user-provided reference images using Playwright screenshot comparison.

## Core Principles

### 1. Reference as Ground Truth

The user's provided image (PNG, WebP, JPG) is the single source of truth for what the component must look like. No verbal description or spec file can substitute for pixel-level comparison.

### 2. Iterate via Diff

Visual alignment is achieved through a tight loop: fix → run test → inspect diff → fix again. The diff image (red = mismatched pixels) is your primary diagnostic tool — not manual eyeballing.

### 3. Test Before Polish

Write the visual test **first** (which fails by design), then fix the component to make it pass. This ensures every change is driven by a measurable comparison, not guesswork.

### 4. Baseline Is Immutable

Once saved, the baseline reference image is never modified by the test framework. If the reference is wrong, replace it with a corrected one — don't adjust thresholds to mask mismatches.

### 5. Antialiasing !== Defect

Slight pixel differences from subpixel rendering, font smoothing, and GPU-accelerated compositing are expected across environments. Use thresholds for tolerance, not for accepting real visual bugs.

## When to Use

- User provides a reference image (screenshot, Figma export, mockup) and wants a component to match it exactly
- User says "make this component match this image" or "pixel-perfect implementation"
- You need to verify a component's visual fidelity against a design spec
- A UI component looks close to the design but subtle spacing/color/sizing differences exist
- You're implementing a design system component from visual specs

**Do NOT use when:**

- No reference image exists (use standard unit/integration tests instead)
- The reference is a wireframe or low-fidelity mockup with intentional flexibility
- Testing is purely functional/logical without visual concerns
- The component is text-heavy and content-driven (visual comparison adds little value)

## Workflow Summary

```
User provides image → save as baseline → write test → run → fail → fix → re-run → pass
```

## Step-by-Step

### 1. Receive Reference Image

The user provides a reference image (PNG, WebP, JPG). This is the **ground truth** — what the component _must_ look like.

### 2. Save the Baseline

Place the reference image as the baseline screenshot:

```
e2e/visual/baselines/<component-name>.png
```

**If the directory doesn't exist, create it.**

The baseline IS the user's reference image — not a Playwright-generated screenshot. When the test runs, Playwright compares the live render against this image.

### 3. Identify the Target Component

Figure out which component/page the reference depicts:

- Ask the user if unclear: "Which component should match this image?"
- If the reference matches an existing component, note its file path
- If it's a new component, plan accordingly

### 4. Write the Visual Test

Create a test file at:

```
e2e/visual/<component-name>.spec.ts
```

Test structure:

```typescript
import { test, expect } from "@playwright/test";

test.describe("<Component Name> — Visual", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await page.waitForLoadState("networkidle");
    // Wait for any CSS animations or transitions to settle
    await page.waitForTimeout(1500);
  });

  test("matches reference image", async ({ page }) => {
    const component = page.locator("<selector>");
    await expect(component).toBeVisible();

    // Compare against the user-provided reference
    await expect(component).toHaveScreenshot(
      "baselines/<component-name>.png", // relative to test dir
      { threshold: 0.02, maxDiffPixels: 50 },
    );
  });
});
```

**Important:** The `baselines/` path is relative to the test file location. Use the full relative path from `e2e/visual/` to the baseline.

**Test runner note:** Replace `bun` with your project's package manager (`npm`, `pnpm`, `yarn`, `bun`) throughout.

### 5. First Run — Expect Failure

```bash
bun test:visual
```

The first run will likely fail because:

- The live component doesn't match the reference yet
- Selector might need adjustment
- Animations/states might differ

**Read the diff output.** Playwright generates a diff image showing exactly which pixels differ — use this to identify what's wrong.

### 6. Iterate: Fix → Re-run → Diff

Loop until pass:

1. Check the diff image (red = mismatched pixels)
2. Identify what's off: spacing, color, size, font, position, missing element
3. Fix the component
4. Re-run: `bun test:visual`
5. Repeat until pass

**Common fixes:**

- CSS margin/padding mismatches
- Wrong font size or weight
- Missing border-radius or shadows
- Wrong color values
- Element not rendered at all
- Layout shifted due to missing content

### 7. Verify Pass

```bash
bun test:visual
```

All tests green. Output shows:

```
✓ e2e/visual/<component>.spec.ts (1 test)
```

### 8. Commit

Commit both:

- The component changes (fixes to match reference)
- The baseline image (it's now the official reference)
- The test file

## Directory Structure

```
e2e/
├── visual/
│   ├── baselines/          # User-provided reference images
│   │   ├── dock-perfect.png
│   │   ├── topbar-perfect.png
│   │   └── ...
│   ├── desktop.spec.ts     # Visual tests
│   └── README.md
├── playwright.config.ts
```

## Edge Cases

| Situation                                                          | Handling                                                                                                                                                                       |
| ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Reference image uses different color space (CMYK vs sRGB)**      | Convert reference to sRGB before saving as baseline. Browsers render in sRGB by default.                                                                                       |
| **Font rendering differs between OS (macOS vs Windows)**           | Use font stacks that specify web-safe fallbacks. Consider running tests in a Docker container for consistent rendering.                                                        |
| **Component depends on API data that's unavailable in test**       | Mock the API response in `beforeEach` or use Playwright's route interception. The component must render with test data.                                                        |
| **Reference image is full-page, not a component**                  | Use `page.screenshot()` instead of a locator, or clip to a specific region with `clip: { x, y, width, height }`.                                                               |
| **Animations cause intermittent mismatches**                       | Add `waitForTimeout` after navigation. For CSS transitions, wait for the `transitionend` event or use `page.waitForFunction(() => !document.querySelector('.animating'))`.     |
| **Reference image has different dimensions than component**        | Update the reference to match the viewport/component dimensions, or set a fixed viewport in the test config.                                                                   |
| **Component is responsive and renders differently at breakpoints** | Set the viewport explicitly in the test (`page.setViewportSize({ width, height })`) and name baselines per breakpoint (e.g., `component-desktop.png`, `component-mobile.png`). |
| **Baseline not found error**                                       | Verify the path is relative to the test file location, not the project root. Check file extension matches exactly (.png, .webp).                                               |
| **Test passes but component looks wrong visually**                 | The `maxDiffPixels` threshold is too high. Reduce it until real visual defects are caught.                                                                                     |
| **Everything fails (entire page mismatched)**                      | Viewport mismatch is the most likely cause. Set `page.setViewportSize()` explicitly in `beforeEach`.                                                                           |
| **User provides the reference after component is already built**   | Skip the first-run failure assumption. Start by writing the test, inspect the diff, then fix specific mismatches.                                                              |

## Troubleshooting

| Problem                       | Likely Cause               | Fix                                       |
| ----------------------------- | -------------------------- | ----------------------------------------- |
| Test passes but looks wrong   | Threshold too high         | Reduce `maxDiffPixels`                    |
| Test fails everywhere         | Antialiasing differences   | Increase threshold to 0.05                |
| Selector finds nothing        | Component not rendered yet | Add `waitForTimeout` or `waitForSelector` |
| Diff shows whole page shifted | Viewport mismatch          | Use `clip` or fixed viewport in test      |
| Baseline not found            | Wrong path                 | Make sure path is relative to test file   |
| Colors slightly off           | Color space differences    | Check if reference uses sRGB              |

## Interaction with Other Skills

| Skill                             | This skill adds                                                                                                                                                                                                                               |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **folder-architecture**           | Handles **file placement** — where tests (e2e/visual/) and baselines (e2e/visual/baselines/) live in the project structure                                                                                                                    |
| **audit-codebase**                | Visual regression tests are small (<100 lines each). If a test file exceeds 400 lines, it's a signal the component is doing too much or the test needs splitting.                                                                             |
| **code-design**                   | The test iteration loop (fix → re-run → diff) benefits from clean, single-responsibility component code. Pure rendering logic is easier to fix pixel-by-pixel than mixed-concern components with embedded data fetching and state management. |
| **implement-folder-architecture** | When migrating project structure, visual test paths (`e2e/visual/`) and baseline paths must be updated along with source code.                                                                                                                |

**Workflow integration:**

```
folder-architecture
  │
  ├─ Ensures e2e/visual/ and baselines/ directories exist
  ├─ Prevents test files from being misplaced
  └─ Keeps baselines organized by component
        │
        ▼
visual-regression (this skill)
  │
  ├─ Writes the test against the reference
  ├─ Guides the fix → re-run → diff loop
  └─ Verifies pixel-perfect alignment
        │
        ▼
code-design
  │
  ├─ Ensures the component being fixed has clean, testable functions
  ├─ Applies after visual alignment to refactor messy code
  └─ Guarantees the component is maintainable, not just visually correct
```

## Verification

Before marking complete:

- [ ] Baseline image saved to `e2e/visual/baselines/`
- [ ] Test compares against `baselines/<name>.png` (not auto-generated snapshot)
- [ ] Test passes against the fixed component
- [ ] Diff output reviewed (no unexpected differences)
- [ ] Component rendering matches reference visually

## Execution Checklist

### Pre-Test

- [ ] Received reference image from user (PNG, WebP, or JPG)
- [ ] Saved baseline to `e2e/visual/baselines/<component>.png`
- [ ] Identified target component (asked user if unclear)
- [ ] Confirmed `@playwright/test` is installed in the project
- [ ] Confirmed `e2e/visual/` directory exists (created if not)

### Test Creation

- [ ] Wrote visual test file at `e2e/visual/<component>.spec.ts`
- [ ] Test uses `page.locator("<selector>")` to isolate the component
- [ ] Test uses `toHaveScreenshot` with the correct baseline path
- [ ] Test uses explicit viewport size if component is responsive
- [ ] Test includes `waitForLoadState("networkidle")`
- [ ] Test includes sufficient wait for animations to settle

### Iteration Loop

- [ ] First run completed (expected to fail on initial test)
- [ ] Diff image reviewed — mismatches identified
- [ ] Component fixed for each mismatch type (spacing, color, size, missing elements)
- [ ] Re-ran test after each fix
- [ ] All mismatches resolved (test passes)

### Final Verification

- [ ] Test passes consistently (run 2-3 times to rule out flakiness)
- [ ] Component visually matches reference image
- [ ] Both component changes and test files are ready to commit
- [ ] Baseline image is committed as the official reference
