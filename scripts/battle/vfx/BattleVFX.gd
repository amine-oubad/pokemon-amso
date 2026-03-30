extends Node
## Pipeline 2 — Gestionnaire de VFX pour les combats.
## Fournit des animations d'attaque par type, camera shake, flash d'impact,
## animations de sprites Pokemon, et fonds de terrain dynamiques.
## Autoload singleton.
##
## Usage dans BattleScene :
##   await BattleVFX.play_attack_vfx(move, attacker_sprite, defender_sprite)
##   BattleVFX.shake_camera(camera, intensity)

# ── Couleurs par type pour les VFX ───────────────────────────────────────────
const TYPE_VFX_COLORS := {
	"Normal":   [Color(0.90, 0.90, 0.85), Color(0.70, 0.70, 0.65)],
	"Fire":     [Color(1.0, 0.55, 0.10), Color(1.0, 0.85, 0.15), Color(0.90, 0.20, 0.05)],
	"Water":    [Color(0.30, 0.60, 1.0), Color(0.50, 0.80, 1.0), Color(0.15, 0.40, 0.85)],
	"Grass":    [Color(0.30, 0.80, 0.20), Color(0.50, 0.90, 0.30), Color(0.15, 0.55, 0.10)],
	"Electric": [Color(1.0, 0.95, 0.20), Color(1.0, 0.85, 0.0), Color(0.95, 0.70, 0.0)],
	"Ice":      [Color(0.60, 0.90, 1.0), Color(0.80, 0.95, 1.0), Color(0.40, 0.75, 0.95)],
	"Fighting": [Color(0.85, 0.25, 0.15), Color(1.0, 0.50, 0.20), Color(0.65, 0.10, 0.05)],
	"Poison":   [Color(0.70, 0.20, 0.70), Color(0.85, 0.40, 0.85), Color(0.50, 0.10, 0.55)],
	"Ground":   [Color(0.85, 0.70, 0.35), Color(0.70, 0.55, 0.25), Color(0.55, 0.40, 0.15)],
	"Flying":   [Color(0.70, 0.80, 1.0), Color(0.85, 0.90, 1.0), Color(0.55, 0.65, 0.90)],
	"Psychic":  [Color(1.0, 0.35, 0.60), Color(0.90, 0.50, 0.80), Color(0.70, 0.15, 0.50)],
	"Bug":      [Color(0.65, 0.80, 0.10), Color(0.80, 0.90, 0.30), Color(0.45, 0.60, 0.05)],
	"Rock":     [Color(0.70, 0.60, 0.30), Color(0.55, 0.48, 0.20), Color(0.85, 0.75, 0.45)],
	"Ghost":    [Color(0.45, 0.30, 0.65), Color(0.60, 0.40, 0.80), Color(0.30, 0.15, 0.50)],
	"Dragon":   [Color(0.45, 0.20, 1.0), Color(0.65, 0.40, 1.0), Color(0.30, 0.10, 0.75)],
	"Dark":     [Color(0.35, 0.25, 0.20), Color(0.50, 0.35, 0.25), Color(0.15, 0.10, 0.08)],
	"Steel":    [Color(0.75, 0.75, 0.85), Color(0.90, 0.90, 0.95), Color(0.55, 0.55, 0.65)],
	"Fairy":    [Color(0.95, 0.55, 0.75), Color(1.0, 0.75, 0.85), Color(0.80, 0.35, 0.60)],
}

# ── Noms de terrains pour les fonds de combat ─────────────────────────────────
const TERRAIN_TYPES := {
	"grass":  {"bg_top": Color(0.45, 0.70, 0.95), "bg_bot": Color(0.30, 0.58, 0.22), "ground": Color(0.35, 0.55, 0.20)},
	"cave":   {"bg_top": Color(0.12, 0.10, 0.18), "bg_bot": Color(0.20, 0.18, 0.25), "ground": Color(0.30, 0.28, 0.32)},
	"water":  {"bg_top": Color(0.45, 0.70, 0.95), "bg_bot": Color(0.15, 0.50, 0.85), "ground": Color(0.20, 0.55, 0.80)},
	"indoor": {"bg_top": Color(0.30, 0.28, 0.35), "bg_bot": Color(0.25, 0.22, 0.28), "ground": Color(0.45, 0.42, 0.38)},
	"snow":   {"bg_top": Color(0.75, 0.82, 0.92), "bg_bot": Color(0.88, 0.90, 0.95), "ground": Color(0.92, 0.93, 0.96)},
	"sand":   {"bg_top": Color(0.80, 0.70, 0.45), "bg_bot": Color(0.90, 0.80, 0.55), "ground": Color(0.88, 0.78, 0.50)},
	"volcano":{"bg_top": Color(0.35, 0.10, 0.08), "bg_bot": Color(0.55, 0.18, 0.10), "ground": Color(0.40, 0.20, 0.12)},
	"forest": {"bg_top": Color(0.20, 0.45, 0.18), "bg_bot": Color(0.12, 0.35, 0.10), "ground": Color(0.18, 0.40, 0.12)},
}

