extends Node3D
## Stylized ancient-Israel coastal blockout: Galilee shore market (Capernaum area),
## clearer roads Galilee -> Cana -> Nazareth -> Tabor -> south toward Jerusalem.
## Readable city pads and simple wooden signposts.

func _ready() -> void:
	_build_ground()
	_build_water()
	_build_market_stalls()
	_build_buildings()
	_build_docks()
	_build_props()
	_build_travel_paths()
	_build_city_pads()
	_build_signposts()
	_build_tabor_rise()

func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	return m

func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, rot_y: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = _mat(color)
	mi.position = pos
	mi.rotation.y = rot_y
	parent.add_child(mi)
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	mi.add_child(body)
	return mi

func _build_ground() -> void:
	_box(self, Vector3(100, 0.4, 120), Vector3(0, -0.2, 12), Color(0.72, 0.62, 0.42))
	_box(self, Vector3(18, 0.15, 14), Vector3(-6, 0.05, 4), Color(0.55, 0.5, 0.42))
	_box(self, Vector3(14, 1.2, 10), Vector3(-20, 0.5, 14), Color(0.65, 0.58, 0.42))
	_box(self, Vector3(10, 2.0, 10), Vector3(-12, 1.0, 18), Color(0.6, 0.55, 0.4))

func _build_water() -> void:
	_box(self, Vector3(90, 0.3, 28), Vector3(4, -0.35, -26), Color(0.2, 0.45, 0.65))

func _build_market_stalls() -> void:
	var stall_color := Color(0.55, 0.35, 0.2)
	var cloth := Color(0.7, 0.25, 0.2)
	for i in range(5):
		var x := -12.0 + i * 3.5
		_box(self, Vector3(2.4, 0.8, 1.6), Vector3(x, 0.4, 6), stall_color)
		_box(self, Vector3(2.6, 0.08, 1.8), Vector3(x, 1.05, 6), cloth)
	for i in range(3):
		var x := -8.0 + i * 4.0
		_box(self, Vector3(2.2, 0.7, 1.4), Vector3(x, 0.35, 10), Color(0.45, 0.3, 0.18))

func _build_buildings() -> void:
	var stone := Color(0.78, 0.72, 0.58)
	var mud := Color(0.65, 0.55, 0.4)
	var homes := [
		Vector3(12, 2.5, 8), Vector3(18, 3.0, 2), Vector3(14, 2.2, -4),
		Vector3(-18, 2.8, 8), Vector3(-22, 2.0, 0), Vector3(8, 2.5, 16),
		Vector3(-4, 2.2, 18), Vector3(20, 2.6, 14),
		Vector3(-20, 2.4, 12), Vector3(10, 2.0, -2),
		Vector3(-16, 2.2, 12), Vector3(-20, 2.0, 9),
		Vector3(-26, 2.4, 15), Vector3(-22, 2.1, 18),
		Vector3(16, 2.0, -2), Vector3(20, 2.3, -6),
	]
	for h in homes:
		var sx := 4.0 + randf() * 2.0
		var sz := 3.5 + randf() * 1.5
		_box(self, Vector3(sx, h.y, sz), Vector3(h.x, h.y * 0.5, h.z), stone if randf() > 0.4 else mud)
		_box(self, Vector3(sx + 0.3, 0.2, sz + 0.3), Vector3(h.x, h.y + 0.1, h.z), Color(0.5, 0.45, 0.35))

func _build_docks() -> void:
	var wood := Color(0.42, 0.28, 0.16)
	_box(self, Vector3(8, 0.35, 14), Vector3(-6, 0.1, -12), wood)
	_box(self, Vector3(3, 0.35, 10), Vector3(-2, 0.1, -16), wood)
	_box(self, Vector3(6, 0.3, 8), Vector3(16, 0.1, -10), wood)
	for i in range(4):
		_box(self, Vector3(0.35, 1.2, 0.35), Vector3(-9, 0.2, -8.0 - i * 3.0), Color(0.3, 0.2, 0.12))

func _build_props() -> void:
	var crate := Color(0.5, 0.35, 0.2)
	_box(self, Vector3(0.8, 0.6, 0.8), Vector3(-5, 0.3, 5), crate)
	_box(self, Vector3(0.7, 0.5, 0.7), Vector3(-4.2, 0.25, 5.4), crate)
	_box(self, Vector3(1.0, 0.4, 0.6), Vector3(-7, 0.2, 4.5), Color(0.35, 0.35, 0.4))

