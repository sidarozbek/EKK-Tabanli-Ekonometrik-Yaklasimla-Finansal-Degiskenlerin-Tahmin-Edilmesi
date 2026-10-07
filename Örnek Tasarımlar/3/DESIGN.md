---
name: Econometric Terminal
colors:
  surface: '#0b1326'
  surface-dim: '#0b1326'
  surface-bright: '#31394d'
  surface-container-lowest: '#060e20'
  surface-container-low: '#131b2e'
  surface-container: '#171f33'
  surface-container-high: '#222a3d'
  surface-container-highest: '#2d3449'
  on-surface: '#dae2fd'
  on-surface-variant: '#bbcabf'
  inverse-surface: '#dae2fd'
  inverse-on-surface: '#283044'
  outline: '#86948a'
  outline-variant: '#3c4a42'
  surface-tint: '#4edea3'
  primary: '#4edea3'
  on-primary: '#003824'
  primary-container: '#10b981'
  on-primary-container: '#00422b'
  inverse-primary: '#006c49'
  secondary: '#b4c5ff'
  on-secondary: '#002a78'
  secondary-container: '#0053db'
  on-secondary-container: '#cdd7ff'
  tertiary: '#7bd0ff'
  on-tertiary: '#00354a'
  tertiary-container: '#19aee8'
  on-tertiary-container: '#003e55'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#6ffbbe'
  primary-fixed-dim: '#4edea3'
  on-primary-fixed: '#002113'
  on-primary-fixed-variant: '#005236'
  secondary-fixed: '#dbe1ff'
  secondary-fixed-dim: '#b4c5ff'
  on-secondary-fixed: '#00174b'
  on-secondary-fixed-variant: '#003ea8'
  tertiary-fixed: '#c4e7ff'
  tertiary-fixed-dim: '#7bd0ff'
  on-tertiary-fixed: '#001e2c'
  on-tertiary-fixed-variant: '#004c69'
  background: '#0b1326'
  on-background: '#dae2fd'
  surface-variant: '#2d3449'
typography:
  display:
    fontFamily: Space Grotesk
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Space Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Space Grotesk
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  body-lg:
    fontFamily: Geist
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
  body-md:
    fontFamily: Geist
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  body-sm:
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  data-metric-lg:
    fontFamily: JetBrains Mono
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: -0.02em
  data-metric-md:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
  data-tabular:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-code:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.03em
  caption:
    fontFamily: Geist
    fontSize: 11px
    fontWeight: '400'
    lineHeight: 14px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 0.75rem
  gutter-lg: 1rem
  margin: 1rem
  margin-lg: 1.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
  space-2xl: 2rem
---

## Brand & Style

This design system defines an academic and financial research environment built for the TÜBİTAK 2209-A research initiative at Atılım University. It merges the analytical gravity of an institutional trading desk (Bloomberg Terminal, FactSet) with the clean clarity of premier scientific platforms (FRED, Our World in Data, Nature Methods).

The aesthetic balances precision engineering with academic rigor. The interface must inspire absolute trust, methodological transparency, and rapid comprehension of complex quantitative models (Ordinary Least Squares, dynamic rolling windows, lag operators, forecast error metrics). Information density is prioritized over decorative whitespace; every pixel and baseline serves quantitative legibility.

Key emotional and functional attributes:
- **Scholarly Authority:** Impeccable typography with strict mathematical notation and tabular numerical consistency.
- **Instrumental Density:** Compact layout components engineered to display high-dimensional time series, matrix outputs, and regression diagnostics side-by-side without visual fatigue.
- **Diagnostic Transparency:** Explicit status systems indicating data pipeline integrity (EVDS, FRED, OECD, and CSV failover buffers).

## Colors

The system uses a dark palette optimized for sustained longitudinal analysis and multi-monitor research setups. It avoids pure blacks (`#000000`) in favor of rich, optical slate-navy tiers that reduce eye strain under prolonged analytical scrutiny.