var _vfx_container: Node2D

func _ready() -> void:
	print("[BattleVFX] Pret — %d types de VFX disponibles" % TYPE_VFX_COLORS.size())

# ── VFX d'attaque principal ───────────────────────────────────────────────────

## Joue l'animation VFX complete d'une attaque.
## parent : le noeud CanvasLayer du combat
## move_type : type de l'attaque ("Fire", "Water", etc.)
## target_pos : position du sprite cible
## is_physical : true pour physique, false pour special
func play_attack_vfx(parent: Node, move_type: String, target_pos: Vector2, is_physical: bool = true) -> void:
	var colors: Array = TYPE_VFX_COLORS.get(move_type, TYPE_VFX_COLORS["Normal"])

	if is_physical:
		await _play_impact_vfx(parent, target_pos, colors)
	else:
		await _play_projectile_vfx(parent, target_pos, colors, move_type)

## Animation d'impact (attaque physique) — etoiles + flash.
func _play_impact_vfx(parent: Node, pos: Vector2, colors: Array) -> void:
	# Flash blanc sur le sprite cible
	var flash := ColorRect.new()
	flash.position = pos - Vector2(50, 40)
	flash.size = Vector2(100, 80)
	flash.color = Color(1.0, 1.0, 1.0, 0.0)
	flash.z_index = 50
	parent.add_child(flash)

	var tw := parent.create_tween()
	tw.tween_property(flash, "color:a", 0.7, 0.05)
	tw.tween_property(flash, "color:a", 0.0, 0.15)
	await tw.finished
	flash.queue_free()

	# Particules d'impact
	var particles := _create_impact_particles(colors)
	particles.position = pos
	particles.z_index = 51
	parent.add_child(particles)
	particles.emitting = true

	await parent.get_tree().create_timer(0.6).timeout
	particles.emitting = false
	await parent.get_tree().create_timer(0.4).timeout
	particles.queue_free()

## Animation de projectile (attaque speciale) — orbe + trainee + impact.
func _play_projectile_vfx(parent: Node, target_pos: Vector2, colors: Array, move_type: String) -> void:
	# Point de depart (cote joueur, en bas a droite)
	var start_pos := Vector2(240, 130)

	# Orbe de projectile
	var orb := ColorRect.new()
	orb.size = Vector2(12, 12)
	orb.position = start_pos - Vector2(6, 6)
	orb.color = colors[0]
	orb.z_index = 52
	parent.add_child(orb)

	# Halo autour de l'orbe
	var halo := ColorRect.new()
	halo.size = Vector2(20, 20)
	halo.position = start_pos - Vector2(10, 10)
	halo.color = Color(colors[0].r, colors[0].g, colors[0].b, 0.3)
	halo.z_index = 51
	parent.add_child(halo)

	# Animation de vol
	var tw := parent.create_tween().set_parallel(true)
	tw.tween_property(orb, "position", target_pos - Vector2(6, 6), 0.35).set_ease(Tween.EASE_IN)
	tw.tween_property(halo, "position", target_pos - Vector2(10, 10), 0.35).set_ease(Tween.EASE_IN)
	await tw.finished

	orb.queue_free()
	halo.queue_free()

	# Impact a l'arrivee
	await _play_impact_vfx(parent, target_pos, colors)

	# Effet supplementaire par type
	await _play_type_specific_effect(parent, target_pos, move_type, colors)

