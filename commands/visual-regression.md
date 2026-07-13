---
name: visual-regression
description: Implement pixel-perfect components from user-provided reference images
---

Activate the visual-regression skill to implement pixel-perfect components from user-provided reference images. Save the reference as a baseline screenshot in `e2e/visual/baselines/`, write a Playwright visual test that compares against it, and iterate through the fix → re-run → diff loop until the component matches the reference exactly. Use explicit viewports, wait for network idle and animations to settle, and verify with multiple passes before committing both the component and the baseline.
