---
name: Econometric Forecaster Mobile
colors:
  surface: '#0d1320'
  surface-dim: '#0d1320'
  surface-bright: '#333948'
  surface-container-lowest: '#080e1b'
  surface-container-low: '#161b29'
  surface-container: '#1a1f2d'
  surface-container-high: '#242a38'
  surface-container-highest: '#2f3543'
  on-surface: '#dde2f5'
  on-surface-variant: '#bac9cc'
  inverse-surface: '#dde2f5'
  inverse-on-surface: '#2a303f'
  outline: '#849396'
  outline-variant: '#3b494c'
  surface-tint: '#00daf3'
  primary: '#c3f5ff'
  on-primary: '#00363d'
  primary-container: '#00e5ff'
  on-primary-container: '#00626e'
  inverse-primary: '#006875'
  secondary: '#ffd799'
  on-secondary: '#432c00'
  secondary-container: '#feb300'
  on-secondary-container: '#6a4800'
  tertiary: '#eaecff'
  on-tertiary: '#00297a'
  tertiary-container: '#c3cfff'
  on-tertiary-container: '#2751bc'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#9cf0ff'
  primary-fixed-dim: '#00daf3'
  on-primary-fixed: '#001f24'
  on-primary-fixed-variant: '#004f58'
  secondary-fixed: '#ffdeac'
  secondary-fixed-dim: '#ffba38'
  on-secondary-fixed: '#281900'
  on-secondary-fixed-variant: '#604100'
  tertiary-fixed: '#dbe1ff'
  tertiary-fixed-dim: '#b5c4ff'
  on-tertiary-fixed: '#00174d'
  on-tertiary-fixed-variant: '#053da9'
  background: '#0d1320'
  on-background: '#dde2f5'
  surface-variant: '#2f3543'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 38px
  headline-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 30px
  headline-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  title-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  body-lg:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
  body-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  body-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '400'
    lineHeight: 16px
  metric-display:
    fontFamily: JetBrains Mono
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 28px
  metric-value:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 18px
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 10px
    fontWeight: '500'
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
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1.25rem
  space-xl: 1.75rem
---

## Brand & Style

This design system is engineered for high-precision econometric research, financial analysis, and academic presentation under the TÜBİTAK 2209-A research initiative. It balances institutional authority with cutting-edge analytical tools, turning complex Ordinary Least Squares (OLS / EKK) regressions, residual analyses, and probabilistic confidence envelopes into clear, legible mobile experiences.

### Design Movement & Aesthetic
- **Analytical Modernism / Technical Slate**: Dense with information yet rigorously structured. The aesthetic relies on low-reflection deep slate backdrops, hairline boundary dividers, and focused neon-tinged accents (cyan and amber) reminiscent of professional terminal displays and institutional econometric reports.
- **Academic Rigor Meets Contemporary Fintech**: Data cards behave as scholarly artifacts. Typography switches naturally between systematic interface prose and monospaced quantitative notation to guarantee precision reading without ocular fatigue.

### Emotional Target
- **Rigorous & Trustworthy**: Evokes peer-reviewed confidence, mathematical reproducibility, and institutional stability.
- **Accurate & Sharp**: Every metric, coefficient ($R^2$, t-stat, p-value), and prediction interval looks deliberate and verifiable.
- **Focused Efficiency**: Rapidly digestible on mobile touchscreens without clutter or decorative noise.

## Colors

The palette is anchored in a deep astronomical navy and technical slate space to deliver optimal contrast on OLED and mobile LCD screens while eliminating bright white glare during long research sessions.

