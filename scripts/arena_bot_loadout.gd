extends Node
class_name ArenaBotLoadout

# Autonomous six-slot economy for AI heroes. Bot gold is personal and is fed by
# passive income plus a share of team takedowns; the player's wallet is untouched.

const MAX_SLOTS := 6
const INCOME_PER_SECOND := 1.25
const PURCHASE_INTERVAL := 2.5

var hero: ArenaActor
var game: Node
var gold := 350.0
var item_ids: Array[String] = []
var cooldowns: Dictionary = {}
var _income_timer := 0.0
var _purchase_timer := 0.0
var _active_timer := 0.0
var _applied_stats: Dictionary = {}


func _ready() -> void:
    hero = get_parent() as ArenaActor
    if hero == null:
        set_process(false)
        push_error("ArenaBotLoadout must be a child of ArenaActor.")
        return
    game = hero.game
    _applied_stats = _empty_stats()


func _process(delta: float) -> void:
    if not is_instance_valid(hero):
        return

    _income_timer += delta
    while _income_timer >= 1.0:
        _income_timer -= 1.0
        gold += INCOME_PER_SECOND

    for item_id in cooldowns.keys():
        cooldowns[item_id] = maxf(0.0, float(cooldowns[item_id]) - delta)

    _purchase_timer += delta
    if _purchase_timer >= PURCHASE_INTERVAL:
        _purchase_timer = 0.0
        _try_purchase_best_item()

    _active_timer += delta
    if _active_timer >= 0.35:
        _active_timer = 0.0
        _try_use_active_items()


func add_gold(amount: int) -> void:
    if amount > 0:
        gold += float(amount)


func get_gold() -> int:
    return int(floor(gold))


func get_item_names() -> PackedStringArray:
    var names := PackedStringArray()
    for item_id in item_ids:
        var item := ArenaItemCatalog.get_item(item_id)
        names.append(str(item.get("short_name", item_id)))
    return names


func _get_purchase_priority() -> Array[String]:
    match hero.team_role:
        "support":
            return ["ironleaf_vest", "aether_lens", "swiftwind_boots", "phoenix_core", "guardian_sigil", "aegis_of_dawn"]
        "roamer":
            return ["swiftwind_boots", "ember_edge", "frostbrand", "blink_rune", "bloodfang", "runebound_edge"]
        "offlane":
            return ["ironleaf_vest", "guardian_sigil", "swiftwind_boots", "aegis_of_dawn", "frostbrand", "phoenix_core"]
        "mid":
            return ["aether_lens", "swiftwind_boots", "ember_edge", "tempest_core", "runebound_edge", "blink_rune"]
        "carry":
            return ["ember_edge", "swiftwind_boots", "bloodfang", "frostbrand", "runebound_edge", "blink_rune"]
    return ["ironleaf_vest", "swiftwind_boots", "ember_edge"]


func _try_purchase_best_item() -> void:
    if not hero.alive or (is_instance_valid(game) and bool(game.get("game_over"))):
        return
    for item_id in _get_purchase_priority():
        if item_ids.has(item_id):
            continue
        var item := ArenaItemCatalog.get_item(item_id)
        if item.is_empty() or gold < float(item.get("price", 0)):
            continue

        var recipe: Array = item.get("recipe", [])
        if recipe.is_empty():
            if item_ids.size() >= MAX_SLOTS:
                continue
        else:
            var can_combine := true
            for component_id in recipe:
                if not item_ids.has(str(component_id)):
                    can_combine = false
                    break
            if not can_combine or item_ids.size() - recipe.size() + 1 > MAX_SLOTS:
                continue

        gold -= float(item.get("price", 0))
        for component_id in recipe:
            item_ids.erase(str(component_id))
        item_ids.append(item_id)
        _recalculate_stats()
        return


func _empty_stats() -> Dictionary:
    return {
        "damage": 0.0,
        "max_health": 0.0,
        "armor": 0.0,
        "attack_speed": 0.0,
        "move_speed": 0.0,
        "spell_power": 0.0,
        "lifesteal": 0.0,
        "on_hit_slow": 0.0,
        "mana": 0.0,
        "mana_regen": 0.0
    }


