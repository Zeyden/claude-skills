---
name: bdui-sanity
description: BDUI Sanity CMS page building and widget configuration for Tabby. Widget catalog (BDUIText, BDUISupercell, BDUIInformer, etc.), styling (BDUIStyleV1Output), Sanity page structure, Lokalize localisation, enrichment backends, and landing page creation. Use when configuring BDUI pages in Sanity, selecting widgets, setting up styles/gradients/insets, or understanding BDUI widget fields and their JSON contracts.
---

# BDUI Sanity CMS — Widget System & Page Building

## Mental Model

```
Sanity Page (slug: "bdui_money_tab")
  │
  ├── Navbar
  │   ├── Android variant: background "transparent"
  │   └── iOS variant: background "solid"
  │
  ├── Page Builder (ordered list of widgets)
  │   ├── BDUIVerticalList (container)
  │   │   ├── BDUIHeading (gradient bg + image + title)
  │   │   ├── BDUIText (body copy)
  │   │   ├── BDUISupercell (icon + text + action)
  │   │   └── BDUIAccordion (FAQ items)
  │   │
  │   ├── BDUIVerticalList (another section)
  │   │   └── ...widgets...
  │   │
  │   └── BDUIDivider
  │
  └── Sticky Footer
      └── BDUIButton (CTA)
```

## Input/Output Architecture

Every BDUI component has two schemas defined in OpenAPI contracts:

- **`*V1Input`** — Configuration from Sanity CMS. User-facing strings use locale keys. Polymorphic fields use `type: array` with `maxItems: 1` (Sanity CMS limitation for oneOf).
- **`*V1Output`** — Processed result sent to mobile apps. Locale keys are resolved to text. Polymorphic fields are direct objects.

The Go backend's `.Output(localizer, language)` method converts Input → Output at render time.

**Example:**
```
Input:  { "text": { "_type": "localisedField", "key": "welcome.title" } }
Output: { "text": { "resolved": "Welcome to Tabby" } }
```

## Widget Catalog

### Base Widget Fields (every widget inherits)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_type` | string | Yes | Widget type discriminator |
| `_key` | string | Yes | Unique key within page |
| `widgetID` | string | Yes | Semantic ID for backend handler routing |
| `bduiStyle` | BDUIStyleV1 | No | Visual styling |
| `interactions` | InteractionsV1 | No | Tap handlers |
| `lifecycleActions` | LifecycleActionsV1 | Yes | `onView` / `onDestroy` event actions |
| `analytics` | AnalyticsV1 | No | Event tracking parameters |

### Text & Typography

| Widget | Key Fields | Description |
|--------|-----------|-------------|
| **BDUIText** | `text` (localised, req), `color` (req), `typography` (req), `align`, `lineLimit` | Body text with styling |
| **BDUIHeading** | `title` (localised, req), `style` (heading1/heading2/headingXL, req), `subtitle`, `button`, `trailingIcon`, `onTap`, `color`, `headingMaxLines` | Section heading with optional decorations |
| **BDUITextLine** | Leading/trailing icon arrays, text objects with colour/typography | Key-value text row |

### Containers

| Widget | Key Fields | Description |
|--------|-----------|-------------|
| **BDUIVerticalList** | `children` (array of 24 widget types) | Vertical stack — primary layout container |
| **BDUIHorizontalList** | `children`, `alignment` (start/center/end), `spacing` | Horizontal scrollable list |

The `children` array accepts any of the 24+ supported widget types via discriminated union.

### Cells / Rows

| Widget | Key Fields | Description |
|--------|-----------|-------------|
| **BDUISupercell** | `body` (req), `layout` (default/inverted/rows, req), `leadIcon` (6 variants, req), `actions` (req), `control`, `extra`, `subtitle`, `subtitle2`, `subtitle3`, `subtitle4`, `styleOptions` | Versatile row — see detailed reference below |
| **BDUIMicrocell** | Lead/trail text lines | Compact row variant |
| **BDUIMerchantSpot** | Merchant logo, overlay, size variants | Merchant-branded cell |
| **BDUIDoubleSpot** | Two overlaid spots (Avatar/Icon/Merchant), size variants | Two-column spot layout |

### Images

| Widget | Key Fields | Description |
|--------|-----------|-------------|
| **BDUIImage** | `image` (Sanity asset ref, req), `contentMode` (fit/fill/center, req) | Image display |
| **BDUIIconSpot** | `shape` (CIRCLE/SQUARE), `size` enum, `backgroundColor` | Icon with container |
| **BDUIAvatarSpot** | Size (XXL/XL/L/M/S/XS/XXS), badge, image/initials | User avatar |