### Semantic Color Assignments
- **Primary (`#00E5FF` — Electric Cyan)**: Serves as the principal signal color. Used for point forecasts, primary regression trendlines, active navigation states, interactive slider throttles, and high-confidence telemetry indicators.
- **Secondary (`#FFB300` — Signal Amber)**: Applied strictly to secondary econometric variables, residual warning states, volatility bounds, and 95% confidence intervals ($\pm 2\sigma$).
- **Tertiary (`#4E73DF` — Institutional Cobalt)**: Used for secondary comparisons, historical base models, passive dataset indicators, and auxiliary chart overlays.
- **Neutral Surface Ecosystem**:
  - `Base Canvas`: `#070B14` (Deepest Void Navy)
  - `Surface Tier 1 (Cards & Groups)`: `#0E1726` (Muted Slate Navy)
  - `Surface Tier 2 (Nested Tables / Inputs)`: `#152238` (Elevated Deep Slate)
  - `Hairline Borders & Outlines`: `rgba(255, 255, 255, 0.08)` to `rgba(0, 229, 255, 0.18)` for interactive targets.
- **Text & Signal Contrast**:
  - `Text Primary`: `#F0F4FC` (Crisp Chalk White)
  - `Text Secondary`: `#8E9EB5` (Cadet Slate)
  - `Text Muted / Footnote`: `#596A82`
  - `Model Significance Success`: `#00E676` ($p < 0.01$)
  - `Model Instability / Critical`: `#FF5252` ($p > 0.10$ or structural breaks)

## Typography

The typography system pairs **Inter** for narrative context, UI controls, and academic structuring with **JetBrains Mono** for numerical values, financial figures, econometric operators, and p-value/t-statistic tables.

### Type Rules & Hierarchy
- **Strict Separation of Data & Prose**: Any statistical figure, date range, coefficient estimate, standard error, or matrix variable must be rendered in `JetBrains Mono` to ensure tabular alignment and mono-spaced column clarity on narrow mobile viewports.
- **Tabular Figures**: `font-feature-settings: "tnum" 1` must be globally enabled across both fonts to eliminate jitter during real-time data streaming or parameter recalculations.
- **Letter Spacing**: Use `-0.02em` on titles above 18px to enforce tight, authoritative academic headlines. Micro-labels (`label-sm`, `label-md`) use `+0.04em` tracking for readability in dark, low-opacity contexts.

## Layout & Spacing

Designed primarily for mobile screen dimensions ($360\text{px}$ to $430\text{px}$ viewport widths), the layout adopts a compact 4-column fluid mobile grid that expands to a 6-column presentation on larger mobile displays and foldable devices.

### Structural Parameters
- **Screen Margin**: Fixed `1rem` (16px) left/right safety margins preserve precious horizontal charting real estate while respecting bezel boundaries and gesture navigation bars.
- **Grid Gutter**: `0.75rem` (12px) column gutters ensure that paired metrics (e.g., $R^2$ paired with Adjusted $R^2$) sit comfortably side-by-side on 375px screens.
- **Vertical Rhythm**: All spacing follows an 4px baseline rhythm (`space-xs` = 4px, `space-sm` = 8px, `space-md` = 12px, `space-lg` = 20px, `space-xl` = 28px).
- **Mobile Reflow Constraints**: Chart widgets span full 4-columns; metric badges collapse into dual 2-column or 3-column micro-grids. Multi-variable OLS regression tables stack parameters horizontally with horizontal scroll capability or vertical accordion drawers.

## Elevation & Depth

The design system uses **Tonal Layering** accompanied by **Subtle Luminescent Borders** rather than standard diffuse drop shadows. This creates a focused, high-precision laboratory environment.

### Elevation Hierarchy
1. **Level 0 (Canvas Base)**: `#070B14`. Raw substrate background.
2. **Level 1 (Card & Module Layer)**: `#0E1726` with a uniform 1px solid stroke of `rgba(255, 255, 255, 0.06)`. Used for forecast summary cards, regression parameter blocks, and variable lists.
3. **Level 2 (Active/Selected Card & Overlays)**: `#152238` with an active boundary stroke of `rgba(0, 229, 255, 0.35)` and a micro ambient inner glow: `0 0 16px rgba(0, 229, 255, 0.08)`.
4. **Level 3 (Sticky Bottom Bars & Modal Drawers)**: `#0E1726` with a top boundary line of `rgba(255, 255, 255, 0.12)`, supported by `backdrop-filter: blur(16px)` and deep ground shadow `0 -8px 24px rgba(0, 0, 0, 0.5)`.

