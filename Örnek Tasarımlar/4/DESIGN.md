---
name: Econometric Terminal & Research Console
colors:
  surface: '#0f131d'
  surface-dim: '#0f131d'
  surface-bright: '#353944'
  surface-container-lowest: '#0a0e18'
  surface-container-low: '#171b26'
  surface-container: '#1c1f2a'
  surface-container-high: '#262a35'
  surface-container-highest: '#313540'
  on-surface: '#dfe2f1'
  on-surface-variant: '#bbcabf'
  inverse-surface: '#dfe2f1'
  inverse-on-surface: '#2c303b'
  outline: '#86948a'
  outline-variant: '#3c4a42'
  surface-tint: '#4edea3'
  primary: '#4edea3'
  on-primary: '#003824'
  primary-container: '#10b981'
  on-primary-container: '#00422b'
  inverse-primary: '#006c49'
  secondary: '#adc6ff'
  on-secondary: '#002e6a'
  secondary-container: '#0566d9'
  on-secondary-container: '#e6ecff'
  tertiary: '#ffb95f'
  on-tertiary: '#472a00'
  tertiary-container: '#e29100'
  on-tertiary-container: '#523200'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#6ffbbe'
  primary-fixed-dim: '#4edea3'
  on-primary-fixed: '#002113'
  on-primary-fixed-variant: '#005236'
  secondary-fixed: '#d8e2ff'
  secondary-fixed-dim: '#adc6ff'
  on-secondary-fixed: '#001a42'
  on-secondary-fixed-variant: '#004395'
  tertiary-fixed: '#ffddb8'
  tertiary-fixed-dim: '#ffb95f'
  on-tertiary-fixed: '#2a1700'
  on-tertiary-fixed-variant: '#653e00'
  background: '#0f131d'
  on-background: '#dfe2f1'
  surface-variant: '#313540'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: '0'
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: -0.005em
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: '0'
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-lg:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: '0'
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 10px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.04em
  code-sm:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: '0'
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-dense: 0.5rem
  margin: 1.5rem
  margin-sm: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
---

## Brand & Style

The design system establishes a high-performance, precision-grade academic and institutional research interface tailored for econometric modeling, ordinary least squares (OLS / EKK) time-series regressions, and empirical forecasting under TÜBİTAK 2209-A standards. 

The aesthetic fuses the dense, data-first utility of legacy financial terminals (Bloomberg, Refinitiv Eikon) with the refined legibility and layered optics of contemporary analytical platforms. The visual tone is disciplined, objective, scholarly, and uncompromisingly technical. It communicates computational confidence, academic integrity, and statistical exactitude. 

Visual design movements integrated:
- **Terminal Modernism:** High visual density, tight structural margins, monospaced tabular alignments, and unambiguous semantic color-coding for financial time series and error terms.
- **Controlled Glassmorphism & Micro-surfacing:** Subtly translucent container panels (layered over deep obsidian-navy canvases) featuring 1px technical borders and sub-pixel dot-matrix background guides.
- **Minimalist Precision:** Visual noise is reduced; decorative elements are eliminated in favor of interactive coordinate grids, residual dispersion plots, regression diagnostic matrices, and responsive coefficient tables.

## Colors

The palette is engineered specifically for prolonged, zero-fatigue quantitative analysis in dark-mode environments. The canvas draws from deep oceanic midnight slates rather than pure black, providing high contrast without harsh glare.

