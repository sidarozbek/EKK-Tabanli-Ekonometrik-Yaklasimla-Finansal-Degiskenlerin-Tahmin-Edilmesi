---
name: Econometric Precision
colors:
  surface: '#f7f9fb'
  surface-dim: '#d8dadc'
  surface-bright: '#f7f9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f6'
  surface-container: '#eceef0'
  surface-container-high: '#e6e8ea'
  surface-container-highest: '#e0e3e5'
  on-surface: '#191c1e'
  on-surface-variant: '#45464d'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eff1f3'
  outline: '#76777d'
  outline-variant: '#c6c6cd'
  surface-tint: '#565e74'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#131b2e'
  on-primary-container: '#7c839b'
  inverse-primary: '#bec6e0'
  secondary: '#b51630'
  on-secondary: '#ffffff'
  secondary-container: '#d93446'
  on-secondary-container: '#fffbff'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#001d31'
  on-tertiary-container: '#188ace'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dae2fd'
  primary-fixed-dim: '#bec6e0'
  on-primary-fixed: '#131b2e'
  on-primary-fixed-variant: '#3f465c'
  secondary-fixed: '#ffdad9'
  secondary-fixed-dim: '#ffb3b3'
  on-secondary-fixed: '#400009'
  on-secondary-fixed-variant: '#920021'
  tertiary-fixed: '#cce5ff'
  tertiary-fixed-dim: '#93ccff'
  on-tertiary-fixed: '#001d31'
  on-tertiary-fixed-variant: '#004b73'
  background: '#f7f9fb'
  on-background: '#191c1e'
  surface-variant: '#e0e3e5'
typography:
  display-lg:
    fontFamily: Geist
    fontSize: 2.25rem
    fontWeight: '600'
    lineHeight: 2.75rem
    letterSpacing: -0.025em
  headline-lg:
    fontFamily: Geist
    fontSize: 1.75rem
    fontWeight: '600'
    lineHeight: 2.25rem
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Geist
    fontSize: 1.375rem
    fontWeight: '600'
    lineHeight: 1.75rem
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Geist
    fontSize: 1.25rem
    fontWeight: '600'
    lineHeight: 1.75rem
    letterSpacing: -0.015em
  body-lg:
    fontFamily: Inter
    fontSize: 1rem
    fontWeight: '400'
    lineHeight: 1.5rem
    letterSpacing: -0.011em
  body-md:
    fontFamily: Inter
    fontSize: 0.875rem
    fontWeight: '400'
    lineHeight: 1.25rem
    letterSpacing: -0.006em
  body-sm:
    fontFamily: Inter
    fontSize: 0.75rem
    fontWeight: '400'
    lineHeight: 1rem
    letterSpacing: 0em
  code-stat-md:
    fontFamily: JetBrains Mono
    fontSize: 0.875rem
    fontWeight: '500'
    lineHeight: 1.25rem
    letterSpacing: -0.02em
  code-stat-sm:
    fontFamily: JetBrains Mono
    fontSize: 0.75rem
    fontWeight: '500'
    lineHeight: 1rem
    letterSpacing: 0em
  label-caps:
    fontFamily: Inter
    fontSize: 0.6875rem
    fontWeight: '600'
    lineHeight: 0.875rem
    letterSpacing: 0.06em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 0.75rem
  gutter-desktop: 1rem
  margin: 1rem
  margin-desktop: 1.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
---

## Brand & Style

This design system is engineered for quantitative macroeconomists, central bank research units, and financial econometricians who require rigorous analytical clarity. Inspired by the meticulous publication aesthetics of Quarto, the interactive state management of R Shiny (`bslib`), and the mission-critical information density of Bloomberg terminals, the interface prioritizes immediate tabular legibility, scientific trust, and high-throughput data inspection.

