---
name: execute-figma-script
description: "Execute a Figma Plugin API script via Figma Console MCP, applying all known API fixes, splitting if needed, and verifying results."
---

## Objective

Execute a Figma Plugin API script file via the Figma Console MCP (`figma_execute`), applying all required API corrections before execution. This shortcut ensures scripts run correctly by fixing known Figma Plugin API pitfalls that cause silent failures.

## Steps

1. **Read the script file** the user specifies (e.g. from `docs/design/figma-scripts/`).

2. **Apply ALL of the following fixes** to the script code before executing:

| Original | Fix | Reason |
|----------|-----|--------|
| `getLocalVariableCollections()` | `getLocalVariableCollectionsAsync()` | Sync API removed |
| `getVariableById(id)` | `getVariableByIdAsync(id)` | Sync API removed |
| `figma.getNodeById(id)` | `await figma.getNodeByIdAsync(id)` | Sync API removed (`documentAccess: dynamic-page` error) |
| `"SemiBold"` (Inter font style) | `"Semi Bold"` (with space) | Correct font style name |
| `"HUG"` in `primaryAxisSizingMode` or `counterAxisSizingMode` | `"AUTO"` | Only accepts `"FIXED"` or `"AUTO"` — `"HUG"` is silently ignored |
| `layoutSizingHorizontal = "FILL"` before `appendChild` | Move AFTER `appendChild` | Child must be inside an auto-layout parent first |
| `layoutGrow = 1` before `appendChild` | Move AFTER `appendChild` | Same reason — requires parent context |
| `layoutPositioning = "ABSOLUTE"` before `appendChild` | Move AFTER `appendChild` | Same reason — requires parent context |
| `figma.closePlugin()` | Remove entirely | Kills the Desktop Bridge plugin used by Figma Console MCP |
| `makeText` as `async function` | Make synchronous (remove `async`/`await`) | Fonts are pre-loaded upfront so no await is needed |
| `resize(w, placeholder)` on auto-layout frames | Set `layoutSizingVertical = "HUG"` AFTER resize, children, and appendChild | `resize()` locks BOTH axes to FIXED — applies to ALL frames, not just top-level components |
| Parent frame with absolute-positioned overflow children | Set `clipsContent = false` on parent | Frames default to `clipsContent = true`, clipping badges/tooltips at negative offsets |

3. **Wrap async IIFEs in try/catch.** Errors inside `(async () => { ... })()` are silently swallowed (unhandled Promise rejection). Always wrap the body in `try { ... } catch(e) { console.error("err:" + e.message); }` so failures appear in console logs.

4. **Check script size.** If the fixed script exceeds ~5000 characters, split it into sequential parts:
   - Each part must be a complete self-contained async IIFE: `(async () => { try { ... } catch(e) { console.error("err:" + e.message); } })();`
   - Each part needs its own boilerplate: async variable collections lookup, vars map, `boundFill`/`noFill` helpers, `makeText` function, and font pre-loading
   - Use `figma.root.setPluginData("componentsFrameId", id)` in Part 1 to store shared state
   - Use `figma.root.getPluginData("componentsFrameId")` in subsequent parts to retrieve it
   - Fall back to `page.children.find(f => f.name === "Components")` if plugin data lookup returns null

5. **Execute via `figma_execute`** with `timeout: 30000` for each part. Record `Date.now()` before each call to use as a timestamp for log filtering.

6. **Check logs** after each execution by calling `figma_get_console_logs` with the `since` timestamp recorded before the `figma_execute` call. This filters to only logs from the current execution, avoiding confusion with stale output.

7. **Dimension audit** — After all parts have executed, run the following verification script via `figma_execute` to catch sizing bugs:

```javascript
(async () => {
  try {
    const page = figma.currentPage;
    const cf = page.children.find(f => f.name === "Components");
    if (!cf) { console.error("❌ No Components frame"); return; }
    const issues = [];
    function audit(node, path) {
      const p = path + "/" + node.name;
      if ("layoutMode" in node && node.layoutMode !== "NONE") {
        if (node.layoutMode === "VERTICAL" && node.height <= 10 && node.layoutSizingVertical === "FIXED")
          issues.push({ path: p, w: node.width, h: node.height, sizing: "V=" + node.layoutSizingVertical });
        if (node.layoutMode === "HORIZONTAL" && node.width <= 10 && node.layoutSizingHorizontal === "FIXED")
          issues.push({ path: p, w: node.width, h: node.height, sizing: "H=" + node.layoutSizingHorizontal });
      }
      if ("children" in node) node.children.forEach(c => audit(c, p));
    }
    cf.children.forEach(c => audit(c, "Components"));
    if (issues.length === 0) {
      console.log("✅ Dimension audit passed — no suspicious sizes");
    } else {
      console.warn("⚠️ " + issues.length + " suspicious nodes:");
      issues.forEach(i => console.warn("  " + i.path + " → " + i.w + "×" + i.h + " (" + i.sizing + ")"));
      // Auto-fix: set HUG on the collapsed axis
      for (const i of issues) {
        const parts = i.path.split("/");
        let node = cf;
        for (let idx = 1; idx < parts.length; idx++) {
          node = node.children.find(c => c.name === parts[idx]);
          if (!node) break;
        }
        if (node) {
          if (i.sizing.startsWith("V=")) node.layoutSizingVertical = "HUG";
          if (i.sizing.startsWith("H=")) node.layoutSizingHorizontal = "HUG";
          console.log("🔧 Fixed: " + i.path);
        }
      }
    }
  } catch(e) { console.error("❌ audit error: " + e.message); }
})();
```

