---
name: Econometric Intelligence Platform
colors:
  surface: '#0f131c'
  surface-dim: '#0f131c'
  surface-bright: '#353943'
  surface-container-lowest: '#0a0e17'
  surface-container-low: '#181b25'
  surface-container: '#1c1f29'
  surface-container-high: '#262a34'
  surface-container-highest: '#31353f'
  on-surface: '#dfe2ef'
  on-surface-variant: '#bbcabf'
  inverse-surface: '#dfe2ef'
  inverse-on-surface: '#2c303a'
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
  tertiary: '#ddb7ff'
  on-tertiary: '#490080'
  tertiary-container: '#c487ff'
  on-tertiary-container: '#550093'
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
  tertiary-fixed: '#f0dbff'
  tertiary-fixed-dim: '#ddb7ff'
  on-tertiary-fixed: '#2c0051'
  on-tertiary-fixed-variant: '#6900b3'
  background: '#0f131c'
  on-background: '#dfe2ef'
  surface-variant: '#31353f'
typography:
  headline-xl:
    fontFamily: Inter
    fontSize: 2.25rem
    fontWeight: '600'
    lineHeight: 2.75rem
    letterSpacing: -0.025em
  headline-xl-mobile:
    fontFamily: Inter
    fontSize: 1.75rem
    fontWeight: '600'
    lineHeight: 2.25rem
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 1.5rem
    fontWeight: '600'
    lineHeight: 2rem
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 1.125rem
    fontWeight: '600'
    lineHeight: 1.5rem
    letterSpacing: -0.015em
  body-lg:
    fontFamily: Inter
    fontSize: 0.9375rem
    fontWeight: '400'
    lineHeight: 1.5rem
    letterSpacing: -0.005em
  body-md:
    fontFamily: Inter
    fontSize: 0.8125rem
    fontWeight: '400'
    lineHeight: 1.25rem
    letterSpacing: '0'
  body-sm:
    fontFamily: Inter
    fontSize: 0.75rem
    fontWeight: '400'
    lineHeight: 1.125rem
    letterSpacing: 0.005em
  label-numeric-lg:
    fontFamily: JetBrains Mono
    fontSize: 1.25rem
    fontWeight: '500'
    lineHeight: 1.5rem
    letterSpacing: -0.02em
  label-numeric-md:
    fontFamily: JetBrains Mono
    fontSize: 0.8125rem
    fontWeight: '500'
    lineHeight: 1.125rem
    letterSpacing: -0.01em
  label-numeric-sm:
    fontFamily: JetBrains Mono
    fontSize: 0.6875rem
    fontWeight: '400'
    lineHeight: 0.9375rem
    letterSpacing: '0'
  code-formula:
    fontFamily: JetBrains Mono
    fontSize: 0.8125rem
    fontWeight: '400'
    lineHeight: 1.375rem
    letterSpacing: '0'
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
  space-lg: 1.25rem
  space-xl: 2rem
---

## Brand & Style
The design system establishes an institutional-grade econometric workstation for academic researchers, quantitative strategists, and policy analysts operating under rigorous computational standards (TÜBİTAK 2209-A / Atılım University). It reconciles the density and precision of classical quantitative terminal environments (FactSet, Bloomberg) with contemporary European academic typography and mathematical publishing aesthetics.

The personality is authoritative, mathematically uncompromising, and forensic. Every pixel signals numerical integrity: uncertainty intervals are never obscured, data points remain sovereign, and computational state transitions (such as Hampel filter thresholds, OLS parameter convergence, or out-of-sample forecast bands) are conveyed with exact chromatic discipline. Visual noise, purely decorative gradients, and frivolous motion are eliminated in favor of information density, low retinal fatigue during multi-hour research sprints, and instant visual disambiguation of stochastic data layers.

## Colors
The system operates natively in dark mode to preserve contrast across continuous, high-frequency line charts and complex econometric matrix visualizations.

- **Foundational Surfaces**:
  - `canvas-default`: `#090D16` (Deep Midnight Slate)
  - `surface-subtle`: `#0F172A` (Tier 1 structural panels, dock chrome)
  - `surface-elevated`: `#1E293B` (Inspectors, popovers, model configuration cards)
  - `surface-inset`: `#050811` (Data-table wells, terminal logs, code blocks)
  - `border-subtle`: `#1E293B`
  - `border-contrast`: `#334155`

- **Econometric Semantic Palette**:
  - **Forecast & Estimation (Primary)**: `#10B981` (Emerald). Signifies forward-projected paths, point estimates ($\hat{y}_{t+h}$), and successful convergence.
  - **Empirical Baseline (Secondary)**: `#3B82F6` (Sapphire Blue). Dedicated to ground-truth historical realizations ($y_t$), target training sets, and standard regressors.
  - **Cross-Validation & Hyperparameters (Tertiary)**: `#A855F7` (Amethyst Purple). Dictates walk-forward splits, train-test boundaries, ridge/lasso shrinkage trajectories, and latent variables.
  - **Diagnostic Warnings & Hampel Outliers**: `#F59E0B` (Amber). Denotes structural breaks, missing observation interpolations, ARCH residual volatility spikes, and stationarity cautions.
  - **Macro Distress & Inflation Critical Alerts**: `#EF4444` (Crimson). Expresses non-invertible MA polynomials, unit-root persistence failures, and runaway forecast variance.

- **Alpha/Ribbon Overlays**:
  - 95% Confidence Interval Fill: `rgba(16, 185, 129, 0.12)` bordered by `rgba(16, 185, 129, 0.40)`.
  - 99% Tail Interval Fill: `rgba(59, 130, 246, 0.08)` bordered by `rgba(59, 130, 246, 0.25)`.

