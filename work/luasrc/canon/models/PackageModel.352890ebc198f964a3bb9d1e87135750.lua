require "hecore.class"

PackageModel = class()

CARDSHOWTYPE = {
	all="allCard",
	wei="wei",
	shu="shu",
	wu="wu",
	qun="qun"
}

EQUIPSHOWTYPE = {
	all="allEquip",
	weapon="weapon",
	armor="armor",
	horse="horse"
}

ILLUSTRATECONFIG = {
	WIDTH = 640,
	HEIGHT = 675,
	VIEW_INIT_POSX = 36,
	VIEW_INIT_POSY = 955
}

BAGCATEGORY = {
	card=1,
	equip=2,
	item=3,
	spirit=4,
	treasure = 5,
}

BAGCONFIG = {
	WIDTH = 720,
	HEIGHT = 870,
    CARD_WIDTH = 171,
    CARD_HEIGHT = 228,
    EQUIP_WIDTH = 128,
    EQUIP_HEIGHT = 130,    
    ITEM_WIDTH = 128,
    ITEM_HEIGHT = 130,        
}

BACKPACK_FILTER = table.const{
    ALL   = {"btn_inventory_inactive_quip","btn_inventory_inactive_prov","btn_inventor_active_card"},
    CARD  = {"btn_inventor_active_card"},
    ITEM  = {"btn_inventory_inactive_prov"},
    EQUIP = {"btn_inventory_inactive_quip"},
    NONE  = {},
}