If the audit reports fixes, re-run it a second time to confirm all issues are resolved.

8. **Visual verification** — After the dimension audit passes, take screenshots of each created component via `figma_take_screenshot`. Check for:
   - Badges/tooltips visible (not clipped by parent frames)
   - Inputs and text filling available width
   - Consistent padding and spacing
   - Content not overflowing or collapsing

   If issues are found, investigate the node properties via `figma_execute` and fix them.

9. **Report results** — summarise what was created or fixed, including any warnings from console output, audit results, and screenshot observations.

## Key Figma Plugin API Rules

### Sizing
- `primaryAxisSizingMode` / `counterAxisSizingMode` accept ONLY `"FIXED"` | `"AUTO"` — never `"HUG"` or `"FILL"`
- `layoutSizingVertical` / `layoutSizingHorizontal` accept `"FIXED"` | `"HUG"` | `"FILL"` — these are the correct high-level shorthands. Prefer these over the low-level axis modes.
- **`resize()` locks BOTH axes to FIXED** on ALL auto-layout frames — not just top-level components. Every frame that calls `resize()` and needs a HUG dimension must set `layoutSizingVertical = "HUG"` (or `layoutSizingHorizontal`) as the very LAST operation — after `resize()`, after appending all children, after appending the node to its parent.
- `resize()` only reliably sets the FIXED dimension (e.g. width). For the HUG dimension, use `layoutSizingVertical = "HUG"` after everything else.
- **Pitfall**: `resize(w, 10)` with a small placeholder height is the #1 cause of collapsed components. The `10` becomes the actual FIXED height. Always follow with `layoutSizingVertical = "HUG"` at the end.

### clipsContent
- Frames default to `clipsContent = true` — any child at negative coordinates (e.g. badges at `y: -10`) will be invisible.
- Set `clipsContent = false` on any frame whose children use `layoutPositioning = "ABSOLUTE"` with negative coordinates.
- Check the full ancestor chain — any clipping ancestor will hide the overflow. Both the immediate parent AND higher-level containers (like a row frame or component set) may need `clipsContent = false`.

### Ordering (critical)
- `layoutSizingHorizontal = "FILL"` — MUST be set AFTER `appendChild` (child must already be inside an auto-layout parent)
- `layoutGrow = 1` — MUST be set AFTER `appendChild`
- `layoutPositioning = "ABSOLUTE"` — MUST be set AFTER `appendChild`

### Async API
- `figma.variables.getLocalVariableCollectionsAsync()` — sync version is removed, always `await`
- `figma.variables.getVariableByIdAsync(id)` — sync version is removed, always `await`
- `figma.getNodeByIdAsync(id)` — sync `getNodeById()` is removed (`documentAccess: dynamic-page` error), always `await`

### Cross-axis alignment
- `counterAxisAlignItems` accepts: `"MIN"` | `"MAX"` | `"CENTER"` | `"BASELINE"` — NOT `"STRETCH"` (that is CSS, not Figma)

### Text nodes
- Set `textAutoResize = "WIDTH_AND_HEIGHT"` on text nodes inside auto-layout frames to prevent zero-size collapse
- Load fonts with `figma.loadFontAsync()` before setting any text properties

### Component sets
- `figma.combineAsVariants([components], parent)` creates a component set
- Variant property names come from component `name` format: `"Property=Value, Property2=Value2"`
- Component sets have `clipsContent = true` by default — set to `false` if children need to overflow

### Desktop Bridge
- NEVER call `figma.closePlugin()` — it kills the Desktop Bridge plugin that Figma Console MCP relies on

### Error handling
- Async IIFEs `(async () => { ... })()` silently swallow errors — the Desktop Bridge reports "Code executed successfully" even when the async body throws
- ALWAYS wrap the body in `try/catch` with `console.error()` so failures appear in logs
- Use `Date.now()` before each `figma_execute` call and pass it as `since` to `figma_get_console_logs` to filter to current execution

