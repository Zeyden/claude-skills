# Tap Interactions & Actions Configuration

## Overview

Tap interactions define what happens when a user taps a widget. They are configured via the `interactions` field on the base widget and via widget-specific `actions` fields.

## Interactions Object

The `interactions` field (from `InteractionsV1Input`) is available on every widget via the base widget schema:

```json
{
  "_type": "BDUISupercell",
  "interactions": {
    "tap": {
      "actions": [
        { "_type": "navigate", "navigationType": "forward", "url": "tabby://details/123" },
        { "_type": "sendAnalytics", "eventName": "cell_tapped", "attributes": [
          { "name": "widget_id", "value": "benefits_01" }
        ]}
      ]
    }
  }
}
```

### Structure

```
interactions (InteractionsV1Input)
  └── tap (TapInteractionV1Input) — optional
        └── actions (ActionsV1Input) — required, array of action objects
```

Currently only `tap` is supported. Future interaction types (longPress, doubleTap) can be added without contract changes.

## Widget-Specific Actions Fields

Some widgets have dedicated `actions` fields separate from `interactions`:

| Widget | Actions Field | Purpose |
|--------|--------------|---------|
| **BDUISupercell** | `actions` (required) | Primary tap action for the entire cell |
| **BDUIInformer** | `actions` (required) | Primary tap action |
| **BDUIButton** | `actions` | Button tap handler |
| **BDUIHeading** | `onTap` | Heading tap with `target` (full/title) |
| **BDUITrain** | `items[].actions` | Per-item tap actions |
| **BDUIInputField** | `leadIcon[].actions`, `trailIcon.actions` | Icon tap actions |
| **BDUINavBar** | `buttons[].actions` | Nav button tap actions |

### BDUIHeading onTap

The heading widget has a special `onTap` field with target control:

```json
{
  "_type": "BDUIHeading",
  "title": { "key": "section.title" },
  "onTap": {
    "target": "full",
    "actions": [
      { "_type": "navigate", "navigationType": "forward", "url": "tabby://section/all" }
    ]
  }
}
```

| Target | Behaviour |
|--------|-----------|
| `full` | Entire heading area is tappable |
| `title` | Only the title text is tappable |

## Action Types Quick Reference

### Navigate
```json
{ "_type": "navigate", "navigationType": "forward", "url": "tabby://savings" }
```

### Script
```json
{ "_type": "script", "id": "toggle", "script": "state.visible = !state.visible;" }
```

### SendAnalytics
```json
{
  "_type": "sendAnalytics",
  "eventName": "impression",
  "attributes": [{ "name": "widget", "value": "hero_banner" }]
}
```

### SendRequest
```json
{
  "_type": "sendRequest",
  "url": "/api/v1/action",
  "attributes": [{ "name": "method", "value": "POST" }]
}
```

### ShowTooltip
```json
{
  "_type": "showTooltip",
  "text": { "_type": "localisedField", "key": "tooltip.help" },
  "attributes": [{ "name": "position", "value": "bottom" }]
}
```

### Custom
```json
{ "_type": "custom", "customType": "openShareSheet" }
```

### CloseWidget
```json
{ "_type": "closeWidget", "widgetId": "promo_modal" }
```

### Legacy
```json
{ "_type": "legacy" }
```

## Multiple Actions (Sequential Execution)

Actions in an array are executed sequentially. Common patterns:

### Analytics + Navigate
```json
{
  "actions": [
    { "_type": "sendAnalytics", "eventName": "cta_tapped", "attributes": [...] },
    { "_type": "navigate", "navigationType": "forward", "url": "tabby://signup" }
  ]
}
```

### Request + Script (process response)
```json
{
  "actions": [
    { "_type": "sendRequest", "url": "/api/v1/check", "attributes": [...] },
    { "_type": "script", "id": "handle_response", "script": "if (response.ok) { ... }" }
  ]
}
```

## Lifecycle Actions

Separate from tap interactions, lifecycle actions fire automatically:

```json
{
  "lifecycleActions": {
    "onView": [
      { "_type": "sendAnalytics", "eventName": "widget_viewed", "attributes": [...] }
    ],
    "onDestroy": [
      { "_type": "script", "id": "cleanup", "script": "state.active = false;" }
    ]
  }
}
```

| Event | Fires When | Common Use |
|-------|-----------|-----------|
| `onView` | Widget becomes visible in viewport | Analytics impressions, lazy loading triggers |
| `onDestroy` | Widget removed from view tree | State cleanup, unsubscribe |

## Input vs Output Differences

| Aspect | Input (Sanity) | Output (Mobile) |
|--------|---------------|-----------------|
| Discriminator | `_type` field | `type` field |
| Text fields | `{ _type: "localisedField", key: "..." }` | `{ resolved: "Actual text" }` |
| Polymorphic fields | Wrapped in array (`maxItems: 1`) | Direct object |
| Icon | Sanity asset `_ref` | CDN URL string |