## Effets supplementaires specifiques au type.
func _play_type_specific_effect(parent: Node, pos: Vector2, move_type: String, colors: Array) -> void:
	match move_type:
		"Fire":
			# Flammes residuelles
			var fire_particles := _create_fire_particles(colors)
			fire_particles.position = pos
			parent.add_child(fire_particles)
			fire_particles.emitting = true
			await parent.get_tree().create_timer(0.8).timeout
			fire_particles.emitting = false
			await parent.get_tree().create_timer(0.5).timeout
			fire_particles.queue_free()

		"Water":
			# Eclaboussures
			var splash := _create_splash_particles(colors)
			splash.position = pos
			parent.add_child(splash)
			splash.emitting = true
			await parent.get_tree().create_timer(0.6).timeout
			splash.emitting = false
			await parent.get_tree().create_timer(0.4).timeout
			splash.queue_free()

		"Electric":
			# Eclairs rapides (flash multiple)
			for i in range(3):
				var bolt := ColorRect.new()
				bolt.size = Vector2(randi_range(2, 6), randi_range(20, 40))
				bolt.position = pos + Vector2(randf_range(-30, 30), randf_range(-30, 10))
				bolt.color = colors[0]
				bolt.z_index = 53
				parent.add_child(bolt)
				var btw := parent.create_tween()
				btw.tween_property(bolt, "color:a", 0.0, 0.15)
				btw.tween_callback(bolt.queue_free)
				await parent.get_tree().create_timer(0.08).timeout

		"Grass":
			# Feuilles tourbillonnantes
			for i in range(5):
				var leaf := ColorRect.new()
				leaf.size = Vector2(4, 6)
				leaf.position = pos + Vector2(randf_range(-20, 20), randf_range(-20, 20))
				leaf.color = colors[randi() % colors.size()]
				leaf.z_index = 52
				parent.add_child(leaf)
				var ltw := parent.create_tween()
				ltw.tween_property(leaf, "position", leaf.position + Vector2(randf_range(-30, 30), -40), 0.6)
				ltw.parallel().tween_property(leaf, "color:a", 0.0, 0.6)
				ltw.tween_callback(leaf.queue_free)
			await parent.get_tree().create_timer(0.6).timeout

		"Ice":
			# Cristaux de glace
			for i in range(6):
				var crystal := ColorRect.new()
				crystal.size = Vector2(5, 5)
				crystal.rotation = randf() * TAU
				crystal.position = pos + Vector2(randf_range(-25, 25), randf_range(-25, 25))
				crystal.color = colors[randi() % colors.size()]
				crystal.z_index = 52
				parent.add_child(crystal)
				var ctw := parent.create_tween()
				ctw.tween_property(crystal, "scale", Vector2(0.1, 0.1), 0.8)
				ctw.parallel().tween_property(crystal, "color:a", 0.0, 0.8)
				ctw.tween_callback(crystal.queue_free)
			await parent.get_tree().create_timer(0.8).timeout

		"Psychic":
			# Ondulation psychique
			for i in range(3):
				var ring := ColorRect.new()
				ring.size = Vector2(10, 10)
				ring.position = pos - Vector2(5, 5)
				ring.color = Color(colors[0].r, colors[0].g, colors[0].b, 0.5)
				ring.z_index = 52
				parent.add_child(ring)
				var rtw := parent.create_tween()
				rtw.tween_property(ring, "size", Vector2(80, 80), 0.5)
				rtw.parallel().tween_property(ring, "position", pos - Vector2(40, 40), 0.5)
				rtw.parallel().tween_property(ring, "color:a", 0.0, 0.5)
				rtw.tween_callback(ring.queue_free)
				await parent.get_tree().create_timer(0.15).timeout
			await parent.get_tree().create_timer(0.3).timeout

		"Ghost":
			# Ombre rampante
			var shadow := ColorRect.new()
			shadow.size = Vector2(80, 60)
			shadow.position = pos - Vector2(40, 30)
			shadow.color = Color(0.15, 0.08, 0.25, 0.0)
			shadow.z_index = 52
			parent.add_child(shadow)
			var stw := parent.create_tween()
			stw.tween_property(shadow, "color:a", 0.6, 0.3)
			stw.tween_property(shadow, "color:a", 0.0, 0.5)
			stw.tween_callback(shadow.queue_free)
			await stw.finished

		"Dragon":
			# Energie draconique
			for i in range(8):
				var orb := ColorRect.new()
				orb.size = Vector2(6, 6)
				var angle := randf() * TAU
				var dist := randf_range(30, 50)
				orb.position = pos + Vector2(cos(angle) * dist, sin(angle) * dist)
				orb.color = colors[randi() % colors.size()]
				orb.z_index = 52
				parent.add_child(orb)
				var dtw := parent.create_tween()
				dtw.tween_property(orb, "position", pos, 0.4)
				dtw.parallel().tween_property(orb, "color:a", 0.0, 0.4)
				dtw.tween_callback(orb.queue_free)
			await parent.get_tree().create_timer(0.5).timeout

