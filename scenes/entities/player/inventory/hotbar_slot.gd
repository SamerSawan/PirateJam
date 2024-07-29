extends Panel

@onready var quantity = $CenterContainer/Panel/Label
@onready var item_display = $CenterContainer/Panel/itemDisplay
# This script controls if an item is visible inside of an item slot
var item : InventoryItem
@onready var texture_button = $TextureButton

func update(slot: InventorySlot):
	if !slot.item:
		item_display.visible = false
		quantity.visible = false
		item = null
	else:
		item_display.visible = true
		item_display.texture = slot.item.texture
		quantity.visible = true
		quantity.text = str(slot.quantity)
		item = slot.item
