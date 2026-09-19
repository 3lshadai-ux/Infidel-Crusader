extends RefCounted
class_name WorldTextures
## Photo-based CC0 albedo maps (Poly Haven–derived) with triplanar materials.
## Loads res://assets/textures/*.png, or *.png.b64 (base64 text) if PNG missing.

const TEX_DIR := "res://assets/textures/"

static var _mat_cache: Dictionary = {}
static var _tex_cache: Dictionary = {}

static func mat(kind: String, tint: Color = Color.WHITE, roughness: float = 0.88, metallic: float = 0.0) -> StandardMaterial3D:
	var key := "%s_%.3f_%.3f_%.3f_%.2f" % [kind, tint.r, tint.g, tint.b, roughness]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.roughness = roughness
	m.metallic = metallic
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var tex := _albedo(kind)
	if tex:
		m.albedo_texture = tex
		m.uv1_triplanar = true
		m.uv1_triplanar_sharpness = 4.0
		m.uv1_scale = _scale_for(kind)
	if kind == "water":
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color.a = 0.82
		m.roughness = 0.15
		m.metallic = 0.35
	_mat_cache[key] = m
	return m

static func _file_for(kind: String) -> String:
	match kind:
		"sand", "dust", "ground":
			return "sand.png"
		"stone", "plaza", "mud":
			return "stone.png"
		"wood", "crate":
			return "wood.png"
		"water":
			return "water.png"
		"cloth", "robe":
			return "cloth.png"
		"robe_cream":
			return "robe_cream.png"
		"tunic":
			return "tunic.png"
		"roof":
			return "roof.png"
		"skin":
			return "skin.png"
		"leaf":
			return "leaf.png"
		"trunk", "bark":
			return "bark.png"
		"dirt":
			return "dirt.png"
		"plaster":
			return "plaster.png"
		"cobble":
			return "cobble.png"
		"wool":
			return "wool.png"
		"leather":
			return "leather.png"
		"sky":
			return "sky_panorama.png"
		_:
			return "sand.png"

static func _scale_for(kind: String) -> Vector3:
	match kind:
		"sand", "dust", "ground", "dirt":
			return Vector3(0.07, 0.07, 0.07)
		"stone", "mud", "plaza", "cobble", "plaster":
			return Vector3(0.11, 0.11, 0.11)
		"wood", "crate", "trunk", "bark":
			return Vector3(0.18, 0.18, 0.18)
		"water":
			return Vector3(0.04, 0.04, 0.04)
		"cloth", "roof", "robe", "robe_cream", "tunic", "wool":
			return Vector3(0.22, 0.22, 0.22)
		"skin":
			return Vector3(0.35, 0.35, 0.35)
		"leaf":
			return Vector3(0.28, 0.28, 0.28)
		_:
			return Vector3(0.12, 0.12, 0.12)

static func _albedo(kind: String) -> Texture2D:
	var fname := _file_for(kind)
	if _tex_cache.has(fname):
		return _tex_cache[fname]
	var tex: Texture2D = null
	var png_path := TEX_DIR + fname
	if ResourceLoader.exists(png_path):
		tex = load(png_path) as Texture2D
	if tex == null:
		tex = _from_b64(fname)
	if tex == null:
		tex = _fallback_noise(kind)
	_tex_cache[fname] = tex
	return tex

static func _from_b64(fname: String) -> Texture2D:
	var b64_path := TEX_DIR + fname + ".b64"
	if not FileAccess.file_exists(b64_path):
		return null
	var f := FileAccess.open(b64_path, FileAccess.READ)
	if f == null:
		return null
	var b64 := f.get_as_text().strip_edges()
	var bytes := Marshalls.base64_to_raw(b64)
	if bytes.is_empty():
		return null
	var img := Image.new()
	var err := img.load_png_from_buffer(bytes)
	if err != OK:
		return null
	return ImageTexture.create_from_image(img)

static func _fallback_noise(kind: String) -> Texture2D:
	var img := Image.create(128, 128, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(kind.hash())
	for y in range(128):
		for x in range(128):
			var v := rng.randi_range(90, 170)
			img.set_pixel(x, y, Color8(v, v, v))
	return ImageTexture.create_from_image(img)
