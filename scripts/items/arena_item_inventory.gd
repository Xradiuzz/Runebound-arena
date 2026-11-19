class_name ArenaItemInventory
extends Node

signal inventory_changed

const MAX_SLOTS := 6

var hero: ArenaActor
var game: Node
var item_ids: Array[String] = []
var cooldowns: Dictionary = {}
var _applied_health_bonus := 0.0
var _applied_mana_bonus := 0.0
var _applied_mana_regen_bonus := 0.0
var _applied_attack_damage_bonus := 0.0
var _applied_armor_bonus := 0.0
var _applied_attack_speed_bonus := 0.0
var _applied_move_speed_bonus := 0.0
var _applied_spell_power_bonus := 0.0
var _applied_lifesteal_bonus := 0.0
var _applied_on_hit_slow_bonus := 0.0


func _ready() -> void:
    hero = get_parent() as ArenaActor
    if hero == null:
        set_process(false)
        push_error("ArenaItemInventory must be a child of ArenaActor.")
        return
    game = hero.game
    _recalculate_stats()
    inventory_changed.emit()


func _process(delta: float) -> void:
    for item_id in cooldowns.keys():
        cooldowns[item_id] = maxf(0.0, float(cooldowns[item_id]) - delta)
    if not is_instance_valid(hero) or not hero.alive:
        return
    for index in range(MAX_SLOTS):
        var action := "item_%d" % (index + 1)
        if InputMap.has_action(action) and Input.is_action_just_pressed(action):
            if is_instance_valid(game) and bool(game.get("shop_sell_mode")):
                sell_slot(index)
            else:
                activate_slot(index)


func get_item_count() -> int:
    return item_ids.size()


func get_item_at(index: int) -> Dictionary:
    if index < 0 or index >= item_ids.size():
        return {}
    return ArenaItemCatalog.get_item(item_ids[index])


func get_slot_cooldown(index: int) -> float:
    var item := get_item_at(index)
    if item.is_empty():
        return 0.0
    return float(cooldowns.get(str(item.get("id", "")), 0.0))


func get_purchase_error(item_id: String) -> String:
    var item := ArenaItemCatalog.get_item(item_id)
    if item.is_empty():
        return "Unknown item."
    if item_ids.has(item_id):
        return "This item is already equipped."
    if not is_instance_valid(game):
        return "Match economy is unavailable."
    if bool(game.get("game_over")):
        return "The match has ended."

    var recipe: Array = item.get("recipe", [])
    if recipe.is_empty():
        if item_ids.size() >= MAX_SLOTS:
            return "Inventory is full."
    else:
        for component_id in recipe:
            if not item_ids.has(str(component_id)):
                var component: Dictionary = ArenaItemCatalog.get_item(str(component_id))
                return "Requires %s." % str(component.get("name", component_id))
        if item_ids.size() - recipe.size() + 1 > MAX_SLOTS:
            return "Not enough inventory space."

    if int(game.get("player_gold")) < int(item.get("price", 0)):
        return "Not enough gold for the purchase or combine fee."
    return ""


func can_purchase(item_id: String) -> bool:
    return get_purchase_error(item_id).is_empty()


func buy_item(item_id: String) -> bool:
    var error_message := get_purchase_error(item_id)
    if not error_message.is_empty():
        _show_message(error_message)
        return false
    var item := ArenaItemCatalog.get_item(item_id)
    var price := int(item.get("price", 0))
    var recipe: Array = item.get("recipe", [])
    game.set("player_gold", int(game.get("player_gold")) - price)
    for component_id in recipe:
        item_ids.erase(str(component_id))
    item_ids.append(item_id)
    _recalculate_stats()
    inventory_changed.emit()
    var action := "Combined" if not recipe.is_empty() else "Purchased"
    _show_message("%s %s" % [action, str(item.get("name", item_id))])
    return true


func sell_slot(index: int) -> bool:
    if not is_instance_valid(hero) or not hero.alive:
        return false
    if not is_instance_valid(game) or bool(game.get("game_over")):
        return false
    if index < 0 or index >= item_ids.size():
        return false

    var item_id := item_ids[index]
    var item := ArenaItemCatalog.get_item(item_id)
    if item.is_empty():
        return false
    var total_value := int(item.get("total_value", item.get("price", 0)))
    var refund := int(floor(float(total_value) * 0.60))
    item_ids.remove_at(index)
    cooldowns.erase(item_id)
    game.set("player_gold", int(game.get("player_gold")) + refund)
    _recalculate_stats()
    inventory_changed.emit()
    _show_message("Sold %s for %d gold" % [str(item.get("name", item_id)), refund])
    return true


func activate_slot(index: int) -> bool:
    if not is_instance_valid(hero) or not hero.alive:
        return false
    if is_instance_valid(game) and bool(game.get("game_over")):
        return false

    var item := get_item_at(index)
    if item.is_empty():
        return false
    var item_id := str(item.get("id", ""))
    var active := str(item.get("active", ""))
    if active.is_empty():
        _show_message("%s is a passive item." % str(item.get("name", "Item")))
        return false

    var remaining := float(cooldowns.get(item_id, 0.0))
    if remaining > 0.0:
        _show_message("%s ready in %.1fs" % [str(item.get("name", "Item")), remaining])
        return false

    var success := false
    match active:
        "blink":
            success = _activate_blink()
        "phoenix":
            success = _activate_phoenix()
    if success:
        cooldowns[item_id] = float(item.get("cooldown", 0.0))
        inventory_changed.emit()
    return success