### Palette Architecture
- **Canvas Base (`#0B0F19`):** Deep abyssal navy for global system background.
- **Surface Layer 1 (`#0F172A`):** Core working surface for dashboards, docked toolbars, and global sidebars.
- **Surface Layer 2 (`#1E293B`):** Elevated cards, econometric model containers, and analytical panels.
- **Surface Layer 3 (`#334155`):** Sub-panels, table header strips, hover tiers, and inactive controls.
- **Dividers & Precision Lines (`#1E293B` to `#334155` at 50% alpha):** 1px structural separators ensuring visual containment of high-density statistics.

### Accent & Functional Semantics
- **Primary Emerald (`#10B981`):** Statistical convergence, target forecast metrics, optimal p-values ($p < 0.01$), model fit indicators ($R^2$, adjusted $R^2$), and active live data connections.
- **Secondary Cobalt (`#2563EB`):** Primary interactions, active tabs, historical baseline time series, and system-level actions.
- **Tertiary Sky (`#38BDF8`):** Rolling out-of-sample forecasts, prediction intervals (95% CI bands), and econometric parameter selections.
- **Amber Warning (`#F59E0B`):** Marginal significance ($0.05 < p < 0.10$), lag order instability, and structural breaks detected.
- **Crimson Error (`#EF4444`):** Model divergence, unit root detection failure, EVDS/FRED sync timeout, and critical forecast residuals.
- **Source Health Indicators:**
  - `EVDS`: Crisp turquoise (`#06B6D4`)
  - `FRED`: Deep institutional blue (`#3B82F6`)
  - `OECD`: Vibrant violet (`#8B5CF6`)
  - `CSV_YEDEK`: Neutral slate amber (`#D97706`)

## Typography

