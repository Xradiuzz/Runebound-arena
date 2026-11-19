class_name ArenaAbilityDefinition
extends Resource

@export var id: StringName
@export var slot: StringName
@export var display_name: String
@export_multiline var description: String

@export var unlock_level: int = 1
@export var max_rank: int = 4
@export var mana_cost: PackedFloat32Array = PackedFloat32Array()
@export var cooldown: PackedFloat32Array = PackedFloat32Array()
@export var damage: PackedFloat32Array = PackedFloat32Array()
@export var duration: PackedFloat32Array = PackedFloat32Array()
@export var magnitude: PackedFloat32Array = PackedFloat32Array()

@export var cast_range: float = 0.0
@export var radius: float = 0.0


func value(values: PackedFloat32Array, rank: int, fallback: float = 0.0) -> float:
    if values.is_empty():
        return fallback

    var index := clampi(rank - 1, 0, values.size() - 1)
    return values[index]
