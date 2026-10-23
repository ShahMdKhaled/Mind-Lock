# MindLock UI/UX Design System
## Complete Color & UI Specification

> **Purpose:** This document defines the recommended visual system for the MindLock app based on the complete set of provided UI screenshots.
>
> **Design direction:** Dark + Minimal + Premium + Productivity + Digital Wellbeing + Security

---

# 1. Design Philosophy

MindLock already has a strong visual foundation:

- Deep dark background
- Purple brand accent
- Rounded cards
- Purple switches and primary buttons
- Clear section headings
- Bottom navigation with active pill
- Semantic colors for warning, success and danger

The recommendation is **not to redesign the entire UI**.

Instead, apply a consistent design system across every screen.

### Main principle

**Purple = MindLock brand / primary action**  
**Green = Success / Enabled / Healthy**  
**Yellow = Warning / Action Required**  
**Red = Error / Critical / Blocked**

This prevents every feature from looking like it has a completely different visual identity.

---

# 2. Official Color Palette

## 2.1 Core Colors

| Purpose | Hex | Usage |
|---|---|---|
| Background | `#0B0A1A` | Main app background |
| Surface/Card | `#14142A` | Normal cards |
| Elevated Surface | `#191936` | Important/elevated cards |
| Border | `#292850` | Card borders/dividers |
| Primary | `#6C63FF` | Main brand/accent |
| Primary Light | `#817AFF` | Highlight/hover/selected details |
| Success | `#35D39A` | Enabled, granted, healthy |
| Warning | `#FFB52E` | Warning, missing permission |
| Danger | `#FF4D6D` | Error, critical, blocked |
| Main Text | `#F2F1FF` | Titles and important text |
| Secondary Text | `#AAA8C7` | Descriptions/body text |
| Muted Text | `#68668A` | Disabled/inactive text |

---

# 3. Color Roles

## 3.1 Primary — MindLock Purple

### `#6C63FF`

This should be the official MindLock brand color.

Use it for:

- Active bottom navigation
- Primary buttons
- ON switches
- Selected states
- Main feature icons
- Focus timer
- Progress indicators
- Active controls
- Important links
- Primary CTA
- Reels Blocker icon
- Uninstall Protection icon
- Strict Mode icon

### Primary Light

`#817AFF`

Use for:

- Highlights
- Secondary purple elements
- Selected chart bars
- Subtle emphasis

---

# 4. Secondary / Success — Mint Green

### `#35D39A`

Use green only for positive/healthy states.

Examples:

- `Granted`
- `Blocking active`
- `Enabled`
- `Completed`
- `Healthy`
- Successful operation
- Healthy usage indicator
- Completed Study Mode

### Important

Do **not** use green as the main brand color.

Purple should remain the MindLock identity.

---

# 5. Warning — Amber

### `#FFB52E`

Use yellow/amber only when the user needs attention.

Examples:

- Permissions Required
- Missing permission
- App Time Limit warning
- Strict Mode warning
- Action Required
- Configuration incomplete

### Example

```text
Permissions Required
App features are currently limited
[ FIX NOW ]
```

Use:

- Border → `#FFB52E`
- Warning icon → `#FFB52E`
- Button → `#FFB52E`

---

# 6. Danger — Pink/Red

### `#FF4D6D`

Use red sparingly.

Use it for:

- Errors
- Critical states
- Failed operations
- Critical blocked states
- Destructive actions

## Important change

Avoid using red simply because a feature is active.

For example:

### Current

```text
Reels Blocker
Active
```

with a red border.

### Recommended

```text
Reels Blocker
Active
```

Use:

- Icon → `#6C63FF`
- Border → `#292850` or subtle `#6C63FF`
- Active → `#35D39A`

Red should communicate **danger**, not simply **active**.

---

# 7. Surface System

Use three levels of surfaces.

## Level 1 — App Background

```text
#0B0A1A
```