The visual style merges Modern Analytical Minimalism with Institutional Rigor:
- **Zero Decorative Fluff:** Every stroke, rule, and fill conveys structural or statistical significance.
- **Tabular Authority:** Uncompromising alignment, tabular numeral enforcement, and high-density layouts accommodate complex multi-model comparison matrices without spatial waste.
- **Micro-Contrast Accents:** Restrained monochrome surfaces punctuated by decisive fiscal crimson, data-stream azure, and econometric confidence emeralds to immediately separate target signals from background noise.

## Colors

The palette establishes an institutional, data-first environment using calibrated high-contrast scales:

- **Primary Canvas & Chrome (`#0F172A` / Slate 900):** Serves as deep ink text, primary buttons, critical data anchors, and dense navigational side rails. Ensures uncompromising contrast ratios (exceeding WCAG AAA standards) against light panels.
- **Institutional Accent (`#C22238` / Central Crimson):** An authoritative deep burgundy-crimson reserved for active macro-policy alerts, structural break flags, negative variance/downside risks, and critical parameter cutoffs.
- **Technical Secondary (`#0284C7` / Data Azure):** Encodes primary forecast projections, interactive chart crosshairs, regression fits, and focused selection states.
- **Statistical Emerald (`#059669`):** Reserved strictly for positive yields, confidence band coverage validations, and out-of-sample forecast accuracy gains.
- **Surface Foundations:**
  - Base Background: `#F8FAFC` (Slate 50) creates a soft, non-glare foundation for extended research sessions.
  - Card & Container Surfaces: `#FFFFFF` (Crisp White) provides stark separation for complex vector graphs and data grids.
  - Tabular Rules & Structural Dividers: `#E2E8F0` (Slate 200) renders razor-sharp micro-borders.
  - Subdued Metadata: `#64748B` (Slate 500) for standard errors, sample sizes ($N$), and degree-of-freedom indicators.

## Typography

The typographic hierarchy enforces immediate distinction between natural language exposition, analytical metric headers, and technical parameter readouts:

- **Geist (Headlines & Section Anchors):** Provides cold, contemporary geometric authority with tight kerning. It roots analytical dashboard modules, page headers, and parameter drawer titles.
- **Inter (Expository Text & UI Controls):** Configured with mandatory `font-feature-settings: "cv02", "cv03", "cv04", "cv11", "tnum"` to enable tabular figures by default across all standard UI controls, tables, and metric summaries.
- **JetBrains Mono (Model Diagnostics & Code Entities):** Applied strictly to formulas ($R^2$, Log-Likelihood, AIC/BIC), p-values, matrix notation, data timestamps, and command palettes. Monospaced characters ensure vertical decimal alignment across multi-row regression outputs.

## Layout & Spacing

The layout is built around a dense 12-column fluid grid system optimized for widescreen displays (1440px and 1920px terminal workstations), with an adaptable sidebar layout reminiscent of Quarto analytical reports:

- **Screen Adaptations:**
  - **Desktop (>= 1280px):** 12 columns, `1rem` (16px) gutters, and `1.5rem` (24px) outer margins. Multi-pane analytical layouts support simultaneous side-by-side inspection (e.g., 3-column model specification drawer, 6-column main forecast chart canvas, 3-column residual diagnostic strip).
  - **Tablet (768px - 1279px):** 8 columns, `0.75rem` (12px) gutters, collapsing sidebars into sliding overlay sheets.
  - **Mobile (< 768px):** 4 columns, single-column vertical flow with horizontally scrollable matrix tables.
- **Density Philosophy:** Compact vertical rhythm using `0.5rem` (8px) and `0.75rem` (12px) gaps minimizes vertical scroll distance, keeping critical macro parameters and loss functions in simultaneous view.

## Elevation & Depth

Visual hierarchy relies on crisp, low-contrast structural outlines rather than heavy drop shadows, reproducing the flat, razor-sharp tactile feel of high-end analytical software:

- **Level 0 (Base Canvas):** Flat `#F8FAFC` surface.
- **Level 1 (Card & Module Panels):** Pure `#FFFFFF` fill bounded by a continuous `1px solid #E2E8F0` border. No drop shadow is used during steady state; spatial division is derived entirely from border definition.
- **Level 2 (Interactive Floating Tools & Chart Tooltips):** Pure `#0F172A` (or `#FFFFFF` in reversed contexts) with `box-shadow: 0 4px 12px -2px rgba(15, 23, 42, 0.08), 0 2px 6px -1px rgba(15, 23, 42, 0.04)` and a `1px solid #CBD5E1` outline.
- **Level 3 (Modal Forecast Overlays & Drawer Flyouts):** Suspended above the canvas with a soft backdrop blur (`backdrop-filter: blur(4px)`) and an architectural shadow: `0 20px 25px -5px rgba(15, 23, 42, 0.1), 0 8px 10px -6px rgba(15, 23, 42, 0.05)`.

## Shapes

The design system employs a restrained, soft-corner shape profile (`roundedness: 1`):

- **Structural Containers & Chart Cards:** `0.25rem` (4px) corner radius (`rounded`), creating an authoritative, grid-aligned posture reminiscent of scientific documentation.
- **Action Buttons & Form Inputs:** `0.25rem` (4px) radius, reinforcing precision and mechanical efficiency.
- **Badges, Status Indicators, & Model Pills:** `0.25rem` (4px) to `0.375rem` (6px) maximum. Full pill radii (e.g., `9999px`) are prohibited to avoid casual, consumer-app connotations.

## Components

### Buttons & Trigger Actions
- **Primary Action (Run Simulation / Estimate Model):** Solid `#0F172A` background, white text, 4px border radius, `0.5rem 0.875rem` padding, font weight 500 (`Inter`). Hover transitions to `#1E293B`.
- **Destructive / Reset Button:** Border `1px solid #E2E8F0`, transparent background, text `#C22238`. On hover: background `#FFF1F2`, border `#FECDD3`.
- **Secondary / Export Action:** Pure `#FFFFFF` background, `1px solid #E2E8F0` border, text `#334155`. Hover: background `#F1F5F9`.

### Chips, Badges & Model Parameter Pills
- **Metric Confidence Badges:** Compact height (`20px`), `JetBrains Mono` at `0.75rem`, `0.25rem` padding.
  - Statistically Significant ($p < 0.01$): `#ECFDF5` background, `#047857` text, border `1px solid #A7F3D0`.
  - Policy / Outlier Warning: `#FFF1F2` background, `#BE123C` text, border `1px solid #FECDD3`.
  - Neutral Parameter (e.g., $\lambda = 1600$): `#F1F5F9` background, `#334155` text, border `1px solid #E2E8F0`.

### Data Grids & Tabular Views
- **Header Cells:** `#F8FAFC` background, text uppercase `label-caps` in `#64748B`, `1px solid #E2E8F0` border bottom, padding `0.5rem 0.75rem`.
- **Data Cells:** `Inter` or `JetBrains Mono` with tabular numbers enabled (`tnum`), height fixed to `32px` for maximum analytical density, text `#0F172A`, bottom border `1px solid #F1F5F9`.
- **Row States:** Hover row background `#F8FAFC`. Active/Selected row uses `#F0F9FF` with a left indicator stripe of `2px solid #0284C7`.

### Form Controls (Sliders, Inputs, Dropdowns)
- **Numeric & Specification Inputs:** `1px solid #CBD5E1` border, `#FFFFFF` background, text in `JetBrains Mono` 14px. Focus state: `1px solid #0284C7` with `0 0 0 1px #0284C7`.
- **Checkboxes & Radios:** Sharp 2px corner radius for checkboxes, standard circular for radio buttons. Selected fill is `#0F172A` with crisp white checkmark/dot indicators.

### Cards & Analytical Containers
- Pure white background, `1px solid #E2E8F0` border, `0.25rem` corner radius.
- **Card Header Strip:** Height `36px`, borders `#E2E8F0` separating the header from the chart canvas. Contains title in `headline-md` (reduced to `0.875rem`), model lag specifications, and top-right toolbar icons (CSV download, Quarto report render, full-screen toggle).