---@alias OnedarkColor "black" | "bg0" | "bg1" | "bg2" | "bg3" | "bg_d" | "bg_blue" | "bg_yellow" | "fg" | "purple" | "green" | "orange" | "blue" | "yellow" | "cyan" | "red" | "grey" | "light_grey" | "dark_cyan" | "dark_red" | "dark_yellow" | "dark_purple" | "diff_add" | "diff_delete" | "diff_change" | "diff_text"

---@alias MaterialScheme "monochrome" | "neutral" | "tonal-spot" | "vibrant" | "expressive" | "fidelity" | "content" | "rainbow" | "fruit-salad"

---@alias MaterialColor "primary" | "on_primary" | "primary_container" | "on_primary_container" | "inverse_primary" | "primary_fixed" | "primary_fixed_dim" | "on_primary_fixed" | "on_primary_fixed_variant" | "secondary" | "on_secondary" | "secondary_container" | "on_secondary_container" | "secondary_fixed" | "secondary_fixed_dim" | "on_secondary_fixed" | "on_secondary_fixed_variant" | "tertiary" | "on_tertiary" | "tertiary_container" | "on_tertiary_container" | "tertiary_fixed" | "tertiary_fixed_dim" | "on_tertiary_fixed" | "on_tertiary_fixed_variant" | "error" | "on_error" | "error_container" | "on_error_container" | "surface_dim" | "surface" | "surface_tint" | "surface_bright" | "surface_container_lowest" | "surface_container_low" | "surface_container" | "surface_container_high" | "surface_container_highest" | "on_surface" | "on_surface_variant" | "outline" | "outline_variant" | "inverse_surface" | "inverse_on_surface" | "surface_variant" | "background" | "on_background" | "shadow" | "scrim"

---@class MaterialYouArgs
---@field material_dispatch table<OnedarkColor, MaterialColor | { start: MaterialColor, stop: MaterialColor, alpha: number }>
---@field size number
---@field scheme MaterialScheme
---@field harmony number
---@field harmonize_threshold number
---@field fg_boost number
---@field dark_mode boolean
---@field color string?
---@field img string?
---@field base_palette table<OnedarkColor, string>