### Interactive

| Widget | Key Fields | Description |
|--------|-----------|-------------|
| **BDUIButton** | `title` (localised, req), `buttonType` (primary/secondary/tertiary, req), `size` (S/M/L/XL, req), `enabled` (req), `progress`, `leadingIcon`, `trailingIcon`, `actions` | Action button |
| **BDUIMicroButton** | `title`, `enabled`, colours | Compact button |
| **BDUIChip** | Default/List/Options variants (discriminated) | Selectable chip |
| **BDUIChipCarousel** | Horizontal chips | Scrollable chip selector |
| **BDUIChipMultiline** | Title, support text | Multiline chip grid |
| **BDUIInputField** | `inputType` (7 variants), `isEnabled`, `textDirection`, `value`, `placeholder`, `label`, `errorText`, `supportText`, `prefix` | Text input — see form validation reference |
| **SwipeButton** | Swipe-to-confirm | Swipe action |
| **Checkbox** / **RadioButton** / **Switch** | Toggle states | Selection controls |
| **DropdownField** / **Selector** / **OTP** | Selection/input variants | Specialised inputs |

### Informational

| Widget | Key Fields | Description |
|--------|-----------|-------------|
| **BDUIInformer** | `title` (localised, req), `actions` (req), `subtitle`, `leadingIcon`, `trail` (icon/button/chevron), `bodyButton`, `style` (outlined/filled), `styleOptions` | Info/warning/error banner |
| **BDUIInfoPrompt** | Styled variants, trail variants | Information prompt |
| **BDUIBadge** | `backgroundColor` (req), `size` (S/M, req), `text` (req), `textColor` (req), `icon` | Small badge/tag |
| **Snackbar** / **Tooltip** | Temporary notifications | Contextual feedback |

### Display

| Widget | Key Fields | Description |
|--------|-----------|-------------|
| **BDUIDivider** | `color` | Visual separator |
| **BDUITrain** | `items[]` with `text`, `numberOfLines`, `color`, `startIcon`, `endIcon`, `typography`, `actions` | Step/progress indicator |
| **BDUITimeline** | `steps[]` with `content` (VerticalList), `expandable`, `lineColor`, `stepIcon`, `title`, `timestamp` | Timeline/step view |
| **BDUINavBar** | `customViews`, `hideOnScroll`, `overlay`, `style`, `trailing`, `leading`, `title` | Navigation bar |

### Structural

| Widget | Key Fields | Description |
|--------|-----------|-------------|
| **BDUIAccordion** | `items[]` with `heading` + `text` (both localised), `isFirstItemExpanded` | Expandable FAQ/details |

## Style System (BDUIStyleV1)

The universal styling object applied to any widget via the `bduiStyle` field:

```json
{
  "backgroundColor": "#FFFFFF",
  "backgroundGradient": {
    "gradientType": "linear",
    "colorStops": [
      { "_key": "stop1", "color": "#6B4EFF", "offset": 0 },
      { "_key": "stop2", "color": "#3B82F6", "offset": 0.5 },
      { "_key": "stop3", "color": "#06B6D4", "offset": 1 }
    ],
    "angle": 180
  },
  "border": { "color": "#E0E0E0" },
  "inset": {
    "top": 16,
    "bottom": 16,
    "leading": 16,
    "trailing": 16
  },
  "roundedCorners": {
    "leadingTop": 12,
    "trailingTop": 12,
    "leadingBottom": 12,
    "trailingBottom": 12
  },
  "width": null,
  "height": null,
  "minWidth": null,
  "minHeight": null,
  "maxWidth": null,
  "maxHeight": null,
  "weight": 1,
  "fillParentWidth": false,
  "fillParentHeight": false,
  "attributes": [
    { "name": "align", "value": "center" },
    { "name": "clipToBounds", "value": "true" }
  ]
}
```

### Style Fields Reference

