# Windows 11 AHK Homepage Design QA

- Source visual truth: `C:\Users\uphol\AppData\Local\Temp\codex-clipboard-eb1b7a51-f671-412d-8a79-ebb5516aacf8.png`
- Implementation screenshot: `C:\Users\uphol\Documents\Autohotkey\AHKv2_LLMs\.codex-win11-qa-final.png`
- Side-by-side comparison: `C:\Users\uphol\Documents\Autohotkey\AHKv2_LLMs\.codex-win11-comparison.png`
- Viewport: 1440 × 1000 desktop
- State: AutoHotkey Automation Studio open; Window control selected; Start menu closed

## Full-view comparison evidence

The side-by-side comparison confirms the major Windows 11 signatures: the supplied dark blue folded-ribbon wallpaper, a full-width translucent taskbar attached to the bottom edge, centered app icons, right-aligned system tray and clock, dark Mica-like application material, and restrained rounded geometry. The open AHK application is an intentional product addition over the clean desktop reference.

## Focused region comparison evidence

A separate crop was not required. The raw 1440 × 1000 implementation capture preserves the title bar, 12–16 px Fluent icons, window controls, taskbar, tray, and clock at readable resolution. Those regions were inspected directly in `.codex-win11-qa-final.png`.

## Findings

- No actionable P0, P1, or P2 differences remain.
- Fonts and typography: Segoe UI Variable/Segoe UI is used for the Windows surface, with Semibold titles and regular body text. Sizes, sentence casing, and density align with Windows guidance.
- Spacing and layout rhythm: the app window uses an 8 px radius, controls use tighter 4–6 px geometry, the taskbar is flush to the viewport edge, and the five AHK controls sit directly beneath the desktop screen.
- Colors and visual tokens: navy wallpaper, near-black Mica surfaces, restrained blue selection states, subtle white separators, and green status accents match the reference and dark-mode hierarchy.
- Image quality and asset fidelity: the supplied Windows reference is used as the wallpaper at native quality. Microsoft Fluent System Icons replace approximate text glyphs for taskbar, window, system-tray, and feature controls.
- Copy and content: all visible app copy is specific to AutoHotkey v2 and the five demonstrations use real AHK concepts and syntax.

## Interaction evidence

- Text expansion button selected successfully and changed the app preview to “Turn a short trigger into finished writing.”
- Selected-state `aria-pressed` updated correctly.
- Start menu opened and closed from the taskbar.
- No browser console errors were present.

## Comparison history

### Iteration 1

- Earlier mismatch: the desktop used CSS-generated ribbon shapes, a floating rounded taskbar, non-Windows display typography, and capability controls inside the fake app.
- Fixes: replaced the wallpaper with the supplied reference asset, made the taskbar edge-to-edge, switched the Windows surface to Segoe UI, applied 8 px WinUI-style geometry and Mica layering, used Fluent icons, and moved five capability controls beneath the screen.
- Post-fix evidence: `.codex-win11-qa-final.png` and `.codex-win11-comparison.png`.

## Follow-up polish

- P3: the Start button uses the closest Fluent Apps glyph instead of Microsoft’s trademarked Windows logo.
- P3: the taskbar intentionally shows only the site’s relevant apps instead of duplicating every application in the source screenshot.

final result: passed
