extends Control

const BOXES := [
    {"name": "Common\nBox", "cost": 5, "rarity": "common", "color": Color(0.7,0.7,0.7)},
    {"name": "Rare\nBox", "cost": 15, "rarity": "rare", "color": Color(0.1,0.4,0.9)},
    {"name": "Epic\nBox", "cost": 30, "rarity": "epic", "color": Color(0.6,0.1,0.9)},
    {"name": "Legendary\nBox", "cost": 60, "rarity": "legendary", "color": Color(1.0,0.6,0.0)},
    {"name": "Mythic\nBox", "cost": 120, "rarity": "mythic", "color": Color(0.9,0.1,0.3)},
    {"name": "Secret\nBox", "cost": 200, "rarity": "secret", "color": Color(0.1,0.9,0.9)},
]

@onready var coins_lbl: Label = $CoinsLabel
@onready var grid: GridContainer = $BoxesGrid

var my_coins: int = 0

func _ready() -> void:
    $BtnClose.pressed.connect(func(): visible = false)
    _build_shop()

func _build_shop() -> void:
    for b in BOXES:
        var btn := Button.new()
        btn.text = "%s\n%d coins" % [b.name, b.cost]
        btn.custom_minimum_size = Vector2(0, 110)
        btn.theme_override_colors["font_color"] = b.color
        btn.theme_override_font_sizes["font_size"] = 18
        btn.pressed.connect(_buy.bind(b))
        grid.add_child(btn)

func open(coins: int) -> void:
    my_coins = coins
    coins_lbl.text = "Your Coins: %d" % my_coins
    visible = true

func _buy(box: Dictionary) -> void:
    if my_coins < box.cost:
        return
    my_coins -= box.cost
    coins_lbl.text = "Your Coins: %d" % my_coins
    AudioManager.play("pickup")
    var popup := AcceptDialog.new()
    popup.title = "Box Opened!"
    popup.dialog_text = "You opened a %s box!\nGot a %s knife skin!" % [
        box.rarity.capitalize(),
        ["worn", "clean", "gilded", "obsidian", "blood-red", "void"][BOXES.find(box)]
    ]
    add_child(popup)
    popup.popup_centered()
