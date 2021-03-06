tool
extends 'res://addons/biomes/nodes/BiomeNode.gd'

const BiomeZylannTexture = preload("res://addons/biomes/scripts/BiomeZylannTextureResource.gd")


func _ready():
	set_slot(0, false, 0, Color(0, 0, 0), true, 3, Color(0, 0, 1))


func generate_resource(_output_slot: int):
	var bz = BiomeZylannTexture.new()
	match $'VBoxContainer/HBoxContainer/TypeOptionButton'.selected:
		0:
			bz.type = bz.TEXTURE_TYPE.HEIGHT
		1:
			bz.type = bz.TEXTURE_TYPE.NORMAL
		2:
			bz.type = bz.TEXTURE_TYPE.DETAIL
		3:
			bz.type = bz.TEXTURE_TYPE.ALBEDO
		4:
			bz.type = bz.TEXTURE_TYPE.COLOR
		5:
			bz.type = bz.TEXTURE_TYPE.SPLAT
	bz.layer = $'VBoxContainer/HBoxContainer2/LayerSpinBox'.value
	return bz
