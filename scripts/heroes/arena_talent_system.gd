extends Node
class_name ArenaTalentSystem

signal state_changed

const TIER_LEVELS := {1: 5, 2: 10}

var hero: ArenaActor
var game: Node
var hero_abilities: Node
var hero_id := "warden"
var current_level := 1
var chosen_talents: Dictionary = {}
var definitions: Dictionary = {}


func _ready() -> void:
    hero = get_parent() as ArenaActor
    if hero == null:
        set_process(false)
        push_error("ArenaTalentSystem must be a child of ArenaActor.")
        return

    game = hero.game
    hero_id = hero.hero_id
    if is_instance_valid(game):
        hero_abilities = game.get("hero_abilities") as Node
        current_level = int(game.get("player_level"))
    definitions = _build_definitions()
    state_changed.emit()


func _build_definitions() -> Dictionary:
    return {
        "warden": {
            1: [
                {"id": "iron_vow", "name": "Iron Vow", "description": "+180 maximum health", "effect": {"max_hp": 180.0}},
                {"id": "marching_wall", "name": "Marching Wall", "description": "+0.7 movement speed", "effect": {"move_speed": 0.7}}
            ],
            2: [
                {"id": "rune_surge", "name": "Rune Surge", "description": "+12% spell power", "effect": {"spell_power": 0.12}},
                {"id": "unbreakable", "name": "Unbreakable", "description": "+18 armor", "effect": {"armor": 18.0}}
            ]
        },
        "nyxara": {
            1: [
                {"id": "mana_well", "name": "Mana Well", "description": "+120 maximum mana and +2 mana regeneration", "effect": {"max_mana": 120.0, "mana_regen": 2.0}},
                {"id": "astral_focus", "name": "Astral Focus", "description": "+14% spell power", "effect": {"spell_power": 0.14}}
            ],
            2: [
                {"id": "quickstep", "name": "Quickstep", "description": "+1 movement speed", "effect": {"move_speed": 1.0}},
                {"id": "echo_mastery", "name": "Echo Mastery", "description": "+8% spell power and +40 maximum mana", "effect": {"spell_power": 0.08, "max_mana": 40.0}}
            ]
        },
        "grom": {
            1: [
                {"id": "blood_harvest", "name": "Blood Harvest", "description": "+8% lifesteal", "effect": {"lifesteal": 0.08}},
                {"id": "ironhide", "name": "Ironhide", "description": "+170 maximum health", "effect": {"max_hp": 170.0}}
            ],
            2: [
                {"id": "war_drums", "name": "War Drums", "description": "+20% attack speed", "effect": {"attack_speed": 0.20}},
                {"id": "executioner", "name": "Executioner", "description": "+28 attack damage", "effect": {"attack_damage": 28.0}}
            ]
        },
        "elyra": {
            1: [
                {"id": "gentle_dawn", "name": "Gentle Dawn", "description": "+180 maximum health", "effect": {"max_hp": 180.0}},
                {"id": "deep_reserve", "name": "Deep Reserve", "description": "+140 mana and +3 mana regeneration", "effect": {"max_mana": 140.0, "mana_regen": 3.0}}
            ],
            2: [
                {"id": "sanctified_light", "name": "Sanctified Light", "description": "+18% spell power", "effect": {"spell_power": 0.18}},
                {"id": "guardian_wings", "name": "Guardian Wings", "description": "+22 armor and +0.5 movement speed", "effect": {"armor": 22.0, "move_speed": 0.5}}
            ]
        },
        "vaelis": {
            1: [
                {"id": "swift_hunt", "name": "Swift Hunt", "description": "+1.0 movement speed", "effect": {"move_speed": 1.0}},
                {"id": "ambush_training", "name": "Ambush Training", "description": "+24 attack damage", "effect": {"attack_damage": 24.0}}
            ],
            2: [
                {"id": "venom_edge", "name": "Venom Edge", "description": "+12% lifesteal and +12% attack speed", "effect": {"lifesteal": 0.12, "attack_speed": 0.12}},
                {"id": "night_runner", "name": "Night Runner", "description": "+0.8 movement speed and +14 armor", "effect": {"move_speed": 0.8, "armor": 14.0}}
            ]
        }
    }


func set_level(level: int) -> void:
    current_level = maxi(1, level)
    state_changed.emit()


func get_options(tier: int) -> Array:
    var hero_data: Dictionary = definitions.get(hero_id, {})
    return hero_data.get(tier, [])


func get_required_level(tier: int) -> int:
    return int(TIER_LEVELS.get(tier, 999))


func get_selected_id(tier: int) -> String:
    return str(chosen_talents.get(tier, ""))


func get_selected_name(tier: int) -> String:
    var selected_id := get_selected_id(tier)
    if selected_id.is_empty():
        return ""
    for option in get_options(tier):
        if str(option.get("id", "")) == selected_id:
            return str(option.get("name", selected_id))
    return selected_id


func can_choose(tier: int) -> bool:
    if not TIER_LEVELS.has(tier) or chosen_talents.has(tier):
        return false
    if current_level < get_required_level(tier):
        return false
    if is_instance_valid(game) and bool(game.get("game_over")):
        return false
    return true


func choose_talent(tier: int, talent_id: String) -> bool:
    if not can_choose(tier):
        return false

    for option in get_options(tier):
        if str(option.get("id", "")) != talent_id:
            continue
        chosen_talents[tier] = talent_id
        _apply_effect(option.get("effect", {}))
        _show_message("Talent learned: %s" % str(option.get("name", talent_id)))
        state_changed.emit()
        return true

    return false


func _apply_effect(effect: Dictionary) -> void:
    if not is_instance_valid(hero):
        return

    if effect.has("max_hp"):
        var health_bonus := float(effect["max_hp"])
        hero.max_hp += health_bonus
        hero.hp = minf(hero.max_hp, hero.hp + health_bonus)
        hero.health_changed.emit(hero.hp, hero.max_hp)
        hero.call("_update_health_bar")
    if effect.has("attack_damage"):
        hero.bonus_attack_damage += float(effect["attack_damage"])
    if effect.has("armor"):
        hero.bonus_armor += float(effect["armor"])
    if effect.has("attack_speed"):
        hero.bonus_attack_speed += float(effect["attack_speed"])
    if effect.has("move_speed"):
        hero.bonus_move_speed += float(effect["move_speed"])
    if effect.has("spell_power"):
        hero.bonus_spell_power += float(effect["spell_power"])
    if effect.has("lifesteal"):
        hero.bonus_lifesteal += float(effect["lifesteal"])

    if is_instance_valid(hero_abilities):
        if effect.has("max_mana"):
            var mana_bonus := float(effect["max_mana"])
            hero_abilities.set("max_mana", float(hero_abilities.get("max_mana")) + mana_bonus)
            hero_abilities.set("mana", float(hero_abilities.get("mana")) + mana_bonus)
        if effect.has("mana_regen"):
            hero_abilities.set("mana_regen", float(hero_abilities.get("mana_regen")) + float(effect["mana_regen"]))


func _show_message(message: String) -> void:
    if not is_instance_valid(game):
        return
    var label = game.get("message_label")
    if label is Label:
        label.text = message
