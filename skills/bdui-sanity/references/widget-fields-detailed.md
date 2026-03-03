# Complete Widget Field Reference

This document provides field-by-field specifications for every BDUI widget, sourced from the OpenAPI contracts in the bdui repository.

## Base Widget (BDUIWidgetV1)

All widgets inherit these fields:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_type` | string | Yes | Widget type discriminator |
| `_key` | string | Yes | Unique key within page |
| `widgetID` | string | Yes | Semantic ID for handler routing |
| `bduiStyle` | BDUIStyleV1 | No | Visual styling |
| `interactions` | InteractionsV1 | No | Tap handlers |
| `lifecycleActions` | LifecycleActionsV1 | Yes | onView / onDestroy |
| `analytics` | AnalyticsV1 | No | Event tracking params |

---

## BDUIText

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `text` | LocalisedField | Yes | Text content |
| `color` | ColorV1 (hex) | Yes | Text colour |
| `typography` | TypographyV1 | Yes | Font variant |
| `align` | enum | No | `start`, `center`, `end` |
| `lineLimit` | integer | No | Max lines (0 = unlimited) |

---

## BDUIHeading

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | LocalisedField | Yes | Heading text |
| `style` | enum | Yes | `heading1`, `heading2`, `headingXL` |
| `subtitle` | LocalisedField | No | Subheading |
| `button` | object | No | Trailing button with `title` (LocalisedField) and `actions` |
| `trailingIcon` | IconV1 | No | Trailing icon |
| `onTap` | object | No | `{ target: "full"/"title", actions: [...] }` |
| `color` | ColorV1 | No | Text colour |
| `headingMaxLines` | integer | No | Max lines for title |

---

## BDUIImage

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `image` | ImageField | Yes | Sanity asset reference (`_ref` pattern: `^image-[a-f0-9]{40}-[0-9]+x[0-9]+-[a-z]+$`) |
| `contentMode` | enum | Yes | `fit`, `fill`, `center` |

**Output**: `image` becomes a URL string pointing to CDN.

---

## BDUIButton

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | LocalisedField | Yes | Button text |
| `buttonType` | enum | Yes | `primary`, `secondary`, `tertiary` |
| `size` | enum | Yes | `S`, `M`, `L`, `XL` |
| `enabled` | boolean | Yes | Whether button is interactive |
| `progress` | boolean | Yes | Show loading indicator |
| `leadingIcon` | IconV1 | No | Icon before text |
| `trailingIcon` | IconV1 | No | Icon after text |
| `actions` | ActionsV1 | No | Tap actions |

---

## BDUISupercell

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `body` | TextTrainItems | Yes | Primary text (array of text items) |
| `layout` | enum | Yes | `default`, `inverted`, `rows` |
| `leadIcon` | discriminated union | Yes | 6 variants (see below) |
| `actions` | ActionsV1 | Yes | Primary tap action |
| `subtitle` | TextTrainItems | No | Subtitle line 1 |
| `subtitle2` | TextTrainItems | No | Subtitle line 2 |
| `subtitle3` | TextTrainItems | No | Subtitle line 3 |
| `subtitle4` | TextTrainItems | No | Subtitle line 4 |
| `control` | discriminated union | No | Trailing control |
| `extra` | discriminated union | No | Extra trailing element |
| `styleOptions` | object | No | Colour/text style overrides |

### LeadIcon Variants

| `_type` | Fields |
|---------|--------|
| `number` | `number` (integer), `backgroundColor`, `textColor` |
| `icon` | `icon` (IconV1), `backgroundColor`, `cornerRadius`, `notificationDot`, `progress` |
| `merchant` | Merchant logo with overlay |
| `avatar` | Avatar with size enum |
| `double` | Two overlaid spots (Avatar/Icon/Merchant) |
| `plain` | No icon content |

### Control Variants

| `_type` | Description |
|---------|-------------|
| `chevron` | Right arrow, navigation indicator |
| `externalLink` | External link icon |
| `button` | Inline button with title and actions |

### Extra Variants

| `_type` | Fields |
|---------|--------|
| `badge` | `text`, `backgroundColor`, `textColor`, `size` (S/M) |
| `counter` | Numeric counter display |
| `icon` | Trailing icon |

---

## BDUIInformer

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | LocalisedField | Yes | Primary text |
| `actions` | ActionsV1 | Yes | Tap actions |
| `subtitle` | LocalisedField | No | Supporting text |
| `leadingIcon` | IconV1 | No | Left icon |
| `trail` | discriminated union | No | Trailing element |
| `bodyButton` | object | No | Button with `title`, `actions`, `progress` |
| `style` | enum | No | `outlined`, `filled` |
| `styleOptions` | object | No | Colour/border overrides |

### Trail Variants

| `_type` | Description |
|---------|-------------|
| `icon` | Trailing icon (e.g., close, info) |
| `chevron` | Navigation chevron |
| `button` | Inline action button |

### Styled Variants (styleOptions)

| Variant | Use Case |
|---------|----------|
| Neutral | General information |
| Positive | Success messages |
| Warning | Warnings |
| Error | Error states |
| Custom | Custom colour overrides |

---

## BDUIAccordion

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `isFirstItemExpanded` | boolean | Yes | Whether first item starts expanded |
| `items` | array | Yes | Accordion items |

### Accordion Item

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_type` | string | Yes | Item type |
| `_key` | string | Yes | Unique key |
| `heading` | LocalisedField | Yes | Question/heading text |
| `text` | LocalisedField | Yes | Answer/body text |