func _activate_blink() -> bool:
    var target := _find_nearest_enemy(17.0)
    var destination := hero.global_position
    if target != null:
        var direction := target.global_position - hero.global_position
        direction.y = 0.0
        if direction.length_squared() > 0.001:
            destination = target.global_position - direction.normalized() * 2.6
    else:
        var forward := -hero.global_transform.basis.z
        forward.y = 0.0
        if forward.length_squared() < 0.001:
            forward = Vector3.FORWARD
        destination += forward.normalized() * 6.0

    destination.x = clampf(destination.x, -18.0, 18.0)
    destination.z = clampf(destination.z, -12.5, 12.5)
    hero.global_position = destination
    hero.velocity = Vector3.ZERO
    _spawn_pulse(destination, Color("#70E8FF"), 2.8)
    _show_message("Blink Rune activated")
    return true


func _activate_phoenix() -> bool:
    var restored := minf(220.0, hero.max_hp - hero.hp)
    hero.hp = minf(hero.max_hp, hero.hp + 220.0)
    hero.grant_shield(110.0, 4.0)
    hero.health_changed.emit(hero.hp, hero.max_hp)
    hero.call("_update_health_bar")
    _spawn_pulse(hero.global_position, Color("#FFB56A"), 3.2)
    _show_message("Phoenix Core • restored %d health and gained a shield" % int(restored))
    return true


func _find_nearest_enemy(search_range: float) -> ArenaActor:
    var chosen: ArenaActor
    var best_distance := search_range
    for node in get_tree().get_nodes_in_group("arena_actors"):
        if not (node is ArenaActor):
            continue
        var candidate := node as ArenaActor
        if candidate == hero or candidate.team == hero.team or not candidate.alive:
            continue
        var distance := hero.global_position.distance_to(candidate.global_position)
        if distance < best_distance:
            best_distance = distance
            chosen = candidate
    return chosen


func _recalculate_stats() -> void:
    if not is_instance_valid(hero):
        return

    var totals := {
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
    for item_id in item_ids:
        var item := ArenaItemCatalog.get_item(item_id)
        var stats: Dictionary = item.get("stats", {})
        for stat_name in totals.keys():
            totals[stat_name] = float(totals[stat_name]) + float(stats.get(stat_name, 0.0))

    hero.bonus_attack_damage += float(totals["damage"]) - _applied_attack_damage_bonus
    hero.bonus_armor += float(totals["armor"]) - _applied_armor_bonus
    hero.bonus_attack_speed += float(totals["attack_speed"]) - _applied_attack_speed_bonus
    hero.bonus_move_speed += float(totals["move_speed"]) - _applied_move_speed_bonus
    hero.bonus_spell_power += float(totals["spell_power"]) - _applied_spell_power_bonus
    hero.bonus_lifesteal += float(totals["lifesteal"]) - _applied_lifesteal_bonus
    hero.bonus_on_hit_slow += float(totals["on_hit_slow"]) - _applied_on_hit_slow_bonus

    _applied_attack_damage_bonus = float(totals["damage"])
    _applied_armor_bonus = float(totals["armor"])
    _applied_attack_speed_bonus = float(totals["attack_speed"])
    _applied_move_speed_bonus = float(totals["move_speed"])
    _applied_spell_power_bonus = float(totals["spell_power"])
    _applied_lifesteal_bonus = float(totals["lifesteal"])
    _applied_on_hit_slow_bonus = float(totals["on_hit_slow"])

    var health_delta := float(totals["max_health"]) - _applied_health_bonus
    hero.max_hp = maxf(1.0, hero.max_hp + health_delta)
    if health_delta > 0.0:
        hero.hp = minf(hero.max_hp, hero.hp + health_delta)
    else:
        hero.hp = minf(hero.hp, hero.max_hp)
    hero.health_changed.emit(hero.hp, hero.max_hp)
    hero.call("_update_health_bar")
    _applied_health_bonus = float(totals["max_health"])

    var ability_controller := _find_ability_controller()
    if ability_controller != null:
        var mana_delta := float(totals["mana"]) - _applied_mana_bonus
        var new_max_mana := maxf(0.0, float(ability_controller.get("max_mana")) + mana_delta)
        ability_controller.set("max_mana", new_max_mana)
        ability_controller.set(
            "mana",
            minf(new_max_mana, float(ability_controller.get("mana")) + maxf(0.0, mana_delta))
        )
        var regen_delta := float(totals["mana_regen"]) - _applied_mana_regen_bonus
        ability_controller.set(
            "mana_regen",
            maxf(0.0, float(ability_controller.get("mana_regen")) + regen_delta)
        )

    _applied_mana_bonus = float(totals["mana"])
    _applied_mana_regen_bonus = float(totals["mana_regen"])


func _find_ability_controller() -> Node:
    for child in hero.get_children():
        if child.has_method("get_rank") and child.has_method("cast"):
            return child
    return null


func _spawn_pulse(position: Vector3, color: Color, radius: float) -> void:
    if not is_instance_valid(game):
        return
    var ring := MeshInstance3D.new()
    var mesh := TorusMesh.new()
    mesh.inner_radius = 0.82
    mesh.outer_radius = 1.0
    ring.mesh = mesh
    ring.rotation_degrees.x = 90.0
    ring.position = position + Vector3(0.0, 0.14, 0.0)
    ring.scale = Vector3(0.25, 1.0, 0.25)

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(color.r, color.g, color.b, 0.88)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = 1.7
    ring.material_override = material
    game.add_child(ring)

    var tween := create_tween()
    tween.tween_property(ring, "scale", Vector3(radius, 1.0, radius), 0.42)
    tween.parallel().tween_property(
        material,
        "albedo_color",
        Color(color.r, color.g, color.b, 0.0),
        0.42
    )
    tween.tween_callback(ring.queue_free)


func _show_message(message: String) -> void:
    if not is_instance_valid(game):
        return
    var label = game.get("message_label")
    if label is Label:
        label.text = message