## Standard Boilerplate Template

When splitting scripts or writing new ones, use this boilerplate at the top of each part:

```javascript
(async () => {
  try {
  const page = figma.currentPage;
  const collections = await figma.variables.getLocalVariableCollectionsAsync();
  const semantic = collections.find(c => c.name === "Semantic");
  if (!semantic) { console.error("❌ No Semantic collection"); return; }
  const vars = {};
  for (const id of semantic.variableIds) {
    const v = await figma.variables.getVariableByIdAsync(id);
    if (v) vars[v.name] = v;
  }
  function bf(n) {
    const v = vars[n];
    if (!v) return { type: "SOLID", color: { r: .5, g: .5, b: .5 } };
    return { type: "SOLID", color: { r: .5, g: .5, b: .5 },
      boundVariables: { color: { type: "VARIABLE_ALIAS", id: v.id } } };
  }
  await figma.loadFontAsync({ family: "Inter", style: "Bold" });
  await figma.loadFontAsync({ family: "Inter", style: "Semi Bold" });
  await figma.loadFontAsync({ family: "Inter", style: "Medium" });
  await figma.loadFontAsync({ family: "Inter", style: "Regular" });
  function mt(c, s, w, f) {
    const sn = w >= 700 ? "Bold" : w >= 600 ? "Semi Bold" : w >= 500 ? "Medium" : "Regular";
    const t = figma.createText();
    t.fontName = { family: "Inter", style: sn };
    t.fontSize = s; t.characters = c;
    t.fills = Array.isArray(f) ? f : [f];
    t.lineHeight = { value: Math.round(s * 1.5), unit: "PIXELS" };
    return t;
  }
  // hugV: After appending a node to its parent and adding all children, call:
  //   node.layoutSizingVertical = "HUG";
  // This MUST be the last operation on any auto-layout frame that called resize().

  // Retrieve Components frame (from Part 1's stored ID or by name)
  const cfId = figma.root.getPluginData("componentsFrameId");
  let cf = cfId ? await figma.getNodeByIdAsync(cfId) : null;
  if (!cf) cf = page.children.find(f => f.name === "Components");
  if (!cf) { console.error("❌ No Components frame"); return; }

  // ... component creation code here ...

  } catch(e) { console.error("❌ error: " + e.message); }
})();
```

## Splitting Strategy

When scripts exceed ~5000 characters, split them into sequential parts. Use these guidelines:

### Character Budgets
- **Boilerplate** (vars, bf, mt, font loading, Components frame lookup): ~800 chars
- **Helper functions**: ~300–700 chars each. Only include helpers needed by that specific part.
- **Component code budget**: ~4000 chars per part (5000 limit minus boilerplate)
- Count characters before executing — use the actual string length, not a rough estimate.

### State Sharing Between Parts
- Part 1 stores the Components frame ID: `figma.root.setPluginData("componentsFrameId", cf.id)`
- Subsequent parts retrieve it: `figma.root.getPluginData("componentsFrameId")`
- Store arrays of created component IDs as JSON: `figma.root.setPluginData("createdIds", JSON.stringify(ids))`
- Always fall back to `page.children.find(f => f.name === "Components")` if plugin data returns null

### Compression Tips
- Symmetric padding: `f.paddingTop = f.paddingBottom = f.paddingLeft = f.paddingRight = 16`
- Single-letter helper names: `S` (section), `H` (header), `BD` (body), `FT` (footer)
- Combine sizing: `f.primaryAxisSizingMode = f.counterAxisSizingMode = "AUTO"`
- Inline fills: `t.fills = [bf("text/primary")]` instead of a separate variable
- Skip `noFill` helper if unused in that part

## Success Criteria

- Console logs show completion messages for each component created/fixed
- Height values logged for rebuilt components should be reasonable (e.g. 30–120px), NOT 1 or 10 (which indicates collapsed/broken sizing)
- No error messages in console output
- No warnings about missing semantic variables (unless expected)
- **Dimension audit passes**: All auto-layout frames with `resize()` calls have reasonable dimensions (not placeholder values like 10)
- **No clipping issues**: No `clipsContent = true` on frames with absolute-positioned overflow children
- **Screenshots confirm visual correctness**: Badges visible, inputs properly sized, content not clipped or overflowing

## Constraints

- Each `figma_execute` call must be under ~5000 characters
- Always use `timeout: 30000` for execution
- Scripts must NOT call `figma.closePlugin()`
- All variable and node lookups must use the async API (`getVariableByIdAsync`, `getNodeByIdAsync`, `getLocalVariableCollectionsAsync`)
- Font style names must use spaces (e.g. `"Semi Bold"` not `"SemiBold"`)
