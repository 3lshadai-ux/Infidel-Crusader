class_name MiracleSetpieces
extends RefCounted
## Cinematic set-piece builders/FX for MiracleEncounter (original visuals only).

static func mat(c: Color, emission: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emission
	return m

static func mesh_box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, emit: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat(color, emit)
	mi.position = pos
	parent.add_child(mi)
	return mi

static func mesh_cyl(parent: Node3D, r: float, h: float, pos: Vector3, color: Color, emit: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = r * 0.9
	cyl.bottom_radius = r
	cyl.height = h
	mi.mesh = cyl
	mi.material_override = mat(color, emit)
	mi.position = pos
	parent.add_child(mi)
	return mi

static func stage_cana_wedding(stage: Node3D) -> void:
	mesh_box(stage, Vector3(3.5, 0.15, 1.2), Vector3(0, 0.2, -2.5), Color(0.45, 0.3, 0.18))
	for i in range(4):
		var x := -2.5 + i * 1.6
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.35, 0.45) if i % 2 == 0 else Color(0.95, 0.75, 0.35)
		light.light_energy = 1.4
		light.omni_range = 6.0
		light.position = Vector3(x, 2.2, -1.5)
		stage.add_child(light)
		mesh_cyl(stage, 0.08, 1.6, Vector3(x, 0.8, -1.5), Color(0.5, 0.35, 0.2))
	for i in range(5):
		var angle := TAU * float(i) / 5.0
		var g := mesh_cyl(stage, 0.28, 1.1, Vector3(cos(angle) * 4.5, 0.55, sin(angle) * 4.5 - 1.0), Color(0.7, 0.55, 0.45))
		var head := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.18
		sm.height = 0.36
		head.mesh = sm
		head.material_override = mat(Color(0.85, 0.7, 0.55))
		head.position = Vector3(0, 0.75, 0)
		g.add_child(head)
	var feast := Label3D.new()
	feast.text = "Wedding Feast -- Cana"
	feast.font_size = 36
	feast.position = Vector3(0, 3.8, -2.5)
	feast.modulate = Color(0.95, 0.8, 0.95)
	stage.add_child(feast)

static func stage_boat_dock(stage: Node3D) -> void:
	mesh_box(stage, Vector3(4.5, 0.35, 1.8), Vector3(0, 0.25, -3.5), Color(0.4, 0.28, 0.16))
	mesh_box(stage, Vector3(3.2, 0.5, 1.4), Vector3(0, 0.35, -5.2), Color(0.35, 0.22, 0.12))
	for i in range(6):
		for j in range(4):
			mesh_box(stage, Vector3(0.08, 0.04, 0.9), Vector3(-1.2 + i * 0.45, 0.15 + j * 0.08, -4.0), Color(0.22, 0.58, 0.38))
	var lbl := Label3D.new()
	lbl.text = "Let down the net"
	lbl.font_size = 32
	lbl.position = Vector3(0, 2.8, -3.5)
	stage.add_child(lbl)

static func stage_boat_simple(stage: Node3D) -> void:
	mesh_box(stage, Vector3(3.5, 0.4, 1.5), Vector3(0, 0.3, -4.0), Color(0.38, 0.25, 0.14))
	mesh_box(stage, Vector3(0.15, 1.8, 0.15), Vector3(0, 1.1, -4.0), Color(0.3, 0.2, 0.12))

static func stage_crowd(stage: Node3D) -> void:
	for i in range(12):
		var angle := TAU * float(i) / 12.0
		var r := 5.0 + (i % 3) * 0.6
		mesh_cyl(stage, 0.25, 1.0, Vector3(cos(angle) * r, 0.5, sin(angle) * r), Color(0.65, 0.5, 0.4))
	mesh_cyl(stage, 0.5, 0.35, Vector3(0, 0.25, -2.0), Color(0.55, 0.4, 0.22))
	mesh_box(stage, Vector3(0.35, 0.12, 0.2), Vector3(-0.15, 0.5, -2.0), Color(0.85, 0.7, 0.4))
	mesh_box(stage, Vector3(0.35, 0.12, 0.2), Vector3(0.15, 0.5, -2.0), Color(0.85, 0.7, 0.4))
	mesh_box(stage, Vector3(0.4, 0.1, 0.15), Vector3(0, 0.55, -1.85), Color(0.45, 0.55, 0.65))
	var lbl := Label3D.new()
	lbl.text = "Five loaves and two fishes"
	lbl.font_size = 30
	lbl.position = Vector3(0, 2.6, -2.0)
	stage.add_child(lbl)

static func stage_tabor_cloud(stage: Node3D) -> void:
	var cloud := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 2.4
	sm.height = 3.2
	cloud.mesh = sm
	var m := mat(Color(1, 1, 1, 0.35), 2.5)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cloud.material_override = m
	cloud.position = Vector3(0, 5.5, 0)
	stage.add_child(cloud)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.95, 0.75)
	light.light_energy = 3.0
	light.omni_range = 16.0
	light.position = Vector3(0, 5, 0)
	stage.add_child(light)

