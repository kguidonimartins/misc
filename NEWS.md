# misc 0.1.0

## Breaking changes

- **`intersect_mask_filter_area()`** — `clipped` now returns one row per
  kept `x_id` by default (`dissolve = TRUE`): fragments produced when `x`
  and `y` have misaligned boundaries (for example two administrative meshes
  from different vintages) are unioned into a single feature instead of
  being left as separate slivers. Pass `dissolve = FALSE` to recover the
  previous one-row-per-fragment behaviour. Also, `y` is now intersected as
  geometry only, so its attributes no longer leak into `clipped` and no
  longer collide with `x`'s attribute names ([#8](https://github.com/kguidonimartins/misc/issues/8)).
  Fixed a bug in this same change where a `GEOMETRYCOLLECTION` decomposing
  into more than one polygon during dissolve was assigned back into the
  clipped `sfc` by position, silently recycling and mixing fragments across
  unrelated `x_id`s ([#10](https://github.com/kguidonimartins/misc/issues/10)).

## New helpers

- **`clean_geo()`** — reads a `.zip`/`.shp`/`.gpkg`/`.geojson`, drops Z/M
  dimensions, replaces non-ASCII characters in attribute columns, reprojects
  to a target CRS (default EPSG:4326) and writes the result to a
  user-provided `output` path. The output format is determined by the
  extension of `output` and may differ from the input format. Replaces the
  standalone `R/prepare_zip_shapefiles.R` cleanup routine with a portable,
  testable function backed by `zip::zip()` instead of `system("zip -j ...")`.
- **`fix_invalid_geometries()`** — reports rows with invalid geometries
  (via `sf::st_is_valid()`) and repairs them with `sf::st_make_valid()`,
  preserving attributes and the geometry column name; valid layers are
  returned unchanged.
- **`intersect_filter_touch()`** — returns the rows of `x` whose geometries
  touch any feature in the mask `y`, using `sf::st_intersects()` only. No
  reprojection, clipping, or area computation is performed: geometries and
  attributes of `x` are returned unchanged. The lightest-touch selection
  strategy, condensed from the common `st_intersects() |> lengths() |> { . == 1 }`
  idiom.
- **`remove_geom_holes()`** — removes polygon holes, optionally keeping holes
  at or above a configurable `max_area`; adapted from `nngeo` under its MIT
  license.
- **`serve_html()`** / **`serve_map()`** / **`serve_html_stop()`** — serve
  HTML widgets and rendered reports over HTTP so they can be opened in a
  browser on another device. Accepts `mapview` maps, any `htmlwidget`
  (`leaflet`, `plotly`, `DT`, `gt`), `sf` objects, and `.html` files already
  on disk; an on-disk report is mounted together with its sibling asset
  directory instead of being copied. One static server is reused per R
  session, so every URL handed out stays valid and pages can be compared in
  separate tabs. Hostname resolution is shared with `serve_plots()`.
- **`serve_plots()`** / **`serve_plots_url()`** — serve R plots over HTTP
  via `httpgd` so they can be viewed in a browser on another device (for
  example an iPad running a terminal over SSH or mosh). The advertised
  hostname is resolved from `MISC_PLOTS_HOST`, `options(misc.plots_host)`, or
  the Tailscale MagicDNS name, replacing the local mDNS name that `httpgd`
  reports and that does not resolve over a VPN. Binds a free port by default
  to avoid clashing with other local servers.
- **`view_qgis()`** — opens `sf` objects in QGIS on macOS, with GeoPackage or
  GeoJSON output and QGIS selection through `MISC_QGIS_APP` or
  `options(misc.qgis_app)`.

## Fixes

- **`clean_geo()`** now normalizes the `output` path to an absolute path
  (via `fs::path_abs()`), matching the behavior already applied to `path`.
  Relative `output` paths (e.g. `"data/clean/x.zip"`) previously failed when
  writing `.zip` output with `zip::zip()`; all output formats now resolve
  correctly against the current working directory.
- **`clean_geo()`** now also accepts an in-memory `sf` object as `path`, so a
  layer read and pre-filtered with `read_geo()` can be written out directly
  (e.g. `sf %>% clean_geo(output = "x.zip")`) without round-tripping through
  a file.

# misc 0.0.6

## View helpers (`R/view_in.R`)

- **`view_vd()` and `view_vd_nonint()`** are explicitly **macOS-only**: on Windows or Linux they stop with a clear error. Documentation describes this platform restriction.
- New **`terminal`** argument: `"terminal"` (Terminal.app, default), `"iterm"` (iTerm2), or `"auto"`. For `"auto"`, the choice comes from the `MISC_VIEW_TERM` environment variable and then from `options(misc.view_term)` (`"terminal"` or `"iterm"`); invalid values trigger a warning and fall back to Terminal.app.
- **AppleScript**-based terminal launch is unified (new window or tab in iTerm2 as appropriate).
- The **`vd`** (VisiData) executable must be on `PATH` before opening the viewer; the error message points to installation (for example `pip install visidata`).
- If **`vdk`** is on `PATH`, the command used is `vdk <project_basename> <file>`; otherwise `vd --default-width=500 <file>`. In `view_vd_nonint()`, the project name uses `basename(here::here())`, consistent with `view_vd()`.
- **`view_mapview_from_path()`** performs the macOS check up front because the workflow relies on `view_vd_nonint()` for the attribute table; documentation updated.