# ── Camera Shake ──────────────────────────────────────────────────────────────

## Secoue l'ecran (effet d'impact).
func shake_screen(parent: Node, intensity: float = 4.0, duration: float = 0.3) -> void:
	var original_pos := Vector2.ZERO
	# Trouver la CanvasLayer parente
	var canvas: CanvasLayer = null
	var node := parent
	while node:
		if node is CanvasLayer:
			canvas = node
			break
		node = node.get_parent()
	if not canvas:
		return

	original_pos = canvas.offset
	var tw := parent.create_tween()
	var steps := int(duration / 0.03)
	for i in range(steps):
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_property(canvas, "offset", original_pos + offset, 0.03)
	tw.tween_property(canvas, "offset", original_pos, 0.05)
	await tw.finished

## Secoue un sprite individuel (recul du Pokemon touche).
func shake_sprite(sprite: Control, intensity: float = 3.0, duration: float = 0.25) -> void:
	var orig := sprite.position
	var tw := sprite.create_tween()
	var steps := int(duration / 0.03)
	for i in range(steps):
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_property(sprite, "position", orig + offset, 0.03)
	tw.tween_property(sprite, "position", orig, 0.04)
	await tw.finished

# ── Flash d'ecran ─────────────────────────────────────────────────────────────

## Flash blanc (coup critique ou super efficace).
func flash_screen(parent: Node, color: Color = Color.WHITE, duration: float = 0.2) -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(color.r, color.g, color.b, 0.0)
	overlay.z_index = 100
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(overlay)

	var tw := parent.create_tween()
	tw.tween_property(overlay, "color:a", 0.6, duration * 0.3)
	tw.tween_property(overlay, "color:a", 0.0, duration * 0.7)
	tw.tween_callback(overlay.queue_free)
	await tw.finished

## Flash colore par type.
func flash_type(parent: Node, move_type: String) -> void:
	var colors: Array = TYPE_VFX_COLORS.get(move_type, TYPE_VFX_COLORS["Normal"])
	await flash_screen(parent, colors[0], 0.25)

# ── Animation sprite Pokemon ─────────────────────────────────────────────────

## Fait "respirer" un sprite Pokemon (idle bounce subtil).
func start_idle_animation(sprite: Control) -> Tween:
	var orig_y := sprite.position.y
	var tw := sprite.create_tween().set_loops()
	tw.tween_property(sprite, "position:y", orig_y - 1.5, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(sprite, "position:y", orig_y + 1.5, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	return tw

## Animation d'entree d'un Pokemon (slide depuis le cote).
func play_enter_animation(sprite: Control, from_left: bool = false) -> void:
	var target_pos := sprite.position
	var start_x := -100.0 if from_left else 420.0
	sprite.position.x = start_x
	sprite.modulate.a = 0.0

	var tw := sprite.create_tween().set_parallel(true)
	tw.tween_property(sprite, "position:x", target_pos.x, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(sprite, "modulate:a", 1.0, 0.3)
	await tw.finished

## Animation de KO (chute + fade).
func play_faint_animation(sprite: Control) -> void:
	var tw := sprite.create_tween().set_parallel(true)
	tw.tween_property(sprite, "position:y", sprite.position.y + 30, 0.5).set_ease(Tween.EASE_IN)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.5)
	await tw.finished

## Animation de capture (retrecissement vers la pokeball).
func play_capture_animation(sprite: Control, ball_pos: Vector2) -> void:
	var tw := sprite.create_tween().set_parallel(true)
	tw.tween_property(sprite, "scale", Vector2(0.05, 0.05), 0.6).set_ease(Tween.EASE_IN)
	tw.tween_property(sprite, "position", ball_pos, 0.6).set_ease(Tween.EASE_IN)
	tw.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.3, 0.5), 0.6)
	await tw.finished

