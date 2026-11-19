class_name WardenAbilityCatalog
extends RefCounted


static func build() -> Dictionary:
    return {
        "Q": _make(
            &"runic_charge", &"Q", "Runic Charge",
            "Charge toward an enemy, dealing physical damage and briefly stunning it.",
            1, 4,
            [60.0, 65.0, 70.0, 75.0],
            [10.0, 9.0, 8.0, 7.0],
            [85.0, 130.0, 175.0, 220.0],
            [0.60, 0.70, 0.80, 0.90],
            [7.0, 7.0, 7.0, 7.0],
            9.0, 0.0
        ),
        "W": _make(
            &"aegis_ward", &"W", "Aegis Ward",
            "Surround Warden with a shield that absorbs incoming damage.",
            1, 4,
            [70.0, 80.0, 90.0, 100.0],
            [16.0, 15.0, 14.0, 13.0],
            [],
            [4.0, 4.5, 5.0, 5.5],
            [140.0, 200.0, 260.0, 320.0],
            0.0, 0.0
        ),
        "E": _make(
            &"hammerfall", &"E", "Hammerfall",
            "Strike the ground, damaging and slowing nearby enemy units.",
            1, 4,
            [80.0, 90.0, 100.0, 110.0],
            [14.0, 13.0, 12.0, 11.0],
            [70.0, 110.0, 150.0, 190.0],
            [2.0, 2.2, 2.4, 2.6],
            [0.30, 0.35, 0.40, 0.45],
            0.0, 4.8
        ),
        "R": _make(
            &"chrono_bastion", &"R", "Chrono Bastion",
            "Unleash a temporal pulse that damages and stuns enemies in a large area.",
            6, 3,
            [150.0, 175.0, 200.0],
            [110.0, 95.0, 80.0],
            [180.0, 270.0, 360.0],
            [1.0, 1.3, 1.6],
            [],
            0.0, 7.0
        )
    }


static func _make(
    ability_id: StringName,
    slot: StringName,
    display_name: String,
    description: String,
    unlock_level: int,
    max_rank: int,
    mana: Array,
    cooldowns: Array,
    damages: Array,
    durations: Array,
    magnitudes: Array,
    cast_range: float,
    radius: float
) -> ArenaAbilityDefinition:
    var definition := ArenaAbilityDefinition.new()
    definition.id = ability_id
    definition.slot = slot
    definition.display_name = display_name
    definition.description = description
    definition.unlock_level = unlock_level
    definition.max_rank = max_rank
    definition.mana_cost = PackedFloat32Array(mana)
    definition.cooldown = PackedFloat32Array(cooldowns)
    definition.damage = PackedFloat32Array(damages)
    definition.duration = PackedFloat32Array(durations)
    definition.magnitude = PackedFloat32Array(magnitudes)
    definition.cast_range = cast_range
    definition.radius = radius
    return definition
