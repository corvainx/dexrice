local env = {
	"HYPRCURSOR_THEME,macOS",
	"HYPRCURSOR_SIZE,27",
	"XCURSOR_THEME,macOS",
	"XCURSOR_SIZE,27",
	"QT_CURSOR_THEME,macOS",
	"QT_CURSOR_SIZE,27",
}

for _, item in ipairs(env) do
	local key, value = item:match("^([^,]+),(.+)$")
	if key and value then
		hl.env(key, value)
	end
end

hl.config({
	general = {
		gaps_in = 2,
		gaps_out = 4,
		border_size = 2,
		col = {
			active_border = "rgba(33333399)",
			inactive_border = "rgba(1e1e1eaa)",
		},
		resize_on_border = true,
		allow_tearing = false,
		layout = "scrolling",
	},

	decoration = {
		rounding = 14,
		shadow = {
			enabled = true,
		},
		active_opacity = 1.0,
		inactive_opacity = 0.90,
		fullscreen_opacity = 1.0,
		blur = {
			enabled = true,
			size = 5,
			passes = 4,
			new_optimizations = true,
			ignore_opacity = true,
			xray = false,
			special = true,
		},
	},
})
