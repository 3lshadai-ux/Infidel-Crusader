extends Node3D
## Stylized ancient-Israel coastal blockout: Galilee shore market (Capernaum area),
## dusty paths toward Cana/Nazareth/Tabor; south road stubs toward Jerusalem.

func _ready() -> void:
	_build_ground()
	_build_water()
	_build_market_stalls()
	_build_buildings()
	_build_docks()
	_build_props()
	_build_travel_paths()

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
	for i in range(4):
		_box(self, Vector3(0.35, 1.2, 0.35), Vector3(-9, 0.2, -8.0 - i * 3.0), Color(0.3, 0.2, 0.12))

func _build_props() -> void:
	var crate := Color(0.5, 0.35, 0.2)
	_box(self, Vector3(0.8, 0.6, 0.8), Vector3(-5, 0.3, 5), crate)
	_box(self, Vector3(0.7, 0.5, 0.7), Vector3(-4.2, 0.25, 5.4), crate)
	_box(self, Vector3(1.0, 0.4, 0.6), Vector3(-7, 0.2, 4.5), Color(0.35, 0.35, 0.4))

func _build_travel_paths() -> void:
	var dust := Color(0.68, 0.58, 0.4)
	_box(self, Vector3(4, 0.05, 30), Vector3(-6, 0.02, -2), dust)
	_box(self, Vector3(28, 0.05, 3.5), Vector3(-10, 0.02, 10), dust)
	_box(self, Vector3(3.5, 0.05, 40), Vector3(2, 0.02, 28), dust)
	_box(self, Vector3(3, 0.05, 12), Vector3(-10, 0.02, 14), dust)
