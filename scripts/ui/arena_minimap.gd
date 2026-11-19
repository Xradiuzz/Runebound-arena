extends Control
class_name ArenaMinimap

const WORLD_MIN_X := -21.0
const WORLD_MAX_X := 21.0
const WORLD_MIN_Z := -15.0
const WORLD_MAX_Z := 15.0
const MAP_MARGIN := 10.0

var game: Node
var refresh_timer := 0.0


func setup(game_node: Node) -> void:
    game = game_node
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size = Vector2(220.0, 184.0)
    queue_redraw()


func _process(delta: float) -> void:
    if not visible:
        return
    refresh_timer += delta
    if refresh_timer >= 0.12:
        refresh_timer = 0.0
        queue_redraw()


func _draw() -> void:
    if not is_instance_valid(game):
        return

    var panel := Rect2(Vector2.ZERO, size)
    draw_rect(panel, Color("#081321", 0.93), true)
    draw_rect(panel, Color("#6D8BA7", 0.9), false, 2.0)

    var map_rect := Rect2(
        Vector2(MAP_MARGIN, MAP_MARGIN + 12.0),
        Vector2(size.x - MAP_MARGIN * 2.0, size.y - MAP_MARGIN * 2.0 - 12.0)
    )
    draw_rect(map_rect, Color("#172B2C", 0.98), true)

    draw_string(
        ThemeDB.fallback_font,
        Vector2(11.0, 14.0),
        "FIELD MAP",
        HORIZONTAL_ALIGNMENT_LEFT,
        -1.0,
        11,
        Color("#D7E7F5")
    )

    _draw_lanes(map_rect)
    _draw_bases(map_rect)
    _draw_structures(map_rect)
    _draw_camps(map_rect)
    _draw_boss_altar(map_rect)
    _draw_actors(map_rect)

    draw_rect(map_rect, Color("#7895A9", 0.75), false, 1.0)


func _draw_lanes(map_rect: Rect2) -> void:
    for lane_x in [-10.0, 0.0, 10.0]:
        var start := _world_to_map(Vector3(lane_x, 0.0, WORLD_MIN_Z), map_rect)
        var finish := _world_to_map(Vector3(lane_x, 0.0, WORLD_MAX_Z), map_rect)
        draw_line(start, finish, Color("#9D9A82", 0.58), 3.0, true)
        draw_line(start, finish, Color("#D2C39A", 0.28), 1.0, true)


func _draw_bases(map_rect: Rect2) -> void:
    var blue_center := _world_to_map(Vector3(0.0, 0.0, 12.0), map_rect)
    var red_center := _world_to_map(Vector3(0.0, 0.0, -12.0), map_rect)
    draw_circle(blue_center, 7.0, Color("#287FC0", 0.8))
    draw_circle(red_center, 7.0, Color("#C64F59", 0.8))
    draw_circle(blue_center, 3.0, Color("#9CE6FF"))
    draw_circle(red_center, 3.0, Color("#FFC0A8"))


func _draw_structures(map_rect: Rect2) -> void:
    var blue_towers = game.get("blue_towers")
    var red_towers = game.get("red_towers")
    _draw_tower_list(blue_towers, Color("#58C8FF"), map_rect)
    _draw_tower_list(red_towers, Color("#FF766F"), map_rect)

    var blue_core = game.get("blue_core")
    var red_core = game.get("red_core")
    _draw_core(blue_core, Color("#8DE3FF"), map_rect)
    _draw_core(red_core, Color("#FFB3A0"), map_rect)


func _draw_tower_list(towers, color: Color, map_rect: Rect2) -> void:
    for tower in towers:
        if not is_instance_valid(tower) or tower.hp <= 0.0:
            continue
        var point := _world_to_map(tower.global_position, map_rect)
        draw_rect(Rect2(point - Vector2(3.0, 3.0), Vector2(6.0, 6.0)), color, true)


func _draw_core(core_node, color: Color, map_rect: Rect2) -> void:
    if not is_instance_valid(core_node) or not (core_node is ArenaTower):
        return
    var core := core_node as ArenaTower
    if core.hp <= 0.0:
        return
    var point := _world_to_map(core.global_position, map_rect)
    draw_circle(point, 5.0, color)
    draw_circle(point, 2.0, Color("#FFFFFF"))


