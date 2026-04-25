# Mermaid Theme Variables Reference

Only the `base` theme supports customisation via `themeVariables`.

## Core Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `darkMode` | false | Affects colour calculations |
| `background` | #f4f4f4 | Diagram background |
| `fontFamily` | trebuchet ms, verdana, arial | Font family |
| `fontSize` | 16px | Base text size |
| `primaryColor` | #fff4dd | Main node background |
| `primaryTextColor` | calculated | Text on primary |
| `primaryBorderColor` | calculated | Primary borders |
| `secondaryColor` | calculated | Secondary backgrounds |
| `secondaryTextColor` | calculated | Secondary text |
| `secondaryBorderColor` | calculated | Secondary borders |
| `tertiaryColor` | calculated | Tertiary backgrounds |
| `tertiaryTextColor` | calculated | Tertiary text |
| `tertiaryBorderColor` | calculated | Tertiary borders |
| `noteBkgColor` | #fff5ad | Note backgrounds |
| `noteTextColor` | #333 | Note text |
| `noteBorderColor` | calculated | Note borders |
| `lineColor` | calculated | Connector lines |
| `textColor` | calculated | Default text |
| `mainBkg` | calculated | Main backgrounds |
| `errorBkgColor` | tertiaryColor | Error backgrounds |
| `errorTextColor` | tertiaryTextColor | Error text |

## Flowchart Variables

| Variable | Purpose |
|----------|---------|
| `nodeBorder` | Node border colour |
| `clusterBkg` | Subgraph background |
| `clusterBorder` | Subgraph border |
| `defaultLinkColor` | Default arrow colour |
| `titleColor` | Diagram title colour |
| `edgeLabelBackground` | Label background on edges |
| `nodeTextColor` | Text inside nodes |

## Sequence Diagram Variables

| Variable | Purpose |
|----------|---------|
| `actorBkg` | Actor/participant background |
| `actorBorder` | Actor border |
| `actorTextColor` | Actor text |
| `actorLineColor` | Lifeline colour |
| `signalColor` | Arrow colour |
| `signalTextColor` | Arrow label colour |
| `labelBoxBkgColor` | Loop/alt label background |
| `labelBoxBorderColor` | Loop/alt label border |
| `labelTextColor` | Loop/alt label text |
| `loopTextColor` | Loop text colour |
| `activationBorderColor` | Activation bar border |
| `activationBkgColor` | Activation bar background |
| `sequenceNumberColor` | Autonumber colour |

## Pie Chart Variables

| Variable | Purpose |
|----------|---------|
| `pie1` to `pie12` | Slice fill colours |
| `pieTitleTextSize` | Title font size |
| `pieTitleTextColor` | Title colour |
| `pieSectionTextSize` | Slice label size |
| `pieSectionTextColor` | Slice label colour |
| `pieLegendTextSize` | Legend text size |
| `pieLegendTextColor` | Legend text colour |
| `pieStrokeColor` | Slice border colour |
| `pieStrokeWidth` | Slice border width |
| `pieOuterStrokeWidth` | Outer border width |
| `pieOuterStrokeColor` | Outer border colour |
| `pieOpacity` | Slice opacity |

## State Diagram Variables

| Variable | Purpose |
|----------|---------|
| `labelColor` | Label text colour |
| `altBackground` | Alternate state background |

## Class Diagram Variables

| Variable | Purpose |
|----------|---------|
| `classText` | Class member text colour |

## User Journey Variables

| Variable | Purpose |
|----------|---------|
| `fillType0` to `fillType7` | Section fill colours |

## Git Graph Variables

| Variable | Purpose |
|----------|---------|
| `git0` to `git7` | Branch colours |
| `gitBranchLabel0` to `gitBranchLabel7` | Branch label colours |
| `gitInv0` to `gitInv7` | Inverted branch colours |
| `commitLabelColor` | Commit label text |
| `commitLabelBackground` | Commit label background |
| `commitLabelFontSize` | Commit label size |
| `tagLabelColor` | Tag label text |
| `tagLabelBackground` | Tag label background |
| `tagLabelBorder` | Tag label border |
| `tagLabelFontSize` | Tag label size |

## XY Chart Variables

| Variable | Purpose |
|----------|---------|
| `titleColor` | Chart title colour |
| `backgroundColor` | Chart background |
| `xAxisLabelColor` | X-axis labels |
| `xAxisTitleColor` | X-axis title |
| `xAxisTickColor` | X-axis ticks |
| `xAxisLineColor` | X-axis line |
| `yAxisLabelColor` | Y-axis labels |
| `yAxisTitleColor` | Y-axis title |
| `yAxisTickColor` | Y-axis ticks |
| `yAxisLineColor` | Y-axis line |
| `plotColorPalette` | Data series colours |

## Radar Chart Variables

| Variable | Purpose |
|----------|---------|
| `axisColor` | Axis line colour |
| `axisStrokeWidth` | Axis line width |
| `axisLabelFontSize` | Axis label size |
| `curveOpacity` | Data curve opacity |
| `curveStrokeWidth` | Data curve width |
| `graticuleColor` | Grid colour |
| `graticuleOpacity` | Grid opacity |
| `graticuleStrokeWidth` | Grid width |
| `legendBoxSize` | Legend swatch size |
| `legendFontSize` | Legend text size |

## Timeline Variables

| Variable | Purpose |
|----------|---------|
| `cScale0` to `cScale11` | Section background colours |
| `cScaleLabel0` to `cScaleLabel11` | Section foreground colours |

## Important Notes

- Only **hex colour codes** (`#rrggbb`) work — named colours (`red`, `blue`) are not supported
- "calculated" means derived from other variables — override the source variable to change them
- Variables are set via frontmatter config or `%%{init:}%%` directive