### Semantic & Data Encoding Roles
- **Primary (`#10B981` Emerald Cyan):** Denotes econometric predictions ($\hat{Y}$), fitted OLS regression lines, statistical significance markers ($p < 0.01$), model convergence, and positive residual thresholds.
- **Secondary (`#3B82F6` Sapphire Blue):** Represents empirical actuals ($Y$), ground-truth historical market data, dependent variables, and primary interactive state controls.
- **Tertiary (`#F59E0B` Amber):** Flags outliers, heteroskedasticity warnings, structural breaks (Chow test indicators), collinearity notices (VIF > 5), and secondary instrument series.
- **Critical / Error (`#EF4444` Crimson):** Marks model divergence, autocorrelation rejections (Durbin-Watson failure zones), multicollinearity, and stationarity test failures (ADF rejection at critical thresholds).
- **Neutral Canvas Hierarchy:**
  - Base Canvas: `#0B0F19` (Obsidian Navy)
  - Surface Panel (Tier 1): `#111827` (Deep Slate Gray)
  - Surface Elevated / Card (Tier 2): `#1F2937` (Subtle Gunmetal)
  - Structural Division / Borders: `#1F2937` (low-contrast structural wireframes) and `#374151` (active interactive borders)
  - Text Hierarchy: Primary text at `#F9FAFB` (high-readability soft white), secondary metrics at `#9CA3AF` (cool silver), and muted parameters at `#4B5563` (subdued graphite).

## Typography

The typography system relies on a dual-engine architecture:
1. **Inter** for all structural UI chrome, navigation items, documentation prose, academic abstracts, and modal dialogs. Its tall x-height and neutral grotesque curves maintain high scan-speed across complex administrative layouts.
2. **JetBrains Mono** for numerical values, financial tickers, econometric equations ($R^2$, Adjusted $R^2$, F-statistic, t-ratios, $p$-values, Akaike & Schwarz criteria), matrix outputs, and chart axes. Monospace numerals ensure strict tabular alignment without shifting decimal points across live calculations.

Mathematical formulas are typeset with clear structural hierarchy: coefficients and parameter symbols are tracked tight with heightened weight (`500` or `600`), while variable labels utilize uppercase micro-typography (`label-sm`) with widened letter-spacing (`0.04em`) to establish visual separation against dense financial figures.

## Layout & Spacing

The layout is built upon an analytics-optimized **fluid multi-pane grid** configured for multi-monitor econometric workflows and data workstations:

- **Desktop (>= 1440px):** 12-column variable fluid grid with an optional 3-column split workstation (Model Configuration Drawer / Main Diagnostic Canvas / Parameter & Regression Summary Deck). Primary gutter is `1rem` (16px), collapsible to `gutter-dense` (`0.5rem` / 8px) within data table cells and metric grids.
- **Tablet (768px - 1439px):** 8-column layout. Chart inspectors and correlation heatmaps occupy the full top span, while coefficient tables and test matrices stack sequentially below. Outer margin: `1rem` (16px).
- **Mobile (< 768px):** 4-column reflow. Critical indicator cards stack vertically, chart canvases render with horizontal pan-and-scan viewports, and tabular columns hide secondary statistical tests ($t$-stat, std err) behind expandable row drawers. Outer margin: `1rem`.

Component padding relies strictly on compact intervals (`space-xs` to `space-md`) to ensure maximum information density per square pixel without inducing visual friction.

## Elevation & Depth

The design system rejects heavy, theatrical drop shadows in favor of a **Tonal Surface Hierarchy reinforced by Translucent Glassmorphism and Low-Contrast Luminous Borders**.

1. **Layer 0 (Canvas Base):** Solid background (`#0B0F19`) overlaid with an ambient 24px micro-grid composed of 1px alpha-blended grid intersections (`rgba(31, 41, 55, 0.3)`).
2. **Layer 1 (Card & Module Containers):** Surface layer filled with `rgba(17, 24, 39, 0.75)` backed by an `8px` blur (`backdrop-filter: blur(8px)`). Enclosed with a razor-thin 1px border (`#1F2937`).
3. **Layer 2 (Floating Popovers, Flyout Inspectors, Tooltips):** Surface layer filled with `rgba(31, 41, 55, 0.95)`, 12px blur, and a crisp 1px active outline (`#374151`). Elevated with a directional, highly diffused ambient occlusion shadow: `0 8px 32px -4px rgba(0, 0, 0, 0.6)`.
4. **Active Series Glow:** When a time-series or prediction trajectory is selected, it casts a subtle directional luminescence (e.g., `#10B981` at `0.15` opacity) onto the immediate chart grid lines, establishing clear data focus.

