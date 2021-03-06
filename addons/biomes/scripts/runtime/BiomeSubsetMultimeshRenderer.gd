extends MultiMeshInstance

export (Array) var sampling_array = []
export (bool) var enable_shadows = false
export (Image) var densitymap
export (Image) var heightmap
export (int) var id = -1
export (int) var maximum_instance_count = 100
export (Mesh) var mesh = preload("res://assets/meshes/spheremesh.tres")
export (Transform) var terrain_inv_transform
export (Vector2) var chunk_size = Vector2(10, 10)
export (Vector2) var chunk_position = Vector2(0, 0)
export (Vector2) var stamp_size = Vector2(256, 256)
export (float) var dithering_scale = 10.0
export (Vector3) var object_scale = Vector3(1, 1, 1)
export (float) var object_scale_variation = 0.3
export (float) var object_rotation_variation = 3.14 * 2.0

export (Vector2) var terrain_size = Vector2(1, 1)
export (Vector2) var terrain_pivot = Vector2(0.5, 0.5)

var _visibility_height_range = 800


func _dither_density(fade: float, pos: Vector2):
	var limit: Array = [
		0.5625,
		0.1875,
		0.6875,
		0.8125,
		0.3125,
		0.9375,
		0.0625,
		0.4375,
		0.25,
		0.75,
		0.125,
		0.625,
		1.0,
		0.5,
		0.875,
		0.375
	]
	var x: int = int(pos.x) % 4
	var y: int = int(pos.y) % 4
	var index: int = x + y * 4
	return fade < limit[index]


func _is_in_range(pixel: Vector2, size: Vector2):
	return pixel.x >= 0 && pixel.x < size.x && pixel.y >= 0 && pixel.y < size.y


func _sample_by_denisty():
	var sampled_points: Array = []
	var density_size = densitymap.get_size()
	var heightmap_size = heightmap.get_size() if heightmap else Vector2(0, 0)
	var texture_density_scale = density_size / terrain_size
	var texture_heightmap_scale = heightmap_size / terrain_size
	var cell_cords = terrain_inv_transform.xform(Vector3(chunk_position.x, 0, chunk_position.y))

	cell_cords += Vector3(terrain_pivot.x, 0, terrain_pivot.y)
	densitymap.lock()
	if heightmap != null:
		heightmap.lock()
	for pos in sampling_array:
		var pos_terrain: Vector2 = (
			pos / stamp_size * chunk_size
			+ Vector2(cell_cords.x, cell_cords.z)
		)
		var tex_coords: Vector2 = (pos_terrain * texture_density_scale).floor()
		if not _is_in_range(tex_coords, density_size):
			continue

		var color = densitymap.get_pixelv(tex_coords)

		if _dither_density(1.0 - color.r, pos / dithering_scale):
			#get heighmap
			color.r = 0.0
			if heightmap != null:
				tex_coords = (pos_terrain * texture_heightmap_scale).floor()
				color = heightmap.get_pixelv(tex_coords)
			sampled_points.append(Vector3(pos.x, color.r, pos.y))
	densitymap.unlock()
	if heightmap != null:
		heightmap.unlock()
	return sampled_points


func _get_density_texture():
	var it = ImageTexture.new()
	it.create_from_image(densitymap)
	return it


func _generate_subset(_userdata):
	var rng = RandomNumberGenerator.new()

	var sampled_points = _sample_by_denisty()
	if sampled_points.size() == 0:
		self.visible = false
		return
	else:
		self.visible = true
	self.global_transform.origin = Vector3(chunk_position.x, 0, chunk_position.y)
	#TODO: setup AABB ?
	rng.seed = int(self.global_transform.origin.length())
	if sampled_points.size() > self.multimesh.instance_count:
		self.multimesh.instance_count = sampled_points.size()
	self.multimesh.visible_instance_count = sampled_points.size()
	for i in range(sampled_points.size()):
		var pos2: Vector2 = (
			Vector2(sampled_points[i].x, sampled_points[i].z)
			/ (stamp_size / chunk_size)
		)
		var position = Vector3(pos2.x, sampled_points[i].y, pos2.y)
		var rand_hash = rng.randf_range(0.0, 1.0)
		var rand_scale3 = (
			Vector3(rand_hash, rand_hash, rand_hash)
			* object_scale_variation
			* object_scale
		)
		var rand_rotation = rand_hash * object_rotation_variation
		var tb = Basis()
		tb = tb.scaled(Vector3(object_scale + rand_scale3))
		tb = tb.rotated(Vector3.UP, rand_rotation)
		var t = Transform(tb)
		t.origin = position
		self.multimesh.set_instance_transform(i, t)


func _ready():
	self.visible = false
	self.multimesh = MultiMesh.new()
	self.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	self.multimesh.color_format = MultiMesh.COLOR_NONE
	self.multimesh.custom_data_format = MultiMesh.CUSTOM_DATA_NONE
	self.multimesh.instance_count = maximum_instance_count
	self.multimesh.visible_instance_count = 0
	self.multimesh.mesh = mesh
	if enable_shadows:
		self.cast_shadow = SHADOW_CASTING_SETTING_ON
	else:
		self.cast_shadow = SHADOW_CASTING_SETTING_OFF
	for i in range(self.multimesh.instance_count):
		var t = Transform(Basis(), Vector3(0, 0, 0))
		self.multimesh.set_instance_transform(i, t)
	_generate_subset(null)


func generate():
	_generate_subset(null)
