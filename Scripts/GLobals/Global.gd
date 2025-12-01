extends Node

var PlayerNode: Node = null ### Player Node 

var inventory: Array = []
var inventory_size: int = 10

signal updateinventory 
signal clickedinteractibles

@onready var Inventory_Slot_Scene = preload("res://Scenes/GUI/Inventory/inventory_slot.tscn")

var LastSelectedItem = null 

var is_lunari: bool = false

var SelectedLanguage: String
###########################
#GOON SPAWN STUFF

var npc_scene = load("res://Scenes/Modules/npc.tscn")
var npc_texture: Array[CompressedTexture2D]
var npc_spawn_rect := Rect2(Vector2.ZERO, Vector2(480,0))
var npc_min_distance: int = 24

### SUS Stuff
signal changed_shape
var Sussynes: int = 0 


var current_shape: String = "test"

var can_enter_next_room: bool = false
func _ready() -> void:
	
	AppendNPCStufF()
	inventory.resize(inventory_size)
	
	

func _process(delta: float) -> void:
	checklanguage()
	
	if current_shape == "Lunari": 
		is_lunari = true
	else: 
		is_lunari = false
	
func checklanguage(): 
	var local = TranslationServer.get_locale()
	SelectedLanguage = local.to_lower()
	
func additem(item):
	
	for i in range(inventory.size()):
		
		if inventory[i] != null and inventory[i]["name_de"] == item["name_de"]:
			#inventory[i]["quantity"] += item["quantity"] 
			emit_signal("updateinventory")
			return true 
			
		elif inventory[i] == null: 
			inventory[i] = item
			emit_signal("updateinventory")
			return true
			
		#else: 
			#inventory[i] = item
			#print("ELSE ", inventory)
	return false
		

func removeitem(item): 
	
	
	for i in range(inventory.size()):
		
		if inventory[i] != null and inventory[i]["name_de"] == item:
			print("Remove Item ", item )
			inventory[i] = null
			updateinventory.emit()
			return true
			
	return false
		
func change_current_shape_string(shape: String): 
	current_shape = shape

func player_reference(player): 
	PlayerNode = player
	
	
func swap_inventory(index_1, index_2):
	
	if index_1 < 0 or index_1 > inventory.size() or index_2 < 0 or index_2 > inventory.size():
		return false
		
	var temp = inventory[index_1]
	inventory[index_1] = inventory[index_2]
	inventory[index_2] = temp
	updateinventory.emit()
	return true

#Update last Selected Item
func change_selecteditem(selected_item):
	
	LastSelectedItem = selected_item
	print("Selected Item ", LastSelectedItem)


func AppendNPCStufF(): 

	var placeholder2 = preload("res://Assets/Placeholders/Placeholder Goons/Katsoro_Sprite.png")
	npc_texture.append(placeholder2)
	var placeholder3 = preload("res://Assets/Placeholders/Placeholder Goons/Yuji-Sprite.png")
	npc_texture.append(placeholder3)

func GetValidSpawnPositions(existing: Array[Vector2]) -> Vector2: 
	var tries := 0
	while tries < 10000: 
		var placeholder_pos_y = 165
		var valid_pos := Vector2(randf_range(npc_spawn_rect.position.x, npc_spawn_rect.position.x + npc_spawn_rect.size.x), placeholder_pos_y)  
		
		var pos_ok := true
		for e in existing: 
			if e.distance_to(valid_pos) < npc_min_distance:
				pos_ok = false 
				break
				
		if pos_ok: 
			return valid_pos
		tries += 1
	return npc_spawn_rect.position
		
func SpawnNPCs(): 
	print("Spawning NPCs")
	randomize()
	var spawn_positions: Array[Vector2] = []
	
	for i in 3: 
		
		var position = GetValidSpawnPositions(spawn_positions)
		spawn_positions.append(position) 
		
		var npc = npc_scene.instantiate() 
		npc.position = position 
		npc.get_node("NPC Texture").texture  = npc_texture.pick_random()
		add_child(npc)
		print("Spawned NPC, location: ", position)

func Add_Sus(sus_to_add): 
	var max_sus = 100 
	
	var temp = Sussynes + sus_to_add
	
	if temp >= max_sus: 
		print("Please piss off ", max_sus)
		Sussynes = max_sus
		
	else: 
		Sussynes += sus_to_add

func Remove_Sus(sus_to_remove): 
	var min_sus = 0 
	var temp = Sussynes - sus_to_remove
	
	
	if temp <= min_sus: 
		Sussynes = min_sus
	else:
		Sussynes -= sus_to_remove
	