## Shapes

The design system implements a **Soft-Edge Technical Geometry (`roundedness: 1`)**. 

- Standard component corners (buttons, input fields, metric tiles, chips) utilize a precise radius of `0.25rem` (4px).
- Larger container structures (charts, panel headers, data tables) leverage `rounded-lg` (`0.5rem` / 8px).
- Badges, status nodes, and categorical tags employ `rounded-sm` (2px) to evoke an authentic computational, hardware-terminal cadence.

Circular geometry is reserved strictly for interactive radio indicators, step indicators in dynamic regression pipelines, and status pings (e.g., live streaming socket indicators).

## Components

### Buttons
- **Primary Action (Execute Model / Run OLS):** Background in high-chroma Emerald Cyan (`#10B981`), foreground in obsidian (`#0B0F19`), weight `600`, radius `0.25rem`. Hover state introduces a luminous green outer edge (`box-shadow: 0 0 12px rgba(16, 185, 129, 0.4)`).
- **Secondary Action (Export LaTeX / CSV):** Transparent background with a 1px border (`#374151`), foreground in `#E5E7EB`. Hover shifts background to `rgba(55, 65, 81, 0.4)` and border to `#9CA3AF`.
- **Icon / Terminal Buttons:** Monospaced 32x32px square buttons with subtle border styling for quick toggles (log transforms, first differences, detrending).

### Input Fields & Selectors
- **Configuration Inputs:** Dark recessed slate surface (`#0B0F19`), 1px outline in `#1F2937`, text typeset in `JetBrains Mono` (`13px`). Focus transitions the border to `#3B82F6` (Sapphire Blue) accompanied by an inline status dot.
- **Variable Selector Dropdowns:** Dense multi-select tags featuring drag-and-drop handles for assigning Dependent ($Y$) vs. Independent ($X_1, X_2, \dots, X_k$) variables.

### Chips & Badges
- **Statistical Significance Flags:** Ultra-compact tags (`padding: 2px 6px`, `JetBrains Mono 10px`).
  - Three stars ($p < 0.01$): `#10B981` background at `10%` opacity, border `rgba(16, 185, 129, 0.3)`, text `#10B981`.
  - Inconclusive ($p > 0.10$): `#9CA3AF` background at `10%`, border `rgba(156, 163, 175, 0.2)`, text `#9CA3AF`.
  - Multicollinearity Flag: `#F59E0B` text on amber-tinted background.

### Cards & Analytical Panels
- Structural glassmorphism containers: `background: rgba(17, 24, 39, 0.75)`, `border: 1px solid #1F2937`.
- **Card Header:** Dedicated 36px bar separated by a 1px baseline border (`#1F2937`), housing the econometric module title in `Inter 12px uppercase` and active sample window details (e.g., `T = 2010:Q1 - 2023:Q4`) in `JetBrains Mono 11px muted`.

### Data Tables (Regression Output Matrix)
- Standardized academic tabular format adhering to formal econometrics presentation (Coefficients, Standard Errors in parentheses, $t$-statistics, $p$-values).
- Striped alternating row backgrounds using `rgba(31, 41, 55, 0.2)` on even rows. Hover state triggers a subtle `#3B82F6` left-accent indicator border (2px width).
- Numeric alignment: strictly right-aligned monospaced numerals with standardized 4-decimal precision across all statistical outputs.

### Specialty Econometric Components
- **Residual Distribution Histogram & QQ-Plot Container:** Split view module equipped with interactive vertical crosshair tracking and normal distribution overlay curves.
- **Model Specification Bar:** Sticky top command strip indicating currently estimated equation: $Y_t = \beta_0 + \beta_1 X_{1t} + \dots + \epsilon_t$ with active parameter chips.