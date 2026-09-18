extends Node3D
## Labeled region markers for stylized ancient-Israel blockout.

func _ready() -> void:
	for loc_id in GameState.map_locations.keys():
		var data: Dictionary = GameState.map_locations[loc_id]
		var pos: Vector3 = data.get("pos", Vector3.ZERO)
		var label_name: String = str(data.get("name", loc_id))
		var is_v0: bool = str(data.get("detail", "later")) == "v0"
		_spawn_marker(loc_id, pos, label_name, is_v0)

func _spawn_marker(loc_id: String, pos: Vector3, label_name: String, is_v0: bool) -> void:
	var root := Node3D.new()
	root.name = "Loc_%s" % loc_id
	root.position = pos
	add_child(root)

	var pad := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(3.2 if is_v0 else 2.0, 0.12, 3.2 if is_v0 else 2.0)
	pad.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.55, 0.25) if is_v0 else Color(0.45, 0.45, 0.5)
	pad.material_override = mat
	pad.position.y = 0.06
	root.add_child(pad)

	var lbl := Label3D.new()
	lbl.text = label_name
	lbl.font_size = 42 if is_v0 else 32
	lbl.position = Vector3(0, 2.2, 0)
	lbl.modulate = Color(1, 0.95, 0.7) if is_v0 else Color(0.75, 0.75, 0.8)
	lbl.outline_size = 6
	root.add_child(lbl)

	var pillar := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.15
	cyl.bottom_radius = 0.2
	cyl.height = 1.6
	pillar.mesh = cyl
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.9, 0.75, 0.3) if is_v0 else Color(0.5, 0.5, 0.55)
	# Emphasize major-beat sites
	if loc_id in ["tabor", "olives_gethsemane", "golgotha"]:
		pmat.emission_enabled = true
		pmat.emission = Color(1, 0.85, 0.2)
		pmat.emission_energy_multiplier = 1.5
	pillar.material_override = pmat
	pillar.position.y = 0.8
	root.add_child(pillar)