func _build_travel_paths() -> void:
	var dust := Color(0.68, 0.58, 0.4)
	var road := Color(0.62, 0.52, 0.36)
	_box(self, Vector3(4.5, 0.06, 36), Vector3(-6, 0.03, -4), dust)
	_box(self, Vector3(30, 0.06, 3.8), Vector3(-10, 0.03, 8), road)
	_box(self, Vector3(3.6, 0.06, 14), Vector3(-20, 0.03, 12), road)
	_box(self, Vector3(12, 0.06, 3.4), Vector3(-22, 0.03, 16), road)
	_box(self, Vector3(16, 0.06, 3.4), Vector3(-16, 0.03, 17), road)
	_box(self, Vector3(3.4, 0.06, 8), Vector3(-12, 0.03, 16), road)
	_box(self, Vector3(22, 0.06, 3.5), Vector3(6, 0.03, 0), dust)
	_box(self, Vector3(3.8, 0.06, 22), Vector3(0, 0.03, 18), road)
	_box(self, Vector3(3.8, 0.06, 18), Vector3(2, 0.03, 30), road)
	_box(self, Vector3(3.5, 0.06, 12), Vector3(4, 0.03, 38), road)
	_box(self, Vector3(10, 0.06, 3.2), Vector3(8, 0.03, 34), road)
	_box(self, Vector3(8, 0.06, 3.2), Vector3(1, 0.03, 40), road)

func _build_city_pads() -> void:
	var plaza := Color(0.7, 0.6, 0.45)
	var pads := [
		{"pos": Vector3(8, 0.04, 4), "size": Vector3(8, 0.08, 8)},
		{"pos": Vector3(-18, 0.04, 10), "size": Vector3(9, 0.08, 9)},
		{"pos": Vector3(-24, 0.04, 16), "size": Vector3(7, 0.08, 7)},
		{"pos": Vector3(18, 0.04, -4), "size": Vector3(7, 0.08, 7)},
		{"pos": Vector3(4, 0.04, 36), "size": Vector3(10, 0.08, 10)},
		{"pos": Vector3(0, 0.04, 42), "size": Vector3(6, 0.08, 6)},
	]
	for p in pads:
		_box(self, p["size"], p["pos"], plaza)

func _build_signposts() -> void:
	var signs := [
		{"pos": Vector3(-10, 0, 8), "text": "<- Cana"},
		{"pos": Vector3(-18, 0, 12), "text": "Nazareth ->"},
		{"pos": Vector3(-14, 0, 16), "text": "^ Tabor"},
		{"pos": Vector3(2, 0, 2), "text": "Bethsaida ->"},
		{"pos": Vector3(0, 0, 20), "text": "v Samaria / Jerusalem"},
		{"pos": Vector3(4, 0, 34), "text": "Olives ->  Golgotha v"},
	]
	for s in signs:
		_signpost(s["pos"], s["text"])

func _signpost(pos: Vector3, text: String) -> void:
	var wood := Color(0.4, 0.28, 0.15)
	_box(self, Vector3(0.18, 2.2, 0.18), pos + Vector3(0, 1.1, 0), wood)
	_box(self, Vector3(1.8, 0.7, 0.12), pos + Vector3(0, 2.0, 0), Color(0.55, 0.42, 0.25))
	var lbl := Label3D.new()
	lbl.text = text
	lbl.font_size = 36
	lbl.position = pos + Vector3(0, 2.0, 0.12)
	lbl.modulate = Color(0.95, 0.9, 0.75)
	lbl.outline_size = 4
	add_child(lbl)

func _build_tabor_rise() -> void:
	_box(self, Vector3(8, 1.5, 8), Vector3(-12, 0.75, 18), Color(0.58, 0.52, 0.38))
	_box(self, Vector3(5, 2.5, 5), Vector3(-12, 2.0, 18), Color(0.6, 0.55, 0.4))
	_box(self, Vector3(3, 0.3, 6), Vector3(-12, 0.2, 14), Color(0.62, 0.52, 0.36))