static func stage_garden_night(stage: Node3D) -> void:
	for i in range(6):
		var angle := TAU * float(i) / 6.0
		mesh_cyl(stage, 0.2, 2.2, Vector3(cos(angle) * 4.0, 1.1, sin(angle) * 4.0), Color(0.18, 0.48, 0.22))
		var leaf := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.9
		sm.height = 1.2
		leaf.mesh = sm
		leaf.material_override = mat(Color(0.2, 0.62, 0.28))
		leaf.position = Vector3(cos(angle) * 4.0, 2.4, sin(angle) * 4.0)
		stage.add_child(leaf)

static func stage_golgotha_path(stage: Node3D) -> void:
	for i in range(5):
		mesh_box(stage, Vector3(0.8, 0.06, 0.35), Vector3(0, 0.05, 4.0 - i * 1.5), Color(0.35, 0.3, 0.28), 0.3)
	for x in [-3.0, 3.0]:
		var light := OmniLight3D.new()
		light.light_color = Color(0.85, 0.55, 0.35)
		light.light_energy = 1.8
		light.omni_range = 8.0
		light.position = Vector3(x, 2.5, 0)
		stage.add_child(light)

static func spawn_wind(fx: Node3D) -> void:
	for i in range(10):
		var streak := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.08, 0.08, 1.4)
		streak.mesh = box
		streak.material_override = mat(Color(0.75, 0.8, 0.9, 0.5), 0.4)
		streak.position = Vector3(randf_range(-6, 6), randf_range(1.5, 4.5), randf_range(-6, 6))
		streak.set_meta("wind", true)
		streak.set_meta("spd", randf_range(3.0, 7.0))
		fx.add_child(streak)

static func fx_simple(fx: Node3D, color: Color) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 5.0
	light.omni_range = 12.0
	light.position = Vector3(0, 3, 0)
	fx.add_child(light)

static func fx_wine(fx: Node3D, jars: Array) -> void:
	for jar in jars:
		paint_jar_wine(jar)
	fx_simple(fx, Color(0.85, 0.12, 0.22))
	for i in range(8):
		var p := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.08
		sm.height = 0.16
		p.mesh = sm
		p.material_override = mat(Color(0.82, 0.05, 0.16), 1.8)
		var angle := TAU * float(i) / 8.0
		p.position = Vector3(cos(angle) * 2.0, 0.5, sin(angle) * 2.0)
		fx.add_child(p)

static func fx_nets_catch(fx: Node3D) -> void:
	for i in range(16):
		var fish := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.35, 0.1, 0.15)
		fish.mesh = box
		fish.material_override = mat(Color(0.18, 0.62, 0.42), 0.65)
		fish.position = Vector3(randf_range(-1.5, 1.5), randf_range(0.3, 1.2), randf_range(-5.5, -3.0))
		fx.add_child(fish)
	fx_simple(fx, Color(0.1, 0.55, 1.0))

static func fx_storm_calm(fx: Node3D) -> void:
	fx_simple(fx, Color(0.7, 0.9, 1.0))
	var lbl := Label3D.new()
	lbl.text = "Peace, be still."
	lbl.font_size = 48
	lbl.position = Vector3(0, 4.5, 0)
	lbl.modulate = Color(0.85, 0.95, 1.0)
	fx.add_child(lbl)

static func fx_loaves(fx: Node3D) -> void:
	fx_simple(fx, Color(0.9, 0.75, 0.35))
	for i in range(20):
		var food := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.25, 0.08, 0.15) if i % 2 == 0 else Vector3(0.3, 0.08, 0.12)
		food.mesh = box
		food.material_override = mat(Color(0.85, 0.7, 0.4) if i % 2 == 0 else Color(0.45, 0.55, 0.65), 0.4)
		var angle := TAU * float(i) / 20.0
		var r := 1.0 + (i % 5) * 0.35
		food.position = Vector3(cos(angle) * r, 0.4 + (i % 4) * 0.15, sin(angle) * r - 2.0)
		fx.add_child(food)

