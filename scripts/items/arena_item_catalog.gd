class_name ArenaItemCatalog
extends RefCounted


static func all_items() -> Array[Dictionary]:
    var items: Array[Dictionary] = []
    items.append({"id": "ironleaf_vest", "name": "Ironleaf Vest", "short_name": "VEST", "price": 350, "description": "+120 health • +8 armor", "stats": {"max_health": 120.0, "armor": 8.0}, "active": "", "cooldown": 0.0})
    items.append({"id": "ember_edge", "name": "Ember Edge", "short_name": "EMBER", "price": 450, "description": "+22 attack damage • +10% attack speed", "stats": {"damage": 22.0, "attack_speed": 0.10}, "active": "", "cooldown": 0.0})
    items.append({"id": "swiftwind_boots", "name": "Swiftwind Boots", "short_name": "BOOTS", "price": 300, "description": "+0.9 movement speed", "stats": {"move_speed": 0.9}, "active": "", "cooldown": 0.0})
    items.append({"id": "aether_lens", "name": "Aether Lens", "short_name": "LENS", "price": 500, "description": "+120 mana • +3 mana regen • +12% spell power", "stats": {"mana": 120.0, "mana_regen": 3.0, "spell_power": 0.12}, "active": "", "cooldown": 0.0})
    items.append({"id": "guardian_sigil", "name": "Guardian Sigil", "short_name": "SIGIL", "price": 650, "description": "+240 health • +14 armor", "stats": {"max_health": 240.0, "armor": 14.0}, "active": "", "cooldown": 0.0})
    items.append({"id": "bloodfang", "name": "Bloodfang", "short_name": "FANG", "price": 700, "description": "+26 attack damage • 12% lifesteal", "stats": {"damage": 26.0, "lifesteal": 0.12}, "active": "", "cooldown": 0.0})
    items.append({"id": "frostbrand", "name": "Frostbrand", "short_name": "FROST", "price": 600, "description": "+16 attack damage • +8% attack speed • attacks slow", "stats": {"damage": 16.0, "attack_speed": 0.08, "on_hit_slow": 0.18}, "active": "", "cooldown": 0.0})
    items.append({"id": "blink_rune", "name": "Blink Rune", "short_name": "BLINK", "price": 550, "description": "Active: blink up to 6 units toward a nearby enemy. 32s cooldown.", "stats": {}, "active": "blink", "cooldown": 32.0})
    items.append({"id": "phoenix_core", "name": "Phoenix Core", "short_name": "PHNX", "price": 750, "description": "+160 health • +8 armor • active heal and shield. 60s cooldown.", "stats": {"max_health": 160.0, "armor": 8.0}, "active": "phoenix", "cooldown": 60.0})

    # Upgrades consume two owned components; price is the combine fee.
    items.append({"id": "runebound_edge", "name": "Runebound Edge", "short_name": "R-EDGE", "price": 380, "total_value": 1530, "recipe": ["ember_edge", "bloodfang"], "description": "Recipe: Ember Edge + Bloodfang + 380 G. +54 damage • +16% attack speed • 12% lifesteal.", "stats": {"damage": 54.0, "attack_speed": 0.16, "lifesteal": 0.12}, "active": "", "cooldown": 0.0})
    items.append({"id": "aegis_of_dawn", "name": "Aegis of Dawn", "short_name": "AEGIS", "price": 450, "total_value": 1450, "recipe": ["ironleaf_vest", "guardian_sigil"], "description": "Recipe: Ironleaf Vest + Guardian Sigil + 450 G. +420 health • +30 armor.", "stats": {"max_health": 420.0, "armor": 30.0}, "active": "", "cooldown": 0.0})
    items.append({"id": "tempest_core", "name": "Tempest Core", "short_name": "TEMPEST", "price": 350, "total_value": 1150, "recipe": ["swiftwind_boots", "aether_lens"], "description": "Recipe: Swiftwind Boots + Aether Lens + 350 G. +1.4 movement • +220 mana • +5 regen • +18% spell power.", "stats": {"move_speed": 1.4, "mana": 220.0, "mana_regen": 5.0, "spell_power": 0.18}, "active": "", "cooldown": 0.0})
    return items


static func get_item(item_id: String) -> Dictionary:
    for item in all_items():
        if str(item.get("id", "")) == item_id:
            return item
    return {}