---

## BDUIVerticalList

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `children` | ChildWidgetV1[] | Yes | Array of child widgets (24 types supported) |

Supported child types: Text, Heading, Image, Button, MicroButton, Supercell, Microcell, Informer, InfoPrompt, Accordion, Badge, Chip, ChipCarousel, ChipMultiline, Divider, TextLine, Avatar, IconSpot, MerchantSpot, AvatarSpot, DoubleSpot, Train, Timeline, InputField, NavBar, HorizontalList.

---

## BDUIHorizontalList

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `children` | ChildWidgetV1[] | Yes | Array of child widgets |
| `alignment` | enum | No | `start`, `center`, `end` |
| `spacing` | integer | No | Space between items |

---

## BDUIDivider

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `color` | ColorV1 | No | Divider colour |

---

## BDUIBadge

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `backgroundColor` | ColorV1 | Yes | Badge background |
| `size` | enum | Yes | `S`, `M` |
| `text` | LocalisedField | Yes | Badge text |
| `textColor` | ColorV1 | Yes | Text colour |
| `icon` | IconV1 | No | Optional icon |

---

## BDUIAvatar

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `size` | enum | Yes | `XXL`, `XL`, `L`, `M`, `S`, `XS`, `XXS` |
| `badge` | object | No | Badge overlay |
| `image` | ImageField | No | Avatar image (falls back to initials) |

---

## BDUIIconSpot

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `shape` | enum | Yes | `CIRCLE`, `SQUARE` |
| `size` | enum | Yes | Size variant |
| `icon` | IconV1 | Yes | Icon content |
| `backgroundColor` | ColorV1 | No | Background colour |

---

## BDUIDoubleSpot

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `spot1` | discriminated union | Yes | First spot (Avatar/Icon/Merchant) |
| `spot2` | discriminated union | Yes | Second spot (Avatar/Icon/Merchant) |
| `size` | enum | Yes | Size variant |

---

## BDUIMicroButton

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | LocalisedField | Yes | Button text |
| `enabled` | boolean | Yes | Interactive state |
| `backgroundColor` | ColorV1 | No | Background |
| `textColor` | ColorV1 | No | Text colour |

---

## BDUIChip

Uses discriminated union with 3 variants:

| Variant | `_type` | Description |
|---------|---------|-------------|
| Default | `default` | Standard chip |
| List | `list` | List-based chip |
| Options | `options` | Options chip |

---

## BDUITrain

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `items` | array | Yes | Train items |

