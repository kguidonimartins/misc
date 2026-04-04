# misc 0.0.6

## View helpers (`R/view_in.R`)

- **`view_vd()` and `view_vd_nonint()`** are explicitly **macOS-only**: on Windows or Linux they stop with a clear error. Documentation describes this platform restriction.
- New **`terminal`** argument: `"terminal"` (Terminal.app, default), `"iterm"` (iTerm2), or `"auto"`. For `"auto"`, the choice comes from the `MISC_VIEW_TERM` environment variable and then from `options(misc.view_term)` (`"terminal"` or `"iterm"`); invalid values trigger a warning and fall back to Terminal.app.
- **AppleScript**-based terminal launch is unified (new window or tab in iTerm2 as appropriate).
- The **`vd`** (VisiData) executable must be on `PATH` before opening the viewer; the error message points to installation (for example `pip install visidata`).
- If **`vdk`** is on `PATH`, the command used is `vdk <project_basename> <file>`; otherwise `vd --default-width=500 <file>`. In `view_vd_nonint()`, the project name uses `basename(here::here())`, consistent with `view_vd()`.
- **`view_mapview_from_path()`** performs the macOS check up front because the workflow relies on `view_vd_nonint()` for the attribute table; documentation updated.