## Typography
Typography is split into two specialized engines:
1. **Interface & Prose Layer (`Inter`)**: Tuned for dense metric displays with tabular lining numerals activated (`tnum`, `cv05`, `cv11`). Headings maintain tighter negative tracking to present compact analytical summaries without word breaks.
2. **Formulaic, Matrix & Value Layer (`JetBrains Mono`)**: Mandated for raw matrix coefficients, p-values, t-statistics, Durbin-Watson tests, confidence limit brackets, and inline LaTeX/econometric representations.

Mathematical notations (such as $AR(p)$, $R^2$, and $\Delta y_t = \alpha + \beta x_{t-1} + \varepsilon_t$) must display within the monospaced hierarchy to prevent proportional font jitter during real-time parameter re-estimation.

## Layout & Spacing
The layout follows an ultra-dense, multi-pane financial terminal grid optimized for widescreen displays (1440px to 4K multi-monitor workspaces), with structured reflow down to compact displays:

- **Structural Grid**: 12-column variable fractional layout. Standard analytics dashboard presents a 3-pane split:
  - Left pane: 2 or 3 columns (Model specification: lags, exogenous regressors, transformations).
  - Center pane: 6 or 7 columns (Main forecast timeline, confidence intervals, residual plot, QQ-plot).
  - Right pane: 3 columns (Tabular diagnostics: $p$-values, AIC/BIC, RMSE/MAE metrics, rolling window parameter tracking).
- **Responsive Adaptations**:
  - **Desktop ($\ge 1280\text{px}$)**: Full 3-pane parallel execution with dockable tabs and synchronous crosshair scrubbing.
  - **Tablet ($768\text{px} - 1279\text{px}$)**: Collapses into 2-tier stacked views; parameter drawer becomes a sliding sheet.
  - **Mobile ($< 768\text{px}$)**: Single column with dedicated segmented sub-navigation toggling between Visualization, Diagnostic Table, and Regressors.
- **Rhythm**: Anchored by an ultra-compact base unit of `4px` (`0.25rem`) to maximize vertical data density in tables and time-series viewports.

## Elevation & Depth
The system eliminates heavy blur drop-shadows and skeuomorphic light sources in favor of **Tonal Layering with Low-Contrast Structural Outlines**.

1. **Surface 0 (Floor)**: Canvas background (`#090D16`), raw unbordered workspace.
2. **Surface 1 (Card/Dock Tier)**: Panel backgrounds (`#0F172A`) structured strictly by `1px solid #1E293B`. Zero shadow.
3. **Surface 2 (Active/Hover Tier)**: Interactive table rows, selected charts, or active parameter blocks switch to `#1E293B` bounded by `#334155`.
4. **Surface 3 (Floating Inspectors & Tooltips)**: Overlays use `#1E293B` with an ambient, technical hairline stroke of `1px solid #475569` and a precision shadow: `0 4px 12px rgba(0, 0, 0, 0.45)`.
5. **Data Depth**: In visualizations, temporal ribbons and intervals layer over one another through controlled alpha channels (`0.08` to `0.20`), ensuring regression lines (`#10B981` and `#3B82F6`) stay razor-sharp at `1.5px` or `2px` vector weight on the foreground plane.

## Shapes
Geometry is disciplined, utilitarian, and near-orthogonal (`Soft` / `0.25rem`). Curved corners must remain minimal (`4px` base, `6px` maximum for floating modals) to preserve screen real estate in dense grid splits and eliminate visual sagging along tabular borders. Data points on line graphs are unrounded vectors (sharp squares or crisp crosses) on zoom inspection.

## Components

- **Buttons & Model Triggers**:
  - Standard button height: `28px` (compact) to `32px` (default). 
  - Primary ("Run OLS / Generate Forecast"): Emerald fill (`#10B981`), dark text (`#090D16`), font weight `600`, zero blur, subtle hover brightness shift.
  - Secondary / Utility: Surface background (`#1E293B`), text (`#E2E8F0`), hairline border (`#334155`).
  - Compute State: Monospaced loading badge with elapsed microsecond timer (`[t = 124ms]`).

- **Diagnostic Data Tables**:
  - Row height: `24px` to `28px` maximum. Zebra alternating tinting suppressed; separation handled via subtle row border (`#1E293B`).
  - Columns right-aligned for all numerical outputs ($R^2$, AIC, F-stat, Kurtosis, Skewness).
  - P-value cells feature dynamic micro-badges: Emerald text for $p < 0.01$, amber for $0.05 \le p < 0.10$, and muted slate for non-significance ($p \ge 0.10$).

- **Interactive Sparklines & Chart Overlays**:
  - Baseline series rendered in Sapphire Blue (`#3B82F6`) at `1.5px`.
  - Point forecasts rendered in Emerald Green (`#10B981`) with distinct dashed styling for out-of-sample horizons.
  - Confidence interval bounds (e.g. $\pm 2\sigma$) rendered with zero-stroke fill ribbons utilizing alpha masks.
  - Hampel filter outlier flags: `6px` Amber diamond markers positioned directly over aberrant residual points with inline tooltip diagnostics.

- **Econometric Parameter Chips & Sliders**:
  - Compact `20px` tall chips with JetBrains Mono tags (e.g., `p=2`, `d=1`, `q=1`, `seasonal=TRUE`).
  - Draggable split-date dividers for rolling cross-validation windows, bounded with Amethyst Purple (`#A855F7`) accents and hairline indicators.

- **Input Fields & Mathematical Formula Editors**:
  - Monospaced inputs with inset background (`#050811`) and high-contrast interior text.
  - Real-time syntax validation: Border shifts immediately to Crimson (`#EF4444`) on collinear regressor specification or non-invertible matrix entries.