# ── Fond de terrain ───────────────────────────────────────────────────────────

## Construit le fond de terrain pour le combat.
## Verifie d'abord si un asset PNG existe, sinon genere procedurallement.
func create_battle_background(terrain: String, parent: Node) -> void:
	var png_path := "res://assets/sprites/battle/backgrounds/%s.png" % terrain
	if ResourceLoader.exists(png_path):
		# Utiliser l'image Kimi/custom
		var tex: Texture2D = load(png_path)
		var bg := TextureRect.new()
		bg.texture = tex
		bg.size = Vector2(320, 140)
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg.z_index = -1
		parent.add_child(bg)
		return

	# Fond procedural avec gradient
	var terrain_data: Dictionary = TERRAIN_TYPES.get(terrain, TERRAIN_TYPES["grass"])
	var bg_top: Color = terrain_data["bg_top"]
	var bg_bot: Color = terrain_data["bg_bot"]
	var ground: Color = terrain_data["ground"]

	# Ciel (gradient simule)
	var sky_h := 80
	for i in range(4):
		var strip := ColorRect.new()
		strip.position = Vector2(0, i * (sky_h / 4))
		strip.size = Vector2(320, sky_h / 4 + 1)
		strip.color = bg_top.lerp(bg_bot, float(i) / 3.0)
		strip.z_index = -1
		parent.add_child(strip)

	# Sol
	var ground_rect := ColorRect.new()
	ground_rect.position = Vector2(0, sky_h)
	ground_rect.size = Vector2(320, 140 - sky_h)
	ground_rect.color = ground
	ground_rect.z_index = -1
	parent.add_child(ground_rect)

	# Details du sol selon le terrain
	match terrain:
		"grass":
			for i in range(12):
				var blade := ColorRect.new()
				blade.position = Vector2(randf_range(10, 310), randf_range(sky_h + 5, 135))
				blade.size = Vector2(2, randi_range(4, 8))
				blade.color = ground.lightened(0.15)
				blade.z_index = -1
				parent.add_child(blade)
		"cave":
			# Stalactites
			for i in range(6):
				var stala := ColorRect.new()
				stala.position = Vector2(randf_range(20, 300), 0)
				stala.size = Vector2(randi_range(3, 8), randi_range(10, 25))
				stala.color = bg_top.darkened(0.2)
				stala.z_index = -1
				parent.add_child(stala)
		"water":
			# Reflets d'eau
			for i in range(8):
				var wave := ColorRect.new()
				wave.position = Vector2(randf_range(0, 300), randf_range(sky_h + 10, 130))
				wave.size = Vector2(randi_range(15, 30), 2)
				wave.color = Color(1.0, 1.0, 1.0, 0.15)
				wave.z_index = -1
				parent.add_child(wave)

# ── Helpers particules ────────────────────────────────────────────────────────

func _create_impact_particles(colors: Array) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.amount = 12
	p.lifetime = 0.5
	p.one_shot = true
	p.explosiveness = 0.9

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 40.0
	mat.initial_velocity_max = 80.0
	mat.gravity = Vector3(0, 120, 0)
	mat.scale_min = 0.5
	mat.scale_max = 1.2
	mat.color = colors[0] if colors.size() > 0 else Color.WHITE
	p.process_material = mat
	return p

func _create_fire_particles(colors: Array) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.amount = 20
	p.lifetime = 0.8
	p.one_shot = true
	p.explosiveness = 0.5

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 30.0
	mat.initial_velocity_max = 60.0
	mat.gravity = Vector3(0, -40, 0)
	mat.scale_min = 0.3
	mat.scale_max = 1.5
	mat.color = colors[0] if colors.size() > 0 else Color(1.0, 0.5, 0.1)
	p.process_material = mat
	return p

func _create_splash_particles(colors: Array) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.amount = 15
	p.lifetime = 0.6
	p.one_shot = true
	p.explosiveness = 0.8

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 120.0
	mat.initial_velocity_min = 50.0
	mat.initial_velocity_max = 100.0
	mat.gravity = Vector3(0, 200, 0)
	mat.scale_min = 0.3
	mat.scale_max = 0.8
	mat.color = colors[0] if colors.size() > 0 else Color(0.3, 0.6, 1.0)
	p.process_material = mat
	return p