func _recalculate_stats() -> void:
    var totals := _empty_stats()
    for item_id in item_ids:
        var item := ArenaItemCatalog.get_item(item_id)
        var stats: Dictionary = item.get("stats", {})
        for stat_name in totals.keys():
            totals[stat_name] = float(totals[stat_name]) + float(stats.get(stat_name, 0.0))

    hero.bonus_attack_damage += float(totals["damage"]) - float(_applied_stats["damage"])
    hero.bonus_armor += float(totals["armor"]) - float(_applied_stats["armor"])
    hero.bonus_attack_speed += float(totals["attack_speed"]) - float(_applied_stats["attack_speed"])
    hero.bonus_move_speed += float(totals["move_speed"]) - float(_applied_stats["move_speed"])
    hero.bonus_spell_power += float(totals["spell_power"]) - float(_applied_stats["spell_power"])
    hero.bonus_lifesteal += float(totals["lifesteal"]) - float(_applied_stats["lifesteal"])
    hero.bonus_on_hit_slow += float(totals["on_hit_slow"]) - float(_applied_stats["on_hit_slow"])

    var health_delta := float(totals["max_health"]) - float(_applied_stats["max_health"])
    hero.max_hp = maxf(1.0, hero.max_hp + health_delta)
    hero.hp = minf(hero.max_hp, hero.hp + maxf(0.0, health_delta))
    hero.health_changed.emit(hero.hp, hero.max_hp)
    hero.call("_update_health_bar")

    var ability_controller := _find_ability_controller()
    if is_instance_valid(ability_controller):
        var mana_delta := float(totals["mana"]) - float(_applied_stats["mana"])
        var max_mana := maxf(0.0, float(ability_controller.get("max_mana")) + mana_delta)
        ability_controller.set("max_mana", max_mana)
        ability_controller.set("mana", minf(max_mana, float(ability_controller.get("mana")) + maxf(0.0, mana_delta)))
        var regen_delta := float(totals["mana_regen"]) - float(_applied_stats["mana_regen"])
        ability_controller.set("mana_regen", maxf(0.0, float(ability_controller.get("mana_regen")) + regen_delta))

    _applied_stats = totals


func _find_ability_controller() -> Node:
    var warden_kit := hero.get_node_or_null("WardenAbilities")
    if is_instance_valid(warden_kit):
        return warden_kit
    return hero.get_node_or_null("ArenaHeroKit")


func _try_use_active_items() -> void:
    if not hero.alive:
        return

    if item_ids.has("phoenix_core") and float(cooldowns.get("phoenix_core", 0.0)) <= 0.0:
        if hero.hp / maxf(1.0, hero.max_hp) <= 0.42:
            hero.hp = minf(hero.max_hp, hero.hp + 220.0)
            hero.grant_shield(110.0, 4.0)
            hero.health_changed.emit(hero.hp, hero.max_hp)
            hero.call("_update_health_bar")
            cooldowns["phoenix_core"] = 60.0
            _spawn_item_pulse(Color("#FFB56A"))
            return

    if not item_ids.has("blink_rune") or float(cooldowns.get("blink_rune", 0.0)) > 0.0:
        return
    if not is_instance_valid(hero.target) or not hero._valid_target():
        return
    var distance := hero.global_position.distance_to(hero.target.global_position)
    if distance < 5.5 or distance > 13.0:
        return
    var direction := hero.target.global_position - hero.global_position
    direction.y = 0.0
    if direction.length_squared() < 0.001:
        return
    var destination := hero.target.global_position - direction.normalized() * 2.8
    destination.x = clampf(destination.x, -18.0, 18.0)
    destination.z = clampf(destination.z, -12.5, 12.5)
    hero.global_position = destination
    hero.velocity = Vector3.ZERO
    cooldowns["blink_rune"] = 32.0
    _spawn_item_pulse(Color("#70E8FF"))


func _spawn_item_pulse(color: Color) -> void:
    if not is_instance_valid(game):
        return
    var ring := MeshInstance3D.new()
    var mesh := TorusMesh.new()
    mesh.inner_radius = 0.82
    mesh.outer_radius = 1.0
    ring.mesh = mesh
    ring.rotation_degrees.x = 90.0
    ring.position = hero.global_position + Vector3(0.0, 0.16, 0.0)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(color.r, color.g, color.b, 0.82)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = 1.6
    ring.material_override = material
    game.add_child(ring)
    var tween := create_tween()
    tween.tween_property(ring, "scale", Vector3(2.8, 1.0, 2.8), 0.35)
    tween.parallel().tween_property(material, "albedo_color", Color(color.r, color.g, color.b, 0.0), 0.35)
    tween.tween_callback(ring.queue_free)