Used for:

- Screen background
- Empty areas
- Main page

---

## Level 2 — Normal Card

```text
#14142A
```

Used for:

- Feature cards
- Settings cards
- Permission cards
- App list cards
- Information cards

---

## Level 3 — Elevated Card

```text
#191936
```

Used for:

- Today's Usage
- Important information
- Hero sections
- Selected content
- Special panels

---

# 8. Borders

Recommended standard border:

```text
#292850
```

Use a subtle 1px border on most cards.

Do not give every card a bright colored border.

### Recommended

```text
Normal:
Border = #292850

Active:
Border = #6C63FF

Warning:
Border = #FFB52E

Critical:
Border = #FF4D6D
```

Colored borders should be reserved for meaningful states.

---

# 9. Home Screen

The Home screen is the most important screen in MindLock.

## 9.1 Header

### Greeting

Example:

```text
Good Afternoon,
```

Color:

```text
#AAA8C7
```

### Main title

```text
Stay Focused
```

Color:

```text
#F2F1FF
```

Recommended size:

```text
30–32 px
Font weight: Bold
```

---

# 10. Permissions Required Card

Keep the current concept.

### Colors

```text
Border: #FFB52E
Icon: #FFB52E
Button: #FFB52E
Text: #F2F1FF
Description: #AAA8C7
```

This is a correct use of warning color.

---

# 11. Today's Usage Card

This should remain the visual hero element of the Home screen.

## Recommended gradient

```text
Start: #6C63FF
End:   #5148D8
```

Use gradient only for major hero elements.

### Avoid

Using gradient on every card.

---

## Today's Usage Typography

```text
Today's Usage
18–20 px
SemiBold
```

Main value:

```text
0h 0m
44–52 px
Bold
```

Secondary:

```text
total screen time
15–16 px
Regular
```

---

# 12. Home Feature Cards

Current features:

- Reels Blocker
- Study Mode
- Uninstall Protection
- App Use Limit
- Strict Mode
- App Time Breaks

## Recommended system

All normal cards should use:

```text
Background: #14142A
Border: #292850
```

Icons:

```text
Primary: #6C63FF
```

Status:

```text
Active/Enabled: #35D39A
Disabled: #68668A
Warning: #FFB52E
```

### Example

```text
Reels Blocker
Active

Icon → Purple
Active → Green
Card → Dark
```

This is more consistent than making the entire card red.

---

# 13. Feature Card Color Mapping

| Feature | Icon | Active | Disabled |
|---|---|---|---|
| Reels Blocker | Purple | Green | Muted |
| Study Mode | Purple | Green | Muted |
| Uninstall Protection | Purple | Green | Muted |
| App Use Limit | Purple | Green | Muted |
| Strict Mode | Purple | Green | Muted |
| App Time Breaks | Purple | Green | Muted |

Warning state:

```text
Warning → Amber
```

Critical state:

```text
Critical → Red
```

---

# 14. Settings Screen

The current Settings/Preferences structure is strong.

## Permission status

### Granted

```text
Icon: #35D39A
Text: #35D39A
```

Example:

```text
✓ Granted
```

### Missing

Recommended:

```text
Icon: #FFB52E
Text: #FFB52E
```

Instead of making Missing look like a disabled/neutral state.

Reason:

**Missing permission requires user action.**

---

# 15. Permission Screen

Recommended hierarchy:

```text
Usage Access
✓ Granted

Accessibility Service
⚠ Missing
[ Grant ]

Display Over Other Apps
✓ Granted

Notifications
✓ Granted

Do Not Disturb
✓ Granted

Background Execution
✓ Granted
```

Use green for success and amber for action-required states.

---

# 16. Reels Blocker Screen

The current structure is good.

## Master Shield

Primary feature:

```text
Icon: #6C63FF
Switch ON: #6C63FF
Border: #6C63FF or subtle
```

## App list

Each app should use:

