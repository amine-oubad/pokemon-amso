class_name UITheme
## Shared UI constants and helper functions used across all screens.

# ── Color palette (Modern Clean) ─────────────────────────────────────────────
const C_BG     := Color(0.12, 0.14, 0.22)
const C_DARK   := Color(0.08, 0.08, 0.14)
const C_PANEL  := Color(0.16, 0.18, 0.28)
const C_BORDER := Color(0.28, 0.32, 0.45)
const C_HP_BG  := Color(0.10, 0.10, 0.18)
const C_TEXT   := Color(0.92, 0.92, 0.96)
const C_TEXT2  := Color(0.60, 0.62, 0.72)
const C_ACCENT := Color(0.30, 0.55, 0.95)

# ── Type colors ──────────────────────────────────────────────────────────────
const TYPE_COLORS := {
	"Normal":   Color(0.66, 0.66, 0.47),
	"Fire":     Color(0.93, 0.51, 0.19),
	"Water":    Color(0.39, 0.56, 0.94),
	"Electric": Color(0.97, 0.82, 0.17),
	"Grass":    Color(0.47, 0.78, 0.30),
	"Ice":      Color(0.59, 0.85, 0.84),
	"Fighting": Color(0.76, 0.18, 0.16),
	"Poison":   Color(0.64, 0.24, 0.63),
	"Ground":   Color(0.88, 0.75, 0.40),
	"Flying":   Color(0.66, 0.56, 0.95),
	"Psychic":  Color(0.98, 0.33, 0.53),
	"Bug":      Color(0.65, 0.73, 0.10),
	"Rock":     Color(0.72, 0.63, 0.21),
	"Ghost":    Color(0.44, 0.34, 0.59),
	"Dragon":   Color(0.44, 0.21, 0.98),
	"Dark":     Color(0.44, 0.34, 0.27),
	"Steel":    Color(0.72, 0.72, 0.81),
	"Fairy":    Color(0.84, 0.52, 0.68),
}

# ── HP bar color ─────────────────────────────────────────────────────────────
static func hp_color(ratio: float) -> Color:
	if ratio > 0.5:
		return Color(0.18, 0.80, 0.34)
	elif ratio > 0.2:
		return Color(0.95, 0.75, 0.10)
	else:
		return Color(0.90, 0.20, 0.15)
