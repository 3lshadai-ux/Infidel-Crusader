extends Node3D
## Labeled region markers for stylized ancient-Israel blockout.
## Larger pads for v0 cities; emissive pillars for major beats; road arrows.

func _ready() -> void:
	for loc_id in GameState.map_locations.keys():
		var data: Dictionary = GameState.map_locations[loc_id]
		var pos: Vector3 = data.get("pos", Vector3.ZERO)
		var label_name: String = str(data.get("name", loc_id))
		var is_v0: bool = str(data.get("detail", "later")) == "v0"
		_spawn_marker(loc_id, pos, label_name, is_v0)
	_spawn_road_hints()

func _spawn_marker(loc_id: String, pos: Vector3, label_name: String, is_v0: bool) -> void:
	var root := Node3D.new()
	root.name = "Loc_%s" % loc_id
	root.position = pos
	add_child(root)

	var pad := MeshInstance3D.new()
	var box := BoxMesh.new()
	var pad_size := 4.5 if is_v0 else 2.4
	if loc_id in ["cana", "jerusalem", "tabor"]:
		pad_size = 5.5
	box.size = Vector3(pad_size, 0.14, pad_size)
	pad.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.78, 0.58, 0.28) if is_v0 else Color(0.45, 0.45, 0.5)
	pad.material_override = mat
	pad.position.y = 0.08
	root.add_child(pad)

	var lbl := Label3D.new()
	lbl.text = label_name
	lbl.font_size = 48 if is_v0 else 34
	lbl.position = Vector3(0, 2.4, 0)
	lbl.modulate = Color(1, 0.95, 0.7) if is_v0 else Color(0.75, 0.75, 0.8)
	lbl.outline_size = 8
	root.add_child(lbl)

	var pillar := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.18
	cyl.bottom_radius = 0.24
	cyl.height = 2.0 if is_v0 else 1.4
	pillar.mesh = cyl
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.9, 0.75, 0.3) if is_v0 else Color(0.5, 0.5, 0.55)
	if loc_id in ["tabor", "olives_gethsemane", "golgotha"]:
		pmat.emission_enabled = true
		pmat.emission = Color(1, 0.85, 0.2)
		pmat.emission_energy_multiplier = 1.8
	elif loc_id == "cana":
		pmat.emission_enabled = true
		pmat.emission = Color(0.7, 0.35, 0.85)
		pmat.emission_energy_multiplier = 1.2
	pillar.material_override = pmat
	pillar.position.y = 1.0
	root.add_child(pillar)

func _spawn_road_hints() -> void:
	# Small chevrons along main corridors
	var hints := [
		{"pos": Vector3(-12, 0.05, 8), "rot": 0.0},
		{"pos": Vector3(-18, 0.05, 13), "rot": PI * 0.5},
		{"pos": Vector3(-14, 0.05, 17), "rot": 0.0},
		{"pos": Vector3(0, 0.05, 24), "rot": 0.0},
		{"pos": Vector3(4, 0.05, 36), "rot": 0.0},
	]
	for h in hints:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.2, 0.08, 0.35)
		mi.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.85, 0.7, 0.35)
		mi.material_override = mat
		mi.position = h["pos"]
		mi.rotation.y = h["rot"]
		add_child(mi)