| Field | Type | Description |
|-------|------|-------------|
| `backgroundColor` | ColorV1 (hex) | Solid background colour |
| `backgroundGradient` | GradientV1 | Linear gradient with colour stops |
| `backgroundGradient.gradientType` | string | Always `"linear"` |
| `backgroundGradient.colorStops[]` | array | `{ _key, color (hex), offset (0.0-1.0) }` |
| `backgroundGradient.angle` | number | Degrees 0-360 (0=top-to-bottom, 90=left-to-right) |
| `border` | BorderV1 | Border with `color` property |
| `inset` | InsetV1 | Padding: `top`, `bottom`, `leading`, `trailing` (dp/pt) |
| `roundedCorners` | CornersV1 | Per-corner radius: `leadingTop`, `trailingTop`, `leadingBottom`, `trailingBottom` |
| `width` / `height` | integer? | Fixed dimensions (null = auto). Minimum 0. |
| `minWidth` / `minHeight` | integer? | Minimum size constraints |
| `maxWidth` / `maxHeight` | integer? | Maximum size constraints |
| `weight` | integer | Flex weight in parent container (like CSS flex-grow). Min 0 (Input), min 1 (Output). |
| `fillParentWidth` | boolean | Expand to fill parent width (default: false) |
| `fillParentHeight` | boolean | Expand to fill parent height (default: false) |
| `attributes[]` | array | Name-value pairs. Name pattern: `^[a-zA-Z][a-zA-Z0-9_]*$` |

## Actions System (8 Types)

Actions define widget behaviour on interaction. See `references/tap-actions.md` for interaction configuration.

| Action Type | Key Fields | Description |
|-------------|-----------|-------------|
| **script** | `id` (req), `script` (req) | Execute client-side JavaScript |
| **navigate** | `navigationType` (forward/back, req), `url` (req), `attributes` | Navigate to screen/URL |
| **sendAnalytics** | `eventName` (req), `attributes` (req) | Send analytics event |
| **sendRequest** | `url` (req), `attributes` | HTTP API request (GET/POST/PUT/DELETE/PATCH) |
| **showTooltip** | `text` (localised, req), `attributes` (req) | Display tooltip |
| **custom** | `customType` (req) | Custom action handler |
| **closeWidget** | `widgetId` | Close current or specified widget |
| **legacy** | — | Backward compatibility |

### Lifecycle Actions

Applied via `lifecycleActions` on any widget:

| Event | Trigger | Common Use |
|-------|---------|-----------|
| `onView` | Widget enters viewport | Analytics impressions, lazy data loading |
| `onDestroy` | Widget removed from tree | Cleanup, state reset |

## Detailed Widget Reference: BDUISupercell

The most versatile row widget with 6 lead icon variants:

```
┌─────────────────────────────────────────────────┐
│ [leadIcon]  Body Text              [extra] [>]  │
│             Subtitle Text                       │
│             Subtitle2                           │
│             Subtitle3                           │
│             Subtitle4                           │
└─────────────────────────────────────────────────┘
```

### LeadIcon Variants (discriminated union)

| Variant | Description |
|---------|-------------|
| `number` | Numbered circle (e.g., step 1, 2, 3) |
| `icon` | Standard icon with optional notification dot, progress |
| `merchant` | Merchant logo with overlay support |
| `avatar` | User avatar with size variants |
| `double` | Two overlaid spots (Avatar/Icon/Merchant) |
| `plain` | No icon |

### Control Variants (trailing)

| Variant | Description |
|---------|-------------|
| `chevron` | Right-pointing arrow (navigation indicator) |
| `externalLink` | External link icon |
| `button` | Inline button |

### Extra Variants (trailing, before control)

| Variant | Description |
|---------|-------------|
| `badge` | Status badge |
| `counter` | Numeric counter |
| `icon` | Trailing icon |

## Detailed Widget Reference: BDUIInformer

```
┌─────────────────────────────────────────────────┐
│ [icon]  Title Text                    [trail]   │
│         Subtitle text goes here                 │
│         [bodyButton]                            │
└─────────────────────────────────────────────────┘
```

### Style Options

| Style | Appearance |
|-------|-----------|
| `outlined` | Border only, no fill |
| `filled` | Solid background |

### Styled Variants (for OutputsideOptions)

| Variant | Use Case |
|---------|----------|
| Neutral | General information |
| Positive | Success messages |
| Warning | Warnings |
| Error | Error states |
| Custom | Custom colour overrides |

### Trail Variants

| Variant | Description |
|---------|-------------|
| `icon` | Trailing icon (e.g., info, close) |
| `chevron` | Navigation chevron |
| `button` | Inline action button |

## How to Create a Landing Page in Sanity

### Step 1: Prepare Lokalize Keys

Import localisation keys in Lokalize with the `layout` tag:
- `landing_hero_title` → "Welcome to Tabby"
- `landing_hero_subtitle` → "Shop now, pay later"
- `landing_benefit_1` → "Split in 4"
- `landing_faq_q1` → "What is Tabby?"
- etc.

### Step 2: Create Page in Sanity Studio

1. Navigate to **Pages** in Sanity Studio
2. Create a new page with your slug (e.g., `bdui_promo_landing`)
3. Configure platform targeting if needed

### Step 3: Add Navbar

