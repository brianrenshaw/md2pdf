# The Comprehensive Guide to Coastal Cartography

Below is a working Table of Contents

[[toc]]

A working reference for the fictitious International Society of Coastal Mapmakers, maintained since 1987. This document covers the history, methods, and ongoing debates within the field. It also happens to exercise every Markdown rendering edge case your stylesheet will ever encounter.

## A Brief History of Shoreline Surveys

The earliest known coastal surveys date to the Mediterranean trading routes of the Phoenicians, who scratched rough outlines of harbors into clay tablets. By the 16th century, Portuguese navigators had developed *portolan charts*, hand-drawn maps that prioritized **compass bearings** and ***harbor depths*** over inland accuracy. The term "cartography" itself comes from the Greek *chartis* (map) and *graphein* (to write), though the modern discipline didn't fully separate from general surveying until the late 1800s[^1].

The 20th century brought aerial photography, satellite imagery, and eventually LiDAR scanning. Each leap forward made the previous generation's maps look almost quaint. ~~The 1952 Beaumont Survey, once considered definitive, was quietly retired in 1978.~~ Today, a single pass of a `Cessna 206` equipped with bathymetric LiDAR captures more data than an entire 19th-century expedition.

[^1]: For a thorough treatment of this history, see Harmon & Feld, *Edges of the Known World* (Cambridge University Press, 2003).

[^2]: Tidal coefficients vary by basin. The Mediterranean, for example, has negligible tidal range compared to the Bay of Fundy's 16-meter swings.

---

## Core Principles

> "A map is not the territory, but a good map makes the territory legible."
>
> Margaret Chen, keynote address to the ISCM Annual Conference, 2014

The Society organizes its work around three principles that have remained constant even as tools have changed:

1. **Accuracy over aesthetics.** A beautiful map that misplaces a reef by 200 meters is worse than an ugly one that gets it right.
2. **Temporal honesty.** Coastlines move. Every map should carry a survey date, and no map should imply permanence it cannot deliver.
3. **Accessible notation.** If a fishing boat captain cannot read your depth markings under a rain-soaked lantern at 4 AM, your notation system has failed.

These principles surface again and again in the sections that follow. They also test whether your CSS handles an ordered list immediately followed by a paragraph without collapsing the spacing.

---

## Survey Methods

### Satellite-Based Remote Sensing

Modern surveys begin with satellite imagery. The Landsat program, operational since 1972, provides multispectral data at 30-meter resolution. For coastal work, the key bands are:

* **Band 1 (Blue):** Penetrates shallow water, useful for bathymetric estimation in clear conditions
* **Band 4 (Near-Infrared):** Absorbed almost entirely by water, making it ideal for delineating the waterline
* **Band 5 (SWIR):** Helps distinguish wet sand from dry sand, important for tidal correction
  * This band is also useful for identifying salt marshes
  * It loses effectiveness in heavy cloud cover
    * Which is, unfortunately, common in the regions where coastal mapping matters most

The following table summarizes the satellites most commonly used in coastal survey work. It tests whether your table styling handles a moderate number of columns and mixed alignment gracefully.

| Satellite     | Operator     | Resolution | Revisit Period | Primary Use              |
|:--------------|:------------:|-----------:|:--------------:|:-------------------------|
| Landsat 9     | USGS/NASA    | 30 m       | 16 days        | Multispectral imaging    |
| Sentinel-2    | ESA          | 10 m       | 5 days         | High-frequency monitoring|
| WorldView-3   | Maxar        | 0.31 m     | 1 day          | Fine-detail mapping      |
| ICESat-2      | NASA         | ~17 m      | 91 days        | Photon-counting LiDAR    |
| SWOT          | NASA/CNES    | 2 km       | 21 days        | Surface water topography |

### Airborne LiDAR

When satellite resolution isn't enough, the Society recommends airborne bathymetric LiDAR. The aircraft flies a series of parallel transects over the target coastline at an altitude of roughly 300 to 500 meters.

Here is a typical survey aircraft over a test region:

![Aerial coastal survey scene](https://picsum.photos/seed/coastal-survey/800/400)

The LiDAR unit fires two laser wavelengths simultaneously. The infrared pulse reflects off the water surface while the green pulse penetrates and reflects off the seabed. The difference in return times gives a depth measurement. A simplified version of the depth calculation looks like this:

$$
d = \frac{c \cdot \Delta t}{2n}
$$

Where $c$ is the speed of light, $\Delta t$ is the time difference between returns, and $n$ is the refractive index of seawater (approximately 1.34).

### Ground-Truth Fieldwork

No remote method replaces boots on the ground. Field teams walk transects, plant survey stakes, and collect sediment samples. Their data validates (or contradicts) what the satellites and aircraft reported.

> Field notes from the 2019 Outer Banks survey:
>
> > "Station 14 shows 1.8 m of recession since the 2017 baseline. The dune line has retreated past the old parking lot footprint."
> >
> > > Appended note from the review team: "Confirmed by drone overflight. Recommend reclassifying this segment from 'stable' to 'active retreat.'"
>
> This three-level nesting of field notes, station logs, and review comments is common in our reports.

---

## Data Processing Pipeline

Once raw data arrives from the field, it moves through a multi-stage processing pipeline. The following code shows the initial ingestion step, written in Python:

```python
import pathlib
from dataclasses import dataclass
from datetime import date

@dataclass
class SurveyPoint:
    latitude: float
    longitude: float
    elevation: float
    survey_date: date
    source: str  # "satellite", "lidar", or "field"

def ingest_csv(path: pathlib.Path) -> list[SurveyPoint]:
    """Read a CSV of raw survey points and return typed objects."""
    points = []
    with open(path) as f:
        next(f)  # skip header
        for line in f:
            lat, lon, elev, dt, src = line.strip().split(",")
            points.append(SurveyPoint(
                latitude=float(lat),
                longitude=float(lon),
                elevation=float(elev),
                survey_date=date.fromisoformat(dt),
                source=src,
            ))
    return points
```

After ingestion, a shell script kicks off the validation and merge steps:

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT_DIR="./raw_surveys"
OUTPUT_DIR="./processed"

mkdir -p "$OUTPUT_DIR"

for csv in "$INPUT_DIR"/*.csv; do
    base=$(basename "$csv" .csv)
    echo "Validating: $base"
    python validate.py "$csv" --strict
    python merge.py "$csv" -o "$OUTPUT_DIR/${base}_merged.geojson"
done

echo "Pipeline complete. $(ls "$OUTPUT_DIR" | wc -l) files generated."
```

The merge step produces GeoJSON, which can then be styled for web display. Here is a snippet of the CSS used for the Society's internal map viewer:

```css
.coastline-layer {
  stroke: var(--color-shoreline, #2563eb);
  stroke-width: 2px;
  fill: none;
}

.depth-contour {
  stroke: var(--color-depth, #0891b2);
  stroke-width: 1px;
  stroke-dasharray: 4 2;
  opacity: 0.7;
}

.survey-point:hover {
  r: 6px;
  fill: var(--color-accent, #f59e0b);
  cursor: pointer;
}
```

There is also a short JavaScript utility for converting coordinates:

```javascript
/**
 * Convert decimal degrees to degrees-minutes-seconds.
 * Used in printed chart legends.
 */
function toDMS(decimal) {
  const abs = Math.abs(decimal);
  const deg = Math.floor(abs);
  const minFloat = (abs - deg) * 60;
  const min = Math.floor(minFloat);
  const sec = ((minFloat - min) * 60).toFixed(2);
  const dir = decimal >= 0 ? (deg === abs ? "" : "N") : "S";
  return `${deg}° ${min}′ ${sec}″ ${dir}`;
}
```

For quick calculations, some teams still use indented code blocks in their field notebooks:

    depth_ft = depth_m * 3.28084
    draft_clearance = depth_ft - vessel_draft
    if draft_clearance < 3.0:
        print("WARNING: insufficient clearance")

Inline code also shows up constantly in documentation. The `--strict` flag in the validation script rejects any point where `elevation` exceeds `±500 m` from the local mean. Occasionally you see code jammed against punctuation like `value`,`another`,`third` and your CSS needs to not collapse the spacing.

Edge case for backticks inside inline code: `` `tick` `` and a longer one: `` `double tick` ``.

---

## Regional Case Studies

### The Outer Banks, North Carolina

The Outer Banks are a chain of barrier islands stretching roughly 320 km along the North Carolina coast. They are among the most dynamic coastlines in North America, with some segments retreating more than 3 meters per year.

![Outer Banks aerial view](https://picsum.photos/seed/outerbanks/800/350)

The following table records measured retreat rates at five monitoring stations. It is deliberately wide to test horizontal overflow handling.

| Station ID | Location Name               | 2015 Baseline (m) | 2020 Measurement (m) | Net Change (m) | Annual Rate (m/yr) | Classification     |
|:----------:|:----------------------------|-------------------:|---------------------:|----------------:|-------------------:|:-------------------|
| OBX-001    | Corolla North Beach         | 142.7              | 128.3                | -14.4           | -2.88              | Active Retreat     |
| OBX-002    | Duck Research Pier          | 88.4               | 86.1                 | -2.3            | -0.46              | Relatively Stable  |
| OBX-003    | Nags Head Mile Post 11      | 61.2               | 47.8                 | -13.4           | -2.68              | Active Retreat     |
| OBX-004    | Cape Hatteras Lighthouse    | 457.0              | 455.2                | -1.8            | -0.36              | Stable (relocated) |
| OBX-005    | Ocracoke South Point        | 203.5              | 198.9                | -4.6            | -0.92              | Moderate Retreat   |

### The Maldives

The Republic of Maldives presents the opposite problem. Rather than dramatic retreat, the islands face gradual submersion. The highest natural point in the country is only about 2.4 meters above sea level.

> The Maldivian government has argued for decades that global sea level rise represents an existential threat. A blockquote containing a list:
>
> * Over 80% of the land area sits below 1 meter elevation
> * Storm surge events that were once rare now occur multiple times per year
> * Coral reef degradation has accelerated erosion on windward coasts

<details>
<summary>Supplementary data: Maldives elevation distribution</summary>

The following breakdown comes from the 2021 national elevation survey. This content is hidden inside a collapsible section, testing whether `<details>` and `<summary>` are styled.

| Elevation Band | % of Total Land Area |
|:---------------|---------------------:|
| Below 0.5 m    | 23%                  |
| 0.5 to 1.0 m   | 41%                  |
| 1.0 to 1.5 m   | 22%                  |
| 1.5 to 2.0 m   | 11%                  |
| Above 2.0 m    | 3%                   |

A code block inside the collapsible:

```python
# Elevation risk calculation
risk_zones = {k: v for k, v in elevations.items() if k < 1.0}
total_at_risk = sum(risk_zones.values())
print(f"{total_at_risk}% of land area below 1.0 m")
```

</details>

---

## Equipment Standards

The Society maintains a short list of approved equipment. This section exercises nested mixed lists: ordered parents with unordered children and vice versa.

1. GPS Receivers
   * Trimble R12i (survey-grade, dual frequency)
   * Leica GS18 T (tilt compensation, good for rough terrain)
     1. Requires firmware version 4.5 or later
     2. Must be calibrated monthly
   * Budget alternative: Emlid Reach RS2+
2. LiDAR Units
   * Leica Chiroptera 4X (bathymetric + topographic)
   * RIEGL VQ-840-G
3. Software
   * QGIS for visualization
   * CloudCompare for point cloud processing
   * Custom Python tooling (see [Data Processing Pipeline](#data-processing-pipeline))

### Task List for Field Kit Preparation

Every field deployment starts with this checklist. It tests task list rendering, including nested sub-tasks at mixed completion states.

* [x] Charge all GPS units to 100%
* [x] Load latest firmware on Trimble R12i
* [ ] Calibrate barometric altimeter
* [ ] Pack backup battery packs
  * [x] Verified: 4 packs in storage
  * [ ] Need to order 2 additional packs
* [ ] Print waterproof field data sheets

### Keyboard Shortcuts for the Map Viewer

The Society's internal map viewer relies on keyboard shortcuts that field analysts memorize. Press <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>M</kbd> to toggle measurement mode. Press <kbd>Ctrl</kbd> + <kbd>Z</kbd> to undo the last edit. The <kbd>Space</kbd> bar pans the map when held. These `<kbd>` elements should render with a key-cap style if your CSS supports it.

---

## Tidal Correction

All elevation data must be corrected relative to a tidal datum. The Society uses Mean Lower Low Water (<abbr title="Mean Lower Low Water">MLLW</abbr>) as the standard vertical reference[^2]. Hover over the abbreviation to see if your CSS shows the title attribute. The correction formula for a given observation is:

$$
h_{\text{corrected}} = h_{\text{observed}} - (T_{\text{predicted}} - \text{MLLW})
$$

Inline math also appears in field documentation. A common shorthand is $h_c = h_o - \Delta T$, where $\Delta T$ is the tidal offset at the time of measurement.

The matrix below represents a simplified tidal constituent model for three monitoring stations:

$$
\begin{bmatrix}
M_2 & S_2 & N_2 & K_1 \\
0.53 & 0.17 & 0.11 & 0.14 \\
0.49 & 0.15 & 0.10 & 0.16 \\
0.61 & 0.19 & 0.13 & 0.12
\end{bmatrix}
$$

---

## Image Handling Edge Cases

This section exists purely to test how your CSS handles images in various contexts.

A small image embedded inline within running text: the Society's logo ![logo](https://picsum.photos/18/18) appears on all official correspondence. It should sit on the text baseline without disrupting line height or pushing adjacent text around.

A linked image that acts as a clickable button:

[![View full map](https://picsum.photos/seed/mapbutton/400/180)](https://example.com/full-map)

Images inside table cells alongside text:

| Region         | Preview                                                      | Survey Count | Notes                              |
|:---------------|:------------------------------------------------------------:|:------------:|:-----------------------------------|
| Gulf Coast     | ![gulf](https://picsum.photos/seed/gulf/100/60)              | 42           | Hurricane damage complicates surveys |
| Pacific NW     | ![pacific](https://picsum.photos/seed/pacific/100/60)        | 31           | Dense fog limits aerial windows     |
| Great Lakes    | ![lakes](https://picsum.photos/seed/greatlakes/100/60)       | 27           | Freshwater, different datum required |

An image that intentionally fails, testing alt text rendering:

![This is a broken image. Your CSS should style the alt text or broken-image icon gracefully.](https://example.invalid/does-not-exist.png)

An HTML image with explicit dimensions that the renderer should honor:

<img src="https://picsum.photos/seed/htmlimg/700/250" alt="HTML image element with explicit width and height" width="700" height="250" />

---

## Notation Glossary

Definition lists are uncommon in Markdown but supported by many extended renderers. They test `<dl>`, `<dt>`, and `<dd>` styling.

Bathymetry
: The measurement of water depth. Derived from the Greek *bathys* (deep) and *metron* (measure).

Datum
: A reference frame for vertical or horizontal measurements. Common vertical datums include MLLW, NAVD88, and MSL.

Isopleth
: A line on a map connecting points of equal value, such as depth contours on a nautical chart.
: Sometimes called an isoline or contour line depending on the discipline. Multiple definitions for a single term are valid and should render as grouped items under one heading.

---

## Miscellaneous Rendering Stress Tests

### Paragraph Immediately After a List

* Item one
* Item two

This paragraph comes directly after a list with no intervening heading or rule. Is the spacing correct, or does it collapse into the list?

### Adjacent Blocks with No Breathing Room

> A blockquote ending abruptly.

```
A code block starting immediately after.
```

* A list starting right after the code block.
* Second item.

This paragraph follows the list. Each transition between block types should maintain consistent vertical rhythm. This is one of the most common rendering bugs in Markdown stylesheets.

### Empty Table Cells

Some survey data arrives with gaps. Your table CSS should handle empty cells without collapsing columns or breaking alignment.

| Station | Jan  | Feb  | Mar  | Apr  |
|---------|------|------|------|------|
| A       | 3.2  |      | 3.1  | 2.9  |
|         | 4.1  | 4.0  |      | 3.8  |
| C       |      |      | 5.5  |      |

### Table with One Row

| Key         | Value                        |
|-------------|------------------------------|
| version     | 3.2.1                        |

### Table with Inline Formatting in Every Cell

| Feature       | Syntax               | Rendered         |
|---------------|-----------------------|------------------|
| Bold          | `**bold**`           | **bold**         |
| Italic        | `*italic*`           | *italic*         |
| Code          | `` `code` ``         | `code`           |
| Link          | `[text](url)`        | [text](url)      |
| Strikethrough | `~~strike~~`         | ~~strike~~       |

### Very Long Cell Content

| Short | This cell contains a much longer block of text designed to test how your table layout algorithm handles content that significantly exceeds the natural column width and might cause wrapping, horizontal scrolling, or overflow issues depending on your `table-layout` property |
|-------|---|
| Data  | More data |

### Very Long Unbroken String

The following string has no whitespace breakpoints. It tests whether your CSS applies `overflow-wrap: break-word` or similar:

`supercalifragilisticexpialidocious_but_also_with_underscores_and_numbers_12345_to_make_it_even_longer_and_more_painful_for_your_layout_engine_to_handle_gracefully`

### Horizontal Rules

Three valid Markdown syntaxes, all producing `<hr>`. Do they render identically under your styles?

---

***

___

### Special Characters and Emoji

Unicode emoji mixed with prose: The survey is complete ✅, the data has been merged 📊, and the report is ready for review 📝. Warning ⚠️: two stations returned anomalous readings ❌.

HTML entities: The Society holds copyright &copy; 2024. Temperatures ranged from 18&deg;C to 32&deg;C. Distance: approximately &frac12; nautical mile &rarr; 926 meters.

Smart quotes: "The shoreline doesn't care about your schedule," said the field supervisor. 'Neither does the tide.'

### Highlighted Text

The <mark>mark element</mark> is used for highlighting. Some Markdown renderers also support ==double equals== syntax. If both are present in the output, they should look the same.

### Deeply Nested Blockquote with Code Inside

> The survey director's summary:
>
> > Field team leader's response:
> >
> > > Instrument technician's note, including inline code `err_code: 0x4F` and a fenced block:
> > >
> > > ```
> > > INSTRUMENT LOG
> > > Timestamp: 2024-03-15T14:22:07Z
> > > Status: RECALIBRATION REQUIRED
> > > Drift: +0.034m over 6hr window
> > > ```
> > >
> > > This is three levels deep with a fenced code block inside. Most stylesheets give up here.

---

## Cross-References and Navigation

This document links to its own sections throughout. Anchor links should scroll smoothly (if your CSS includes `scroll-behavior: smooth`) and land at the correct heading.

* Jump to [Core Principles](#core-principles)
* Jump to [Tidal Correction](#tidal-correction)
* Jump to [Equipment Standards](#equipment-standards)
* Return to the [top of the document](#the-comprehensive-guide-to-coastal-cartography)

---

## Appendix: Centered Content

<div align="center">

**International Society of Coastal Mapmakers**

*Founded 1987 &middot; Louisville, Kentucky*

<img src="https://picsum.photos/seed/seal/150/150" alt="Society seal" width="150" height="150" />

"Mapping the edge of the world, one transect at a time."

</div>

---

## Final Rendering Checklist

Walk through the document top to bottom and confirm each element renders correctly under your stylesheet.

* [ ] Headings h1 through h6 are visually distinct with appropriate spacing
* [ ] Bold, italic, bold-italic, strikethrough, and inline code all render
* [ ] Footnotes link correctly and appear at the document's end
* [ ] Blockquotes, including triple-nested, have clear visual treatment
* [ ] Ordered, unordered, mixed, task, and definition lists indent properly
* [ ] Tables align columns, handle overflow, and show borders consistently
* [ ] Images load from the web, scale properly, and sit correctly inline and in tables
* [ ] Broken images display alt text or a placeholder icon
* [ ] HTML images with explicit dimensions honor width/height
* [ ] Code blocks show syntax highlighting and scroll horizontally if needed
* [ ] Indented code blocks are styled (same or different from fenced, intentionally)
* [ ] Inline code handles backtick edge cases and punctuation adjacency
* [ ] Horizontal rules are visible and consistent across all three syntaxes
* [ ] `<details>` / `<summary>` collapses and expands with styled toggle
* [ ] `<kbd>` elements render with key-cap styling
* [ ] `<abbr>` elements show title on hover
* [ ] `<mark>` and ==highlight== are styled: <mark>like this</mark>
* [ ] Math blocks render if KaTeX or MathJax is loaded
* [ ] Emoji and HTML entities display correctly
* [ ] Long unbroken strings do not blow out the layout
* [ ] Adjacent block elements (quote, code, list, paragraph) maintain vertical rhythm
* [ ] Anchor links scroll to the correct sections
* [ ] Centered HTML content renders as expected
* [ ] Empty table cells do not break table structure

[[foot-left]] <b>Updated:</b> March 2026