The typographic hierarchy is split into three intentional roles:
1. **Space Grotesk (Display & Section Titles):** Provides a sharp, authoritative, technical identity that evokes structural science and mathematical notation.
2. **Geist (Body & Analytical Interface):** Delivers clean readability for econometric explanations, model hypotheses, and project abstracts at high density.
3. **JetBrains Mono (Data & Formulas):** Used for all quantitative outputs, tabular matrices, mathematical expressions (e.g., $y_t = \alpha + \beta x_t + \epsilon_t$), test statistics (RMSE, Theil's U, AIC, BIC, MAPE), and time stamps. 

All mono numerals must be rendered with strict tabular layout (`font-variant-numeric: tabular-nums lining-nums`) so that decimals align vertically across rows in financial comparison tables.

## Layout & Spacing

The workstation uses a compact fluid grid system with structural snap boundaries, supporting continuous data streaming and multi-pane modeling.

### Layout Mechanics
- **Grid Architecture:** 12-column layout (expandable to 16 or 24 columns on ultra-wide displays $\ge 1920\text{px}$). Default column gutter is locked to `0.75rem` (12px) to maximize horizontal data density.
- **Docked Canvas Framework:** The workstation utilizes fixed-ratio flexible panes:
  - Global Header: Fixed `44px` height containing institutional TÜBİTAK/Atılım badges, project metadata, and data sync status.
  - Left Tool Pane (Variables & Parameters): `280px` to `340px` fixed width containing lag orders ($p, q$), dynamic estimation windows ($w$), and feature selectors.
  - Center Canvas: Fluid regression surfaces, time-series charts, and out-of-sample visualizers.
  - Right Inspector Pane (Diagnostic Station): `320px` dedicated to goodness-of-fit (Theil U, RMSE, AIC, BIC, White Heteroskedasticity test).
- **Responsive Handling:** On screens $< 1024\text{px}$, the interface stacks the parameter panel into an off-canvas drawer and adjusts grid margins to `0.75rem`, while preserving horizontal scrolling on tabular matrices to prevent statistical column clipping.

## Elevation & Depth

This system intentionally departs from heavy drop shadows and glassmorphic blurs, opting for high-precision **Tonal Layering** combined with **Low-Contrast Technical Outlines**. This reproduces the precision of calibrated scientific instruments and terminal monitors.

### Hierarchy & Tiers
- **Tier 0 (Base Canvas - `#0B0F19`):** The foundational substrate behind all modules.
- **Tier 1 (Surface Panel - `#0F172A`):** Boundary delineated by a 1px border (`#1E293B`). Zero shadow.
- **Tier 2 (Interactive Modules / Chart Cards - `#1E293B`):** Outlined with 1px solid stroke (`#334155`). Used for active regression charts and statistical metric blocks.
- **Tier 3 (Floating Menus & Diagnostic Popovers - `#1E293B`):** Elevated using a surgical, low-diffusion ambient shadow: `box-shadow: 0 4px 20px -2px rgba(0, 0, 0, 0.65), 0 0 0 1px #475569`.
- **Active Focus & Data Selection:** When a parameter or data point is focused, elevation is communicated through a razor-thin optical glow: `box-shadow: 0 0 0 1px #10B981, 0 0 12px rgba(16, 185, 129, 0.25)`.

## Shapes

The platform utilizes a **Soft (Level 1)** geometric standard. Roundness is dialed back to maintain an industrial, analytical character:
- Standard interactive elements (inputs, select triggers, buttons): `0.25rem` (4px).
- Panel containers and regression cards: `0.375rem` (6px).
- Metric pills and data health badges: `0.25rem` (4px). Pure circular pills are strictly forbidden to preserve maximum tabular density and prevent text truncation.
- Technical charts and internal grid blocks: `0px` inner corners to align flush against axes and tick marks.

## Components

### Buttons & Interactive Triggers
- **Primary Action (e.g., "Run OLS Estimation", "Compute Forecast"):** Solid emerald fill (`#10B981`), dark slate text (`#022C22`), weight 600, height `32px`, font size `12px`. Hover state shifts to `#059669`.
- **Secondary Action (e.g., "Export LaTeX Table", "Configure Lags"):** Ghost style with `#1E293B` background, 1px stroke of `#334155`, text `#F8FAFC`. Hover shifts stroke to `#475569`.
- **Icon / Micro Tool Buttons:** `28px x 28px` square, centered iconography, `4px` radius.

### Data Health Badges (EVDS, FRED, OECD, CSV_YEDEK)
- Rendered as compact, monospaced micro-indicators: `height: 20px`, padding `2px 6px`, radius `4px`, font `JetBrains Mono` at `10px` uppercase.
- Composed of an inline `5px` pulsing indicator dot paired with label text:
  - **EVDS:** `#06B6D4` dot with 15% `#06B6D4` background tint and 30% border.
  - **FRED:** `#3B82F6` dot with 15% `#3B82F6` background tint and 30% border.
  - **OECD:** `#8B5CF6` dot with 15% `#8B5CF6` background tint and 30% border.
  - **CSV_YEDEK:** `#F59E0B` dot with 15% `#F59E0B` background tint and 30% border.

### Analytical Data Tables
- Header row height `28px`, uppercase `11px` JetBrains Mono, background `#1E293B`, subtle bottom border `#334155`.
- Data rows height `28px`, font size `12px` tabular mono. Alternating row background (`#0F172A` / `#131D31`) for scanning long macroeconomic series.
- Right-aligned numeric values. Negative values colored in soft coral (`#F87171`); statistical significance indicated by asterisk badges (`* p<0.1`, `** p<0.05`, `*** p<0.01`).

### Input Fields & Estimation Controls
- Height `30px`, background `#0B0F19`, 1px border `#334155`, text `#F8FAFC`, placeholder `#64748B`.
- Integrated parameter steppers (for lag window $w$, step $k$): compact dual-arrow triggers integrated into the right-hand boundary of the input.

### Metric Cards (Diagnostics & Error Values)
- Compact rectangular modules: Top label in `11px` Geist (`#94A3B8`), primary metric in `18px` JetBrains Mono bold (`#F8FAFC`).
- Delta / Baseline indicator below: `+0.042 vs AR(1)` with directional arrow, tinted green for error reduction (e.g., lower RMSE/Theil U) and red for error degradation.

### Chart Containers
- Integrated header featuring active variable indicators (e.g., `USD/TRY ~ [TCMB_EVDS]`), temporal resolution toggles (`M`, `Q`, `Y`), and zoom-lock buttons.
- Grid lines styled with `#334155` at 40% opacity, dotted `1px`. Crosshairs lock to closest historical timestamp displaying tooltip coordinates in tabular monospace.