### Train Item

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_type` | string | Yes | Item type |
| `_key` | string | Yes | Unique key |
| `text` | LocalisedField | Yes | Item text |
| `numberOfLines` | integer | Yes | Line count |
| `actions` | ActionsV1 | Yes | Tap actions |
| `color` | ColorV1 | No | Text colour |
| `startIcon` | IconV1 | No | Leading icon |
| `endIcon` | IconV1 | No | Trailing icon |
| `typography` | TypographyV1 | No | Font variant |

---

## BDUITimeline

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `steps` | array | Yes | Timeline steps |

### Timeline Step

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `content` | BDUIVerticalListV1 | Yes | Step content (nested widget tree) |
| `expandable` | boolean | Yes | Whether step can expand/collapse |
| `lineColor` | ColorV1 | Yes | Connector line colour |
| `stepIcon` | TimelineStepIcon | Yes | Step indicator icon |
| `title` | LocalisedField | Yes | Step title |
| `inset` | InsetV1 | No | Content padding |
| `timestamp` | LocalisedField | No | Time label |

### TimelineStepIcon

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `backgroundColor` | ColorV1 | Yes | Icon background |
| `borderColor` | ColorV1 | Yes | Icon border |
| `icon` | IconV1 | Yes | Icon content |

---

## BDUINavBar

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `customViews` | array | Yes | Custom view containers |
| `hideOnScroll` | boolean | Yes | Auto-hide on scroll |
| `overlay` | boolean | Yes | Overlay mode |
| `style` | NavBarStyleV1 | Yes | Nav bar styling |
| `trailing` | NavBarButtonV1[] | Yes | Trailing buttons |
| `anchorWidgetId` | string | No | Scroll anchor widget |
| `leading` | NavBarButtonV1 | No | Leading button (back) |
| `title` | NavBarTitleV1 | No | Title configuration |

### NavBarStyleV1

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `background` | enum | Yes | `solid`, `transparent`, `dynamic` |
| `buttons` | enum | Yes | `transparent`, `floating`, `dynamicToFloating`, `dynamicToTransparent` |

### NavBarTitleV1

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `isLarge` | boolean | Yes | Large title mode |
| `title` | LocalisedField | Yes | Title text |
| `visibilityStrategy` | VisibilityStrategyV1 | Yes | Show/hide behaviour |

### VisibilityStrategyV1

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `visibilityType` | enum | Yes | `alwaysVisible`, `visibleOnTop`, `visibleOnScroll` |
| `thresholdOffset` | number | Yes | Scroll threshold for visibility change |

### NavBarButtonV1

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Button identifier |
| `actions` | ActionsV1 | Yes | Tap actions |
| `badge` | boolean | Yes | Show notification badge |
| `icon` | IconV1 | Yes | Button icon |

### NavBarCustomViewContainerV1

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Container identifier |
| `position` | enum | Yes | `leading`, `center`, `trailing` |
| `visibilityStrategy` | VisibilityStrategyV1 | Yes | Show/hide behaviour |
| `widget` | array | Yes | Supported: Heading, Text, Image, Badge |

---

## BDUIInputField

The most complex widget (1200+ lines of contract). See `form-validation.md` in bdui-go references for full details.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `inputType` | discriminated union (array, maxItems 1) | Yes | 7 variants: text, number, phone, email, password, pin, decimal |
| `isEnabled` | boolean | Yes | Interactive state |
| `textDirection` | enum | Yes | `ltr`, `rtl`, `content` |
| `trailIcon` | InputIconV1 | Yes | Trailing icon with actions |
| `value` | string | Yes | Current input value |
| `errorText` | LocalisedField | No | Error message |
| `header` | LocalisedField | No | Field header |
| `label` | LocalisedField | No | Field label |
| `leadIcon` | discriminated union (array, maxItems 1) | No | InputFieldIcon or ClearTextButton |
| `meta` | object | No | Arbitrary metadata |
| `placeholder` | LocalisedField | No | Placeholder text |
| `prefix` | InputPrefixV1 | No | `{ direction, text }` |
| `supportText` | discriminated union (array, maxItems 1) | No | Error or Hint text |
| `inputInteraction` | object | No | `{ showKeyboardOnFocus: boolean }` |

---

## BDUITextLine

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `leadingIcons` | IconV1[] | No | Leading icon array |
| `trailingIcons` | IconV1[] | No | Trailing icon array |
| `textItems` | array | Yes | Text objects with colour and typography |

---

## BDUIMicrocell

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `lead` | TextLineV1 | Yes | Leading text line |
| `trail` | TextLineV1 | No | Trailing text line |

---

## BDUIInfoPrompt

Similar to BDUIInformer with additional styled variants and trail variants.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | LocalisedField | Yes | Primary text |
| `actions` | ActionsV1 | Yes | Tap actions |
| `styledVariant` | discriminated union | No | Neutral/Positive/Warning/Error/Custom |
| `trail` | discriminated union | No | Close/Chevron trailing element |
