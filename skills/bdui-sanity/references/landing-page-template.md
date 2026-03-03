# Landing Page Template — Step-by-Step Sanity Configuration

This template shows how to build a complete BDUI landing page in Sanity with exact values for spacing, gradients, typography, and widget configuration.

## Page Structure Overview

```
Page (slug: "bdui_promo_landing")
  ├── BDUINavBar (transparent overlay on hero)
  ├── BDUIVerticalList [Hero Section]
  │   ├── BDUIImage (hero illustration)
  │   ├── BDUIHeading (headline)
  │   └── BDUIText (subtitle)
  ├── BDUIVerticalList [Benefits Section]
  │   ├── BDUIHeading (section title)
  │   ├── BDUISupercell (benefit 1)
  │   ├── BDUISupercell (benefit 2)
  │   └── BDUISupercell (benefit 3)
  ├── BDUIVerticalList [FAQ Section]
  │   ├── BDUIHeading (section title)
  │   └── BDUIAccordion (FAQ items)
  └── BDUIButton [Sticky Footer CTA]
```

---

## Step 1: Prepare Lokalize Keys

Import these keys in Lokalize with the `layout` tag:

| Key | English | Arabic |
|-----|---------|--------|
| `promo.hero_title` | Welcome to Tabby | مرحبًا بك في تابي |
| `promo.hero_subtitle` | Shop now, pay later | تسوّق الآن وادفع لاحقًا |
| `promo.benefits_title` | Benefits | المزايا |
| `promo.benefit_1` | Split in 4 payments | قسّم على 4 دفعات |
| `promo.benefit_1_sub` | No interest, no fees | بدون فوائد أو رسوم |
| `promo.benefit_2` | Pay next month | ادفع الشهر القادم |
| `promo.benefit_2_sub` | Full amount in 30 days | المبلغ الكامل خلال 30 يومًا |
| `promo.benefit_3` | Shop at 30,000+ stores | تسوّق في أكثر من 30,000 متجر |
| `promo.benefit_3_sub` | Online and in-store | أونلاين وفي المتاجر |
| `promo.faq_title` | FAQ | الأسئلة الشائعة |
| `promo.faq_q1` | What is Tabby? | ما هو تابي؟ |
| `promo.faq_a1` | Tabby lets you split... | تابي يتيح لك تقسيم... |
| `promo.faq_q2` | How do I pay? | كيف أدفع؟ |
| `promo.faq_a2` | Download the app... | حمّل التطبيق... |
| `promo.cta_button` | Get Started | ابدأ الآن |

---

## Step 2: NavBar

```json
{
  "_type": "BDUINavBar",
  "hideOnScroll": false,
  "overlay": true,
  "style": {
    "background": "transparent",
    "buttons": "floating"
  },
  "trailing": [
    {
      "id": "close_btn",
      "badge": false,
      "icon": { "applyTint": true, "autoMirrored": false, "image": { "_ref": "close-icon-ref" } },
      "actions": [{ "_type": "navigate", "navigationType": "back", "url": "" }]
    }
  ],
  "customViews": [],
  "title": null,
  "leading": null
}
```

**Platform notes:**
- Android: `background: "transparent"` overlays hero gradient
- iOS: If you want a solid bar, use `background: "solid"`, `buttons: "transparent"`

---

## Step 3: Hero Section

