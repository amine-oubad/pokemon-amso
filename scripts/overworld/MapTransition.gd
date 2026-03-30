class_name MapTransition
extends Area2D
## Zone de transition entre maps.
## Quand le joueur entre dans cette zone, on change de scène.
##
## Utilisation depuis un script de map :
##   var t := MapTransition.new()
##   t.target_scene    = "res://scenes/overworld/maps/Route1.tscn"
##   t.spawn_position  = Vector2(160, 32)
##   var cs := CollisionShape2D.new()
##   var rs := RectangleShape2D.new(); rs.size = Vector2(32, 24); cs.shape = rs
##   t.add_child(cs)
##   add_child(t)

var target_scene:   String  = ""
var spawn_position: Vector2 = Vector2.ZERO

var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _triggered or target_scene.is_empty():
		return
	if not (body.get_script() and body.get_script().get_global_name() == &"Player"):
		return
	_triggered = true
	GameState.pending_spawn_position = spawn_position
	get_tree().change_scene_to_file(target_scene)