static func fx_transfiguration(fx: Node3D) -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.95, 0.7)
	light.light_energy = 12.0
	light.omni_range = 22.0
	light.position = Vector3(0, 4, 0)
	fx.add_child(light)
	var sphere := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.6
	sm.height = 3.2
	sphere.mesh = sm
	var m := mat(Color(1, 0.95, 0.7, 0.55), 5.0)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere.material_override = m
	sphere.position = Vector3(0, 3.8, 0)
	fx.add_child(sphere)
	var cloud := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 2.8
	cm.height = 4.0
	cloud.mesh = cm
	var cmat := mat(Color(1, 1, 1, 0.25), 2.0)
	cmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cloud.material_override = cmat
	cloud.position = Vector3(0, 4.5, 0)
	fx.add_child(cloud)
	var voice := Label3D.new()
	voice.text = "A voice out of the cloud..."
	voice.font_size = 40
	voice.position = Vector3(0, 7.2, 0)
	voice.modulate = Color(1, 0.95, 0.8)
	fx.add_child(voice)

static func fx_gethsemane(fx: Node3D) -> void:
	fx_simple(fx, Color(0.25, 0.7, 0.4))
	var quiet := Label3D.new()
	quiet.text = "Nevertheless not as I will, but as thou wilt."
	quiet.font_size = 28
	quiet.position = Vector3(0, 3.5, 0)
	quiet.modulate = Color(0.45, 0.95, 0.55)
	fx.add_child(quiet)

static func fx_crucifixion(fx: Node3D) -> void:
	var beam := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.35, 6.0, 0.35)
	beam.mesh = box
	var m := mat(Color(0.3, 0.22, 0.16))
	beam.material_override = m
	beam.position = Vector3(0, 3.0, 0)
	fx.add_child(beam)
	var cross := MeshInstance3D.new()
	var box2 := BoxMesh.new()
	box2.size = Vector3(2.6, 0.3, 0.3)
	cross.mesh = box2
	cross.material_override = m
	cross.position = Vector3(0, 4.6, 0)
	fx.add_child(cross)
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.95, 0.65, 0.4)
	glow.light_energy = 4.5
	glow.omni_range = 16.0
	glow.position = Vector3(0, 5, -1.5)
	fx.add_child(glow)
	var rim := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.8
	sm.height = 3.6
	rim.mesh = sm
	var rmat := mat(Color(0.9, 0.5, 0.3, 0.2), 1.5)
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rim.material_override = rmat
	rim.position = Vector3(0, 4.5, -0.5)
	fx.add_child(rim)

static func paint_jar_water(jar: Node3D) -> void:
	var water := jar.get_node_or_null("Water")
	if water:
		water.visible = true
		water.material_override = mat(Color(0.12, 0.48, 0.95), 0.55)
	if jar is MeshInstance3D:
		(jar as MeshInstance3D).material_override = mat(Color(0.5, 0.48, 0.42), 0.2)

static func paint_jar_wine(jar: Node3D) -> void:
	jar.set_meta("wine", true)
	var water := jar.get_node_or_null("Water")
	if water:
		water.visible = true
		water.material_override = mat(Color(0.78, 0.06, 0.18), 1.6)
	if jar is MeshInstance3D:
		(jar as MeshInstance3D).material_override = mat(Color(0.55, 0.12, 0.42), 1.1)

static func spawn_waterpots(parent: Node3D, count: int) -> Array:
	var jars: Array = []
	for i in range(count):
		var jar := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.35
		cyl.bottom_radius = 0.4
		cyl.height = 0.9
		jar.mesh = cyl
		jar.material_override = mat(Color(0.55, 0.5, 0.42))
		var angle := TAU * float(i) / float(count)
		jar.position = Vector3(cos(angle) * 3.2, 0.45, sin(angle) * 3.2)
		jar.set_meta("filled", false)
		jar.set_meta("wine", false)
		parent.add_child(jar)
		jars.append(jar)
		var lbl := Label3D.new()
		lbl.text = "Jar %d" % (i + 1)
		lbl.font_size = 28
		lbl.position = Vector3(0, 0.7, 0)
		jar.add_child(lbl)
		var water := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.28
		disc.bottom_radius = 0.28
		disc.height = 0.05
		water.mesh = disc
		water.material_override = mat(Color(0.12, 0.48, 0.95), 0.45)
		water.position = Vector3(0, 0.2, 0)
		water.visible = false
		water.name = "Water"
		jar.add_child(water)
	return jars