### Optical Highlights
- Shadows are never pure black; they carry a slight navy tint (`rgba(3, 7, 18, 0.6)`).
- Interactive econometric threshold indicators project a subtle 4px radial bloom in their respective accent color (`#00E5FF` for primary, `#FFB300` for warning bounds).

## Shapes

The design system maintains a **Soft / Semi-Technical Geometry** (`roundedness: 1`), conveying mathematical structure, engineered precision, and modern software ergonomics.

### Corner Radius System
- **Core Elements & Inputs (`0.25rem` / 4px)**: Input fields, regression parameter tags, inline data badges, and progress tracks. Sharp enough to feel industrial and precise.
- **Card Containers & Modules (`0.5rem` / 8px)**: Chart containers, metric modules, model diagnostics panels, and bottom sheets.
- **Interactive Buttons & Selectors (`0.375rem` / 6px)**: Action buttons, variable toggle chips, and econometric transformation controls.
- **Status Pills & Confidence Chips**: Full pill roundedness (`9999px`) exclusively reserved for binary indicators, e.g., model validation statuses (`"H₀ REDDEDİLDİ"`, `"OLS DÜZEYİ: GÜVENİLİR"`).

## Components

### 1. Buttons
- **Primary (Forecast Trigger / Run EKK)**: Solid `#00E5FF` background with `#070B14` bold text (`fontFamily: "Inter"`, `fontWeight: 600`). Active press introduces a scale-down of `0.98` and a cyan luminescence.
- **Secondary (Parameter Tuning / Export)**: Ghost button with `#152238` fill, 1px border `rgba(0, 229, 255, 0.25)`, and `#00E5FF` text.
- **Danger (Reset Model / Drop Variable)**: Translucent ruby fill `rgba(255, 82, 82, 0.12)` with `#FF5252` border and label.

### 2. Metric Badges & Status Pills
- **Econometric Status Pill**: Height of 22px, `rounded-full`, with internal padding `0.2rem 0.5rem`. Contains a pulsing 6px dot:
  - Valid OLS Model: Emerald dot with `rgba(0, 230, 118, 0.12)` fill.
  - Heteroskedasticity / Multicollinearity Alert: Amber dot with `rgba(255, 179, 0, 0.12)` fill.
- **Coefficient Badges**: JetBrains Mono font (`label-sm`), displaying variable names ($X_1, X_2$) in Slate (`#8E9EB5`) alongside bold calculated coefficients in `#F0F4FC`.

### 3. Cards & Analytical Containers
- Built on Surface Tier 1 (`#0E1726`) with 12px internal padding (`space-md`).
- Header row contains the variable name, TÜBİTAK 2209-A dataset tag, and a 3-dot contextual action trigger.
- Cards maintain zero elevation shadows by default; hierarchy is defined purely by border brightness and nested surface contrast.

### 4. Forecast & Confidence Band Displays
- Main trendline drawn with 2px stroke in `#00E5FF`.
- Upper and lower bounds ($95\%$ confidence interval) bounded by `#FFB300` dashed 1px stroke with an intra-band fill of `rgba(255, 179, 0, 0.06)`.
- Crosshair scrubbers highlight mobile touch points showing exact timestamp, predicted value, and error margin in a floating tooltip pill.

### 5. Input Fields & Parameter Steppers
- Background of `#152238` with 1px border `rgba(255, 255, 255, 0.1)`.
- Focus state activates a 1px border in `#00E5FF` with a subtle outline glow.
- Labels are positioned strictly above the inputs in `Inter` 11px uppercase (`#8E9EB5`).

### 6. Econometric Data Table (Mobile Optimized)
- Alternating subtle rows (`transparent` vs `rgba(255, 255, 255, 0.02)`).
- Sticky left column for variable labels ($\beta_0, \beta_1, \dots$); horizontal swipe for statistical columns: Std Error, t-Stat, P>|t|, [0.025 - 0.975].
- Numerical entries rendered strictly in tabular `JetBrains Mono`.