func _draw_camps(map_rect: Rect2) -> void:
    for node in get_tree().get_nodes_in_group("arena_neutral_camps"):
        if not (node is ArenaNeutralCamp):
            continue
        var camp := node as ArenaNeutralCamp
        var point := _world_to_map(camp.global_position, map_rect)
        var active := camp.is_monster_alive()
        var color := Color("#E5C779") if active else Color("#66727B")
        draw_circle(point, 4.2, Color("#081321", 0.95))
        draw_circle(point, 3.0, color)
        if not active and camp.respawn_remaining > 0.0:
            draw_string(
                ThemeDB.fallback_font,
                point + Vector2(5.0, 3.0),
                str(int(ceil(camp.respawn_remaining))),
                HORIZONTAL_ALIGNMENT_LEFT,
                22.0,
                8,
                Color("#C4CFD7")
            )


func _draw_boss_altar(map_rect: Rect2) -> void:
    var point := _world_to_map(Vector3(6.6, 0.0, 0.0), map_rect)
    var boss_active := is_instance_valid(game.get("ancient_boss"))
    var color := Color("#FF765F") if boss_active else Color("#77B7C5", 0.72)
    draw_circle(point, 5.0, Color("#081321", 0.95))
    draw_circle(point, 3.4, color)
    draw_circle(point, 1.3, Color("#F6E7C8"))


func _draw_actors(map_rect: Rect2) -> void:
    for node in get_tree().get_nodes_in_group("arena_actors"):
        if not (node is ArenaActor):
            continue
        var actor := node as ArenaActor
        if not actor.alive:
            continue

        var point := _world_to_map(actor.global_position, map_rect)
        var color := Color("#54BFFF") if actor.team == 0 else Color("#FF6B70")
        var radius := 2.0 if actor.is_minion else 3.6

        if actor.is_player:
            draw_circle(point, 6.0, Color("#F8F5D8"))
            draw_circle(point, 4.2, color)
        elif actor.is_minion and actor.minion_role == "siege":
            var diamond := PackedVector2Array([
                point + Vector2(0.0, -5.0),
                point + Vector2(5.0, 0.0),
                point + Vector2(0.0, 5.0),
                point + Vector2(-5.0, 0.0)
            ])
            draw_colored_polygon(diamond, Color("#F0CF7A"))
        elif actor.is_minion and actor.minion_role == "super":
            draw_circle(point, 4.5, Color("#F4E0A0"))
            draw_circle(point, 2.8, color)
        elif actor.is_minion and actor.minion_role == "ranged":
            draw_circle(point, 3.0, Color("#B9E7FF") if actor.team == 0 else Color("#FFD0C8"))
            draw_circle(point, 1.6, color)
        else:
            draw_circle(point, radius, color)

        if not actor.is_minion:
            var role_mark := "M"
            match actor.team_role:
                "offlane":
                    role_mark = "O"
                "mid":
                    role_mark = "M"
                "carry":
                    role_mark = "C"
                "support":
                    role_mark = "S"
                "roamer":
                    role_mark = "R"
            draw_string(
                ThemeDB.fallback_font,
                point + Vector2(5.0, -4.0),
                role_mark,
                HORIZONTAL_ALIGNMENT_LEFT,
                10.0,
                8,
                Color("#F5F7FF")
            )

    for node in get_tree().get_nodes_in_group("arena_neutral_monsters"):
        if not (node is ArenaNeutralMonster):
            continue
        var monster := node as ArenaNeutralMonster
        if monster.alive:
            var point := _world_to_map(monster.global_position, map_rect)
            if monster.is_in_group("arena_ancient_bosses"):
                draw_circle(point, 7.0, Color("#FF765F", 0.30))
                draw_circle(point, 4.8, Color("#FF765F"))
                draw_circle(point, 2.0, Color("#FFF0D2"))
            else:
                draw_circle(point, 2.5, Color("#F2D27B"))


func _world_to_map(world_position: Vector3, map_rect: Rect2) -> Vector2:
    var normalized_x := inverse_lerp(WORLD_MIN_X, WORLD_MAX_X, world_position.x)
    var normalized_z := inverse_lerp(WORLD_MIN_Z, WORLD_MAX_Z, world_position.z)
    return Vector2(
        map_rect.position.x + normalized_x * map_rect.size.x,
        map_rect.position.y + normalized_z * map_rect.size.y
    )