```json
{
  "_type": "BDUIVerticalList",
  "bduiStyle": {
    "backgroundGradient": {
      "gradientType": "linear",
      "angle": 180,
      "colorStops": [
        { "_key": "s1", "color": "#3B1F8E", "offset": 0 },
        { "_key": "s2", "color": "#6B4EFF", "offset": 0.5 },
        { "_key": "s3", "color": "#8B6FFF", "offset": 1 }
      ]
    },
    "inset": { "top": 80, "bottom": 32, "leading": 24, "trailing": 24 },
    "roundedCorners": {
      "leadingTop": 0, "trailingTop": 0,
      "leadingBottom": 24, "trailingBottom": 24
    }
  },
  "children": [
    {
      "_type": "BDUIImage",
      "_key": "hero_img",
      "contentMode": "fit",
      "image": { "_type": "image", "asset": { "_ref": "image-hero-illustration-ref" } },
      "bduiStyle": {
        "height": 200,
        "inset": { "bottom": 24 }
      }
    },
    {
      "_type": "BDUIHeading",
      "_key": "hero_heading",
      "style": "headingXL",
      "title": { "_type": "localisedField", "key": "promo.hero_title" },
      "color": "#FFFFFF",
      "bduiStyle": { "inset": { "bottom": 8 } }
    },
    {
      "_type": "BDUIText",
      "_key": "hero_subtitle",
      "text": { "_type": "localisedField", "key": "promo.hero_subtitle" },
      "typography": "Body1LooseRegular",
      "color": "#FFFFFFCC",
      "align": "start"
    }
  ]
}
```

**Key values:**
- Hero top inset `80` accounts for navbar overlay height
- Gradient angle `180` = bottom-to-top (dark at top, light at bottom)
- Bottom rounded corners `24` for card-like appearance
- Image height `200` for hero illustration
- Heading-to-subtitle gap via inset bottom `8`

---

## Step 4: Benefits Section

```json
{
  "_type": "BDUIVerticalList",
  "bduiStyle": {
    "backgroundColor": "#FFFFFF",
    "inset": { "top": 24, "bottom": 24, "leading": 16, "trailing": 16 },
    "roundedCorners": {
      "leadingTop": 16, "trailingTop": 16,
      "leadingBottom": 16, "trailingBottom": 16
    }
  },
  "children": [
    {
      "_type": "BDUIHeading",
      "_key": "benefits_title",
      "style": "heading1",
      "title": { "_type": "localisedField", "key": "promo.benefits_title" },
      "bduiStyle": { "inset": { "bottom": 16 } }
    },
    {
      "_type": "BDUISupercell",
      "_key": "benefit_1",
      "layout": "default",
      "leadIcon": [{
        "_type": "icon",
        "icon": { "applyTint": true, "autoMirrored": false, "image": { "_ref": "split-icon-ref" } },
        "backgroundColor": "#F0EBFF"
      }],
      "body": [{ "text": { "_type": "localisedField", "key": "promo.benefit_1" } }],
      "subtitle": [{ "text": { "_type": "localisedField", "key": "promo.benefit_1_sub" } }],
      "actions": [{ "_type": "navigate", "navigationType": "forward", "url": "tabby://split-details" }],
      "control": [{ "_type": "chevron" }]
    },
    {
      "_type": "BDUISupercell",
      "_key": "benefit_2",
      "layout": "default",
      "leadIcon": [{
        "_type": "icon",
        "icon": { "applyTint": true, "autoMirrored": false, "image": { "_ref": "calendar-icon-ref" } },
        "backgroundColor": "#E8F5E9"
      }],
      "body": [{ "text": { "_type": "localisedField", "key": "promo.benefit_2" } }],
      "subtitle": [{ "text": { "_type": "localisedField", "key": "promo.benefit_2_sub" } }],
      "actions": [{ "_type": "navigate", "navigationType": "forward", "url": "tabby://pay-later" }],
      "control": [{ "_type": "chevron" }]
    },
    {
      "_type": "BDUISupercell",
      "_key": "benefit_3",
      "layout": "default",
      "leadIcon": [{
        "_type": "icon",
        "icon": { "applyTint": true, "autoMirrored": false, "image": { "_ref": "store-icon-ref" } },
        "backgroundColor": "#E3F2FD"
      }],
      "body": [{ "text": { "_type": "localisedField", "key": "promo.benefit_3" } }],
      "subtitle": [{ "text": { "_type": "localisedField", "key": "promo.benefit_3_sub" } }],
      "actions": [{ "_type": "navigate", "navigationType": "forward", "url": "tabby://stores" }],
      "control": [{ "_type": "chevron" }]
    }
  ]
}
```

