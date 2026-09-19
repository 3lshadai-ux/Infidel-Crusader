extends WorldEnvironment
## Applies CC0 panorama sky when available (PNG or PNG.b64).

func _ready() -> void:
	var tex := _load_sky_tex()
	if tex == null:
		return
	var sky := Sky.new()
	var pan := PanoramaSkyMaterial.new()
	pan.panorama = tex
	pan.energy_multiplier = 1.05
	sky.sky_material = pan
	if environment == null:
		environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES

func _load_sky_tex() -> Texture2D:
	var png := "res://assets/textures/sky_panorama.png"
	if ResourceLoader.exists(png):
		return load(png) as Texture2D
	var b64p := "res://assets/textures/sky_panorama.png.b64"
	if not FileAccess.file_exists(b64p):
		return null
	var f := FileAccess.open(b64p, FileAccess.READ)
	if f == null:
		return null
	var bytes := Marshalls.base64_to_raw(f.get_as_text().strip_edges())
	if bytes.is_empty():
		return null
	var img := Image.new()
	if img.load_png_from_buffer(bytes) != OK:
		return null
	return ImageTexture.create_from_image(img)