```text
Card: #14142A
Border: #292850
Switch ON: #6C63FF
Status: #35D39A
```

Example:

```text
Instagram
Blocking active
```

Status should be green.

---

# 17. Uninstall Protection

This screen should use a security/premium feel.

### Master Shield

```text
Purple
#6C63FF
```

### Information cards

```text
Background: #14142A
Border: #292850
Icon: #6C63FF
Title: #F2F1FF
Body: #AAA8C7
```

Do not use red unless there is an actual error or destructive action.

---

# 18. App Time Breaks

Current design is clean.

Recommended:

### Master Shield

```text
Primary: #6C63FF
```

### Healthy Habits

The leaf/health icon can use:

```text
#35D39A
```

This creates semantic meaning without changing the whole theme.

---

# 19. Study Mode

Study Mode is one of the screens where purple should dominate.

## Timer

Inactive ring:

```text
#1C1B38
```

Active ring:

```text
#6C63FF
```

Completed:

```text
#35D39A
```

## Start Focus Button

Recommended gradient:

```text
#6C63FF → #5148D8
```

Text:

```text
#FFFFFF
```

Button should be the main CTA on this screen.

---

# 20. Usage Analysis

This screen needs the most visual consistency improvement.

## Current problem

The chart uses:

```text
Red bars
Purple bars
```

without an obvious legend.

The user may not understand what red and purple represent.

---

## Recommended single-metric chart

If the chart represents only screen time:

Use one purple family.

```text
Normal bar:
#514C9A

Selected/current:
#817AFF
```

Example:

```text
Sunday    ███████
Monday    █████
Tuesday   ████████
Wednesday ██████
```

Use different colors only if the chart represents different metrics.

---

# 21. Most Used Apps

Avoid a red border around Facebook just because Facebook is the highest-used app.

High usage is not automatically an error.

Recommended:

```text
Card: #14142A
Border: #292850
App name: #F2F1FF
Category: semantic accent
Time: #AAA8C7
Percentage: #68668A
```

Red can be used for a warning label if the app has exceeded a user-defined limit.

---

# 22. Bottom Navigation

Current navigation concept is good.

## Active

```text
Icon: #6C63FF
Label: #6C63FF
Pill: #211F4A
```

## Inactive

```text
Icon: #68668A
Label: #68668A
```

Keep the active pill.

It clearly communicates the current location.

---

# 23. Switch System

## ON

```text
Track: #6C63FF
Thumb: #FFFFFF
```

## OFF

```text
Track: #1B1A30
Border: #77758F
Thumb: #77758F
```

The current white OFF border is slightly too bright.

A muted border will look more premium.

---

# 24. Typography

Recommended font:

## Inter

Use a consistent type scale.

| Element | Size | Weight |
|---|---:|---|
| Main page title | 30–32 px | Bold |
| Hero title | 30–32 px | Bold |
| Section heading | 18–20 px | SemiBold |
| Card title | 18 px | SemiBold |
| Body | 14–16 px | Regular |
| Caption | 12–13 px | Regular |
| Status | 13–14 px | Medium/SemiBold |

---

# 25. Typography Colors

## Primary text

```text
#F2F1FF
```

Use for:

- Page titles
- Feature titles
- Important values
- Main buttons

## Secondary

```text
#AAA8C7
```

Use for:

- Descriptions
- Supporting information
- Secondary values

## Muted

```text
#68668A
```

Use for:

- Disabled
- Inactive
- Less important information

---

# 26. Spacing System

Use a consistent 4px-based spacing system.

```text
4px
8px
12px
16px
20px
24px
32px
40px
```

Recommended:

```text
Screen horizontal padding: 24px
Card internal padding: 24px
Small gap: 8px
Normal gap: 16px
Section gap: 24–32px
```

Avoid random spacing values between screens.

---

# 27. Border Radius

Recommended:

```text
Large cards: 24px
Medium cards: 20px
Buttons: 16–20px
Pills: 999px
Small elements: 12px
```

Your current rounded-card language is good and should remain.

---

# 28. Icon Style

Use one consistent icon style.

Recommended:

**Outline / Rounded / Simple**

Avoid mixing:

- 3D icons
- Filled icons
- Very detailed icons
- Different stroke weights

Recommended stroke:

```text
2–2.5 px
```

Icons should generally use:

```text
#6C63FF
```

unless semantic coloring is required.

---

# 29. Semantic Color Rules

This is the most important rule in the entire design system.

```text
PURPLE
Brand
Primary
Active
Selected
Action

GREEN
Success
Enabled
Granted
Healthy
Completed

YELLOW
Warning
Missing
Attention
Action Required

RED
Error
Critical
Danger
Destructive
Blocked
```

Do not break these meanings without a strong reason.

---

# 30. Recommended Before/After

## Current

```text
Reels Blocker → Red
App Use Limit → Yellow
Strict Mode → Yellow
Study Mode → Purple
```

## Recommended

```text
Reels Blocker → Purple + Green status
App Use Limit → Purple + Green status
Strict Mode → Purple + Green status
Study Mode → Purple + Green status
```

This makes the app feel like one unified product.

---

# 31. Recommended Final Visual Hierarchy

The entire app should visually communicate:

### Level 1 — Brand

```text
Purple
#6C63FF
```

### Level 2 — State

```text
Green
#35D39A
```

### Level 3 — Attention

```text
Amber
#FFB52E
```

### Level 4 — Critical

```text
Red
#FF4D6D
```

Everything else stays dark/neutral.

---

# 32. What NOT To Change

The following parts of the current UI are already strong:

- Dark theme
- Rounded cards
- Bottom navigation
- Purple primary accent
- Today's Usage hero card
- Study Mode timer concept
- Permission status layout
- Master Shield concept
- Feature grid
- Large page titles
- Card-based settings
- Purple ON switches

Do not redesign these unnecessarily.

---

# 33. What SHOULD Be Changed

Priority order:

## Priority 1 — Color consistency

Reduce unnecessary red/yellow borders.

## Priority 2 — Chart consistency

Remove unexplained red chart bars.

## Priority 3 — Status semantics

Use:

```text
Green = Active/Enabled
Yellow = Attention
Red = Error/Critical
Purple = Brand/Action
```

## Priority 4 — OFF switch

Make the OFF switch border less bright.

## Priority 5 — Typography hierarchy

Increase contrast between:

- Main
- Secondary
- Muted

## Priority 6 — Card borders

Use neutral borders by default.

---

# 34. Final MindLock Design Tokens

```dart
class MindLockColors {
  // Background
  static const background = Color(0xFF0B0A1A);

  // Surfaces
  static const surface = Color(0xFF14142A);
  static const elevatedSurface = Color(0xFF191936);

  // Borders
  static const border = Color(0xFF292850);

  // Brand
  static const primary = Color(0xFF6C63FF);
  static const primaryLight = Color(0xFF817AFF);

  // Semantic
  static const success = Color(0xFF35D39A);
  static const warning = Color(0xFFFFB52E);
  static const danger = Color(0xFFFF4D6D);

  // Text
  static const textPrimary = Color(0xFFF2F1FF);
  static const textSecondary = Color(0xFFAAA8C7);
  static const textMuted = Color(0xFF68668A);
}
```

---

# 35. Final Recommendation

**Do not replace the current MindLock UI.**

Instead, keep the existing design and apply this design system consistently.

The final visual identity should be:

> **Deep Navy + Electric Violet + Mint Green + Amber + Controlled Red**

The most important change is:

> **Purple should represent MindLock itself. Green should represent successful/active states. Yellow should represent attention. Red should represent actual danger or error.**

This will make the entire application feel more polished, consistent, premium and production-ready.
