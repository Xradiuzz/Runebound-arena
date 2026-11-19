class_name HeroAbilityKitCatalog
extends RefCounted


static func build(hero_id: String) -> Dictionary:
    match hero_id:
        "nyxara":
            return _build_nyxara()
        "grom":
            return _build_grom()
        "elyra":
            return _build_elyra()
        "vaelis":
            return _build_vaelis()
        _:
            return {}


static func _build_nyxara() -> Dictionary:
    return {
        "Q": _make(
            &"rift_step", &"Q", "Rift Step",
            "Blink toward a nearby enemy and cut through the veil.",
            1, 4,
            [65.0, 70.0, 75.0, 80.0],
            [11.0, 10.0, 9.0, 8.0],
            [90.0, 130.0, 170.0, 210.0],
            [0.7, 0.8, 0.9, 1.0],
            [6.0, 6.5, 7.0, 7.5],
            10.0, 0.0
        ),
        "W": _make(
            &"astral_snare", &"W", "Astral Snare",
            "Bind the nearest enemy in a rune of starlight.",
            1, 4,
            [75.0, 85.0, 95.0, 105.0],
            [15.0, 14.0, 13.0, 12.0],
            [45.0, 70.0, 95.0, 120.0],
            [1.25, 1.45, 1.65, 1.85],
            [],
            9.0, 0.0
        ),
        "E": _make(
            &"starfall", &"E", "Starfall",
            "Detonate a star shard around a nearby enemy, slowing the area.",
            1, 4,
            [95.0, 105.0, 115.0, 125.0],
            [14.0, 13.0, 12.0, 11.0],
            [85.0, 125.0, 165.0, 205.0],
            [1.6, 1.8, 2.0, 2.2],
            [0.25, 0.30, 0.35, 0.40],
            11.0, 4.2
        ),
        "R": _make(
            &"void_eclipse", &"R", "Void Eclipse",
            "Collapse a void field around Nyxara, damaging and stunning enemies.",
            6, 3,
            [160.0, 185.0, 210.0],
            [115.0, 100.0, 85.0],
            [190.0, 280.0, 370.0],
            [0.9, 1.15, 1.4],
            [],
            0.0, 7.2
        )
    }


static func _build_grom() -> Dictionary:
    return {
        "Q": _make(
            &"savage_leap", &"Q", "Savage Leap",
            "Leap into an enemy, dealing heavy damage and briefly stunning it.",
            1, 4,
            [55.0, 60.0, 65.0, 70.0],
            [10.0, 9.0, 8.0, 7.0],
            [100.0, 145.0, 190.0, 235.0],
            [0.65, 0.75, 0.85, 0.95],
            [6.5, 7.0, 7.5, 8.0],
            9.0, 0.0
        ),
        "W": _make(
            &"blood_howl", &"W", "Blood Howl",
            "Restore health and gain a short-lived blood shield.",
            1, 4,
            [80.0, 90.0, 100.0, 110.0],
            [18.0, 17.0, 16.0, 15.0],
            [55.0, 75.0, 95.0, 115.0],
            [4.0, 4.5, 5.0, 5.5],
            [0.14, 0.17, 0.20, 0.23],
            0.0, 0.0
        ),
        "E": _make(
            &"cleaving_arc", &"E", "Cleaving Arc",
            "Sweep in a wide arc, wounding enemies with a bleeding cut.",
            1, 4,
            [70.0, 80.0, 90.0, 100.0],
            [13.0, 12.0, 11.0, 10.0],
            [90.0, 130.0, 170.0, 210.0],
            [3.0, 3.2, 3.4, 3.6],
            [10.0, 14.0, 18.0, 22.0],
            0.0, 4.8
        ),
        "R": _make(
            &"warpath", &"R", "Warpath",
            "Enter a berserker frenzy, increasing attack damage and movement speed.",
            6, 3,
            [140.0, 165.0, 190.0],
            [105.0, 90.0, 75.0],
            [],
            [6.0, 7.0, 8.0],
            [0.25, 0.35, 0.45],
            0.0, 0.0
        )
    }