Configure per platform:
- **Android**: style `{ background: "transparent", buttons: "floating" }` — overlays hero content
- **iOS**: style `{ background: "solid", buttons: "transparent" }` — standard nav bar

### Step 4: Build Content Sections

**Hero Section** — gradient background with image and text:
```
BDUIVerticalList
  bduiStyle:
    backgroundGradient: { gradientType: "linear", angle: 180, colorStops: [...] }
    inset: { top: 40, bottom: 24, leading: 16, trailing: 16 }
  children:
    ├── BDUIImage (hero illustration, contentMode: "fit")
    ├── BDUIHeading (style: "headingXL", title: hero_title, color: "#FFFFFF")
    └── BDUIText (typography: "bodyLRegular", text: hero_subtitle, color: "#FFFFFF")
```

**Benefits Section** — white card with supercells:
```
BDUIVerticalList
  bduiStyle:
    backgroundColor: "#FFFFFF"
    inset: { top: 16, bottom: 16, leading: 16, trailing: 16 }
    roundedCorners: { leadingTop: 16, trailingTop: 16, leadingBottom: 16, trailingBottom: 16 }
  children:
    ├── BDUIHeading (style: "heading1", title: "Benefits")
    ├── BDUISupercell (layout: "default", leadIcon: icon, body: benefit_1, control: chevron)
    ├── BDUISupercell (layout: "default", leadIcon: icon, body: benefit_2, control: chevron)
    └── BDUISupercell (layout: "default", leadIcon: icon, body: benefit_3, control: chevron)
```

**FAQ Section** — accordion:
```
BDUIVerticalList
  bduiStyle: { inset: { top: 16, bottom: 16, leading: 16, trailing: 16 } }
  children:
    ├── BDUIHeading (style: "heading1", title: "FAQ")
    └── BDUIAccordion (isFirstItemExpanded: true, items: [...])
```

### Step 5: Add Sticky Footer

```
BDUIButton
  title: "Get Started"
  buttonType: "primary"
  size: "L"
  enabled: true
  actions: [{ _type: "navigate", navigationType: "forward", url: "tabby://signup" }]
```

### Step 6: Configure Enrichment Backend (if needed)

If widgets need dynamic server-side data, select the enrichment backend dropdown in Sanity. This maps to a Layout Service `BATCHED_WIDGETS` group that calls the Go backend.

## Enrichment Backends

Widgets needing server-side data enrichment are grouped into backend configurations:

| Backend Group | Description |
|--------------|-------------|
| `VCARD` | Virtual card data |
| `TABBY_SAVE_GROUP` | Savings features |
| `CUSTOMER_OPERATIONS_GROUP` | Customer operations |

The Layout Service batches widgets by their enrichment backend, makes a single gRPC call per group, and distributes results.

## JavaScript Actions (Script Type)

```json
{
  "_type": "script",
  "id": "toggle_visibility",
  "script": "state.count = (state.count || 0) + 1; return { show: state.count < 3 };"
}
```

**Can do**: Read/write widget state, return instructions (show/hide, update fields), simple computations.

**Cannot do**: Import modules, make network requests, create functions dynamically, access DOM, run async code.

## Localisation (BDUILocalisedFieldV1)

**Input** (Sanity config):
```json
{ "_type": "localisedField", "key": "welcome.title" }
```

**Output** (mobile receives):
```json
{ "resolved": "Welcome to Tabby" }
```

Key pattern: `^[a-zA-Z0-9_.]+$` — managed in Lokalize, imported into Sanity with `layout` tag.

## Typography System

Extensive typography variants (30+):

**V1 styles**: `HeadingXL`, `HeadingL`, `HeadingM`, `HeadingS`, `Body1TightRegular`, `Body1TightBold`, `Body1LooseRegular`, `Body2TightRegular`, `Body2TightBold`, `Special`, `CaptionXS`, `CaptionS`, `CaptionM`

**V2 styles**: `HeadingH1`-`HeadingH6`, `Body1Tight`, `Body1Loose`, `Body2Tight`, `Body2Loose`, `CaptionXS`-`CaptionM`, `Special` variants

## Icon System

**Input** (Sanity): Sanity asset reference with `_ref` pattern `^image-[a-f0-9]{40}-[0-9]+x[0-9]+-[a-z]+$`

**Output** (mobile): CDN URL (`format: uri`), `applyTint` (boolean), `autoMirrored` (boolean), optional `tintColor`

## Delegation

- For **Go backend handlers, pipeline, preprocessors, postprocessors** → invoke `bdui-go`
- For **Compose UI rendering of BDUI widgets on mobile/desktop** → invoke `compose-expert`
