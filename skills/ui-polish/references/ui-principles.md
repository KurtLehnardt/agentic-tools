# UI Polish Principles Reference

Source: [Jakub Krehel — Details That Make Interfaces Feel Better](https://jakub.kr/writing/details-that-make-interfaces-feel-better)

Use this reference when auditing or fixing frontend code. Each principle includes the rule, why it matters, and exact implementation.

---

## 1. Balanced Text Wrapping

**Rule:** Headings and short text blocks should distribute text evenly across lines.

**Why:** Prevents orphaned single words on the last line. Creates visual balance.

**Implementation:**
```css
h1, h2, h3, .heading {
  text-wrap: balance;
}
```

**Alternative:** `text-wrap: pretty` — similar result, slightly different algorithm (optimizes last line only).

**When to apply:** Headings, card titles, hero text, modal titles. NOT long-form body text (performance cost scales with line count).

---

## 2. Concentric Border Radius

**Rule:** When nesting rounded elements, outer radius = inner radius + padding between them.

**Why:** Equal radii on nested elements creates uneven visual gaps. Concentric radii look intentional and polished.

**Formula:**
```
outer_radius = inner_radius + padding
```

**Example:**
```css
/* Inner element */
.card-content {
  border-radius: 12px;
}

/* Outer element with 8px padding */
.card {
  padding: 8px;
  border-radius: 20px; /* 12 + 8 */
}
```

**When to apply:** Cards with inner content areas, buttons inside containers, avatar badges, nested modals.

---

## 3. Contextual Icon Animations

**Rule:** Icons that appear/disappear conditionally should animate with opacity + scale + blur.

**Why:** Abrupt icon swaps feel jarring. Smooth transitions signal state changes clearly.

**Implementation (CSS):**
```css
.icon-enter {
  animation: icon-in 200ms ease-out;
}

.icon-exit {
  animation: icon-out 150ms ease-in;
}

@keyframes icon-in {
  from {
    opacity: 0;
    transform: scale(0.8);
    filter: blur(4px);
  }
}

@keyframes icon-out {
  to {
    opacity: 0;
    transform: scale(0.8);
    filter: blur(4px);
  }
}
```

**Implementation (Motion/Framer Motion):**
```jsx
<AnimatePresence>
  {showIcon && (
    <motion.div
      initial={{ opacity: 0, scale: 0.8, filter: "blur(4px)" }}
      animate={{ opacity: 1, scale: 1, filter: "blur(0px)" }}
      exit={{ opacity: 0, scale: 0.8, filter: "blur(4px)" }}
    />
  )}
</AnimatePresence>
```

**When to apply:** Status indicators, toggle icons, conditional action buttons, loading/success/error state icons.

---

## 4. Crispy Text Rendering

**Rule:** Apply grayscale antialiasing instead of default subpixel rendering.

**Why:** Subpixel rendering makes text appear heavier/blurrier, especially light-weight fonts on macOS.

**Implementation:**
```css
body, #root, .layout {
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
```

**Tailwind:** `antialiased` class on layout root.

**When to apply:** Globally on the layout root. One-time change, affects all text.

---

## 5. Tabular Numbers

**Rule:** Dynamic numeric displays should use fixed-width digits.

**Why:** Proportional digits cause numbers to shift width as they change, creating jittery layout.

**Implementation:**
```css
.timer, .counter, .price, .stat {
  font-variant-numeric: tabular-nums;
}
```

**Tailwind:** `tabular-nums` class.

**Caveat:** Some fonts (e.g., Inter) change numeral style when tabular-nums is enabled — the number shapes themselves look different. Test visually.

**When to apply:** Timers, counters, prices, statistics, table columns with numbers, any number that updates dynamically.

---

## 6. Interruptible Animations

**Rule:** User-triggered animations must use CSS transitions, not keyframes.

**Why:** CSS transitions automatically interpolate toward the latest target state. Keyframe animations run a fixed timeline and cannot retarget mid-flight. Non-interruptible animations feel broken when users act faster than the animation.

**Correct (interruptible):**
```css
.dropdown {
  transition: opacity 200ms ease, transform 200ms ease;
}
.dropdown.open {
  opacity: 1;
  transform: translateY(0);
}
.dropdown.closed {
  opacity: 0;
  transform: translateY(-8px);
}
```

**Incorrect (not interruptible):**
```css
.dropdown.open {
  animation: slideDown 200ms ease forwards;
}
/* If user closes before animation finishes, it can't retarget */
```

**When to apply:** Dropdowns, tooltips, toggles, accordions, tabs, sidebar open/close — any animation triggered by user interaction that can be reversed.

**Exception:** Staged sequences that play once (page load animations, onboarding flows) can use keyframes.

---

## 7. Staggered Enter Animations

**Rule:** Groups of entering elements should animate in with staggered delays, not all at once.

**Why:** Simultaneous entry feels abrupt. Stagger creates a natural reading flow and draws attention progressively.

**Implementation (CSS):**
```css
@keyframes enter {
  from {
    opacity: 0;
    transform: translateY(8px);
    filter: blur(5px);
  }
}

.stagger-item {
  animation: enter 400ms ease-out both;
  animation-delay: calc(var(--index) * 80ms);
}
```

**Usage in markup:**
```html
<div class="stagger-item" style="--index: 0">Title</div>
<div class="stagger-item" style="--index: 1">Description</div>
<div class="stagger-item" style="--index: 2">Actions</div>
```

**Variations:**
- **Section-level stagger:** Title, description, and actions as 3 groups (~100ms delay)
- **Word-level stagger:** Split title into word spans (~80ms delay per word)
- **Item-level stagger:** List items entering one by one (~50ms delay)

**When to apply:** Card content, modal content, page sections on load, list items, dashboard widgets.

---

## 8. Subtle Exit Animations

**Rule:** Exit animations should use reduced movement — a small fixed offset, not full travel distance.

**Why:** Exiting elements don't need attention. Full travel distance on exit competes with entering content.

**Implementation:**
```css
/* Entry: full movement */
@keyframes enter {
  from { opacity: 0; transform: translateY(16px); filter: blur(4px); }
}

/* Exit: subtle movement — fixed 12px, not full container height */
@keyframes exit {
  to { opacity: 0; transform: translateY(-12px); filter: blur(4px); }
}
```

**Motion library:**
```jsx
exit={{ opacity: 0, y: "-12px", filter: "blur(4px)" }}
```

**Rules:**
- Exit translateY: max 12px (fixed), regardless of element size
- Exit duration: shorter than enter (150ms vs 300ms)
- Always include some motion — removing animation entirely loses directional context
- Direction should match the logical flow (e.g., exiting upward if new content enters from below)

---

## 9. Optical Alignment

**Rule:** Adjust alignment by eye, not by geometry. Geometric center ≠ visual center.

**Why:** Asymmetric shapes (play icons, arrows, certain glyphs) appear off-center when geometrically centered due to uneven visual weight distribution.

**Common case — buttons with icons:**
```css
/* Icon-left button: reduce left padding */
.btn-icon-left {
  padding-left: 12px; /* instead of 16px */
  padding-right: 16px;
}

/* Play button: shift icon right */
.play-icon {
  margin-left: 2px;
}
```

**Best practice:** Fix alignment within the SVG itself (adjust viewBox or path position) rather than adding CSS offsets. SVG fixes are more portable and don't create spacing side effects.

**When to apply:** Play/forward/back icons in buttons, arrow icons, asymmetric logos, any icon that looks "off" when centered.

---

## 10. Shadows Over Borders

**Rule:** Use layered box-shadows instead of solid borders for cards and containers.

**Why:** Solid borders are fixed-color and look wrong on non-white backgrounds. Shadows use transparency, adapting to any background. Layered shadows create more realistic depth.

**Implementation — 3-layer shadow:**
```css
.card {
  box-shadow:
    0px 0px 0px 1px rgba(0, 0, 0, 0.06),
    0px 1px 2px -1px rgba(0, 0, 0, 0.06),
    0px 2px 4px 0px rgba(0, 0, 0, 0.04);
}

.card:hover {
  box-shadow:
    0px 0px 0px 1px rgba(0, 0, 0, 0.08),
    0px 1px 2px -1px rgba(0, 0, 0, 0.08),
    0px 2px 4px 0px rgba(0, 0, 0, 0.06);
  transition: box-shadow 200ms ease;
}
```

**Layer breakdown:**
1. `0px 0px 0px 1px` — thin outline (replaces border)
2. `0px 1px 2px -1px` — subtle directional shadow
3. `0px 2px 4px 0px` — soft ambient shadow

**Dark mode:** Increase opacity values or switch to lighter shadow colors.

**When to apply:** Cards, dropdown menus, modals, popovers, any container that currently uses `border: 1px solid`.

---

## 11. Image Outlines

**Rule:** Add a subtle 1px inset outline to images for definition and depth.

**Why:** Images without outlines blend into backgrounds, especially light images on light backgrounds. The outline provides consistent visual boundaries.

**Implementation:**
```css
img {
  outline: 1px solid rgba(0, 0, 0, 0.1);
  outline-offset: -1px;
}

/* Dark mode */
@media (prefers-color-scheme: dark) {
  img {
    outline-color: rgba(255, 255, 255, 0.1);
  }
}
```

**When to apply:** Content images, avatars, thumbnails, gallery images. Not decorative/background images or icons.