static func _build_elyra() -> Dictionary:
    return {
        "Q": _make(
            &"mending_ray", &"Q", "Mending Ray",
            "Heal and shield the most wounded nearby ally.",
            1, 4,
            [55.0, 60.0, 65.0, 70.0],
            [9.0, 8.5, 8.0, 7.5],
            [0.0, 0.0, 0.0, 0.0],
            [3.0, 3.2, 3.4, 3.6],
            [95.0, 125.0, 155.0, 185.0],
            9.0, 0.0
        ),
        "W": _make(
            &"sanctuary", &"W", "Sanctuary",
            "Restore health to nearby allies and grant a brief shield.",
            1, 4,
            [85.0, 95.0, 105.0, 115.0],
            [17.0, 16.0, 15.0, 14.0],
            [0.0, 0.0, 0.0, 0.0],
            [3.5, 3.8, 4.1, 4.4],
            [65.0, 90.0, 115.0, 140.0],
            0.0, 6.0
        ),
        "E": _make(
            &"binding_light", &"E", "Binding Light",
            "Root enemies around the nearest hostile target.",
            1, 4,
            [70.0, 80.0, 90.0, 100.0],
            [13.0, 12.0, 11.0, 10.0],
            [55.0, 80.0, 105.0, 130.0],
            [1.0, 1.2, 1.4, 1.6],
            [0.0, 0.0, 0.0, 0.0],
            9.0, 4.4
        ),
        "R": _make(
            &"dawn_chorus", &"R", "Dawn Chorus",
            "Send a restorative pulse through the entire allied team.",
            6, 3,
            [155.0, 180.0, 205.0],
            [110.0, 95.0, 80.0],
            [0.0, 0.0, 0.0],
            [4.0, 4.5, 5.0],
            [180.0, 250.0, 320.0],
            0.0, 0.0
        )
    }


static func _build_vaelis() -> Dictionary:
    return {
        "Q": _make(
            &"shadow_pounce", &"Q", "Shadow Pounce",
            "Blink to a hostile target and strike from the flank.",
            1, 4,
            [60.0, 65.0, 70.0, 75.0],
            [10.0, 9.0, 8.0, 7.0],
            [105.0, 145.0, 185.0, 225.0],
            [0.7, 0.8, 0.9, 1.0],
            [0.18, 0.22, 0.26, 0.30],
            10.0, 0.0
        ),
        "W": _make(
            &"hunters_mark", &"W", "Hunter's Mark",
            "Mark the nearest enemy, slowing and wounding it.",
            1, 4,
            [55.0, 65.0, 75.0, 85.0],
            [12.0, 11.0, 10.0, 9.0],
            [65.0, 95.0, 125.0, 155.0],
            [2.5, 2.8, 3.1, 3.4],
            [0.20, 0.24, 0.28, 0.32],
            12.0, 0.0
        ),
        "E": _make(
            &"gale_cut", &"E", "Gale Cut",
            "Release a circular blade of wind that slows nearby foes.",
            1, 4,
            [75.0, 85.0, 95.0, 105.0],
            [13.0, 12.0, 11.0, 10.0],
            [80.0, 115.0, 150.0, 185.0],
            [1.8, 2.0, 2.2, 2.4],
            [0.22, 0.25, 0.28, 0.31],
            0.0, 4.8
        ),
        "R": _make(
            &"nightfall", &"R", "Nightfall",
            "Assault a marked area, damaging and stunning enemies.",
            6, 3,
            [150.0, 175.0, 200.0],
            [105.0, 90.0, 75.0],
            [175.0, 255.0, 335.0],
            [0.85, 1.0, 1.15],
            [0.0, 0.0, 0.0],
            12.0, 5.8
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