**Key patterns:**
- White card with `cornerRadius: 16` all sides
- Section heading with `inset.bottom: 16` gap to first cell
- Each supercell uses `leadIcon` type `icon` with coloured background
- `control: [{ _type: "chevron" }]` adds navigation arrow
- Note: Input polymorphic fields (leadIcon, control) use **array with maxItems 1** — Sanity CMS limitation

---

## Step 5: FAQ Section

```json
{
  "_type": "BDUIVerticalList",
  "bduiStyle": {
    "inset": { "top": 24, "bottom": 24, "leading": 16, "trailing": 16 }
  },
  "children": [
    {
      "_type": "BDUIHeading",
      "_key": "faq_title",
      "style": "heading1",
      "title": { "_type": "localisedField", "key": "promo.faq_title" },
      "bduiStyle": { "inset": { "bottom": 16 } }
    },
    {
      "_type": "BDUIAccordion",
      "_key": "faq_accordion",
      "isFirstItemExpanded": true,
      "items": [
        {
          "_type": "accordionItem",
          "_key": "faq_1",
          "heading": { "_type": "localisedField", "key": "promo.faq_q1" },
          "text": { "_type": "localisedField", "key": "promo.faq_a1" }
        },
        {
          "_type": "accordionItem",
          "_key": "faq_2",
          "heading": { "_type": "localisedField", "key": "promo.faq_q2" },
          "text": { "_type": "localisedField", "key": "promo.faq_a2" }
        }
      ]
    }
  ]
}
```

---

## Step 6: Sticky Footer CTA

```json
{
  "_type": "BDUIButton",
  "_key": "cta_button",
  "title": { "_type": "localisedField", "key": "promo.cta_button" },
  "buttonType": "primary",
  "size": "L",
  "enabled": true,
  "progress": false,
  "actions": [
    { "_type": "sendAnalytics", "eventName": "cta_tapped", "attributes": [{ "name": "page", "value": "promo_landing" }] },
    { "_type": "navigate", "navigationType": "forward", "url": "tabby://signup" }
  ],
  "bduiStyle": {
    "inset": { "top": 12, "bottom": 12, "leading": 16, "trailing": 16 }
  }
}
```

**Footer placement**: The button is configured as a sticky footer in the Sanity page builder, not nested inside a VerticalList.

---

## Common Spacing Reference

| Location | Value | Purpose |
|----------|-------|---------|
| Hero top inset | 80 | Clear navbar overlay |
| Hero bottom inset | 32 | Space before next section |
| Section horizontal inset | 16-24 | Side padding |
| Section vertical inset | 24 | Top/bottom section padding |
| Heading-to-content gap | 16 | Space between heading and first item |
| Widget-to-widget gap | 8-12 | Space between items in list |
| Card corner radius | 12-16 | Rounded card appearance |
| Button inset | 12 top/bottom, 16 leading/trailing | CTA padding |

## Common Gradient Presets

| Name | Angle | Colour Stops |
|------|-------|-------------|
| Purple hero | 180 | `#3B1F8E` → `#6B4EFF` → `#8B6FFF` |
| Blue card | 135 | `#1E3A5F` → `#3B82F6` |
| Sunset | 90 | `#FF6B35` → `#F72585` |
| Green fresh | 180 | `#065F46` → `#34D399` |

## Typography Quick Reference

| Context | Typography Value | Use For |
|---------|-----------------|---------|
| Page title | `HeadingXL` | Hero headlines |
| Section heading | `heading1` (via BDUIHeading style) | Section titles |
| Body text | `Body1LooseRegular` | Paragraphs, descriptions |
| Subtitle | `Body2TightRegular` | Supercell subtitles |
| Caption | `CaptionS` | Small labels |
| Button | (inherits from buttonType) | Buttons auto-style |
