extends GSGameVisualQaCapture

## The visual QA capture of zed's weapons, on gs-game's shared tool (gs-game docs/visual-qa.md): each weapon's clips from
## the first-person camera (the view model and arms), behind-right and an opponent in front (a [GSHumanoidFigure] holding
## the same weapon as a [ZeeWorldModel], as everybody else sees it). Run through tools/zed_vqa_shot.sh.
##
## Layers: the view model draws on layer 20 (its own, hidden from the outside cameras by the shared views), the figure and
## its gun on BODY_LAYER, which the first-person camera does not draw.

const BODY_LAYER := 1 << 18
const CLIPS: PackedStringArray = ["hip", "fire", "reload", "aim", "draw"]
const SECONDS := {"hip": 1.0, "fire": 1.6, "reload": 2.4, "aim": 1.6, "draw": 1.2}

var _view: ZeeViewModel = null
var _figure: GSHumanoidFigure = null
var _world: ZeeWorldModel = null
var _art: ZeeWeaponArt = null
var _kind := ZeeWeaponNet.KIND_SHOT
var _recoil := Vector2(0.5, 0.1)
var _fired := 0
var _primed := false


func _items() -> PackedStringArray:
	ZedWeaponPack.install()
	var ids := PackedStringArray()
	for art in ZedWeaponPack.art():
		ids.append(String(art.id))
	return ids


func _clips(_item: String) -> PackedStringArray:
	return CLIPS


func _build() -> void:
	ZedWeaponPack.install()
	build_stage()
	first_person.cull_mask = 0xFFFFF & ~BODY_LAYER
	_view = ZeeViewModel.new()
	_view.arm_skin = "res://assets/arms/Textures/texture-c.png"
	first_person.add_child(_view)
	_view.set_process(false)
	_figure = GSHumanoidFigure.new()
	_figure.name = "Person"
	stage.add_child(_figure)
	_figure.build(GSHumanoidLook.stock(1))
	# The nodes enter the tree on the next frame; _stage runs after it (the capture awaits warm-up frames per clip).


func _subject(_item: String) -> Node3D:
	return _figure


func _seconds(_item: String, clip: String) -> float:
	return float(SECONDS[clip])


func _warmup_frames(_item: String, _clip: String) -> int:
	return 6


func _stage(item: String, clip: String) -> GSResult:
	_art = ZeeWeaponArtTable.get_art(StringName(item))
	if _art == null:
		return GSResult.fail(GSError.CODE_UNSUPPORTED, "no art for %s" % item)
	var hold := GSHumanoidFigure.Hold.GUN
	_kind = ZeeWeaponNet.KIND_SHOT
	match _art.pose:
		ZeeWeaponArtTable.POSE_MELEE:
			hold = GSHumanoidFigure.Hold.MELEE
			_kind = ZeeWeaponNet.KIND_SWING
		ZeeWeaponArtTable.POSE_THROWN:
			hold = GSHumanoidFigure.Hold.NONE
			_kind = ZeeWeaponNet.KIND_THROW
	_figure.set_hold(hold)
	if _world != null:
		_world.queue_free()
	_world = ZeeWorldModel.new()
	_world.effects = false
	if not _world.attach_to(_figure):
		return GSResult.fail(GSError.CODE_UNSUPPORTED, "the person has no hand")
	var _equipped := _world.equip(_art)
	_world.set_process(false)
	var _viewed := _view.equip(_art)
	_view.on_reset()
	_view.aim(false)
	_view.on_reload(0.0)
	_view.on_deploy(1.0)
	_fired = 0
	_primed = false
	return GSResult.success(0)


## Shots at these seconds of the fire clip (a swing or throw for the other kinds).
func _shot_times(clip: String) -> Array[float]:
	if clip == "fire":
		return [0.2, 0.7, 1.1]
	return []


func _drive(_item: String, clip: String, t: float, frame: int) -> void:
	# The capture drives frame 0 twice (once to prime the outside views); step once.
	if frame == 0 and _primed:
		return
	_primed = true
	var dt := 1.0 / float(fps)
	if frame == 0:
		dt = 0.0
	match clip:
		"aim":
			_view.aim(t >= 0.1)
		"reload":
			var f := clampf(t / float(SECONDS["reload"]), 0.0, 1.0)
			_view.on_reload(f if f < 1.0 else 0.0)
			_world.on_reloading(f > 0.0 and f < 1.0)
		"draw":
			_view.on_deploy(clampf(t / float(SECONDS["draw"]), 0.0, 1.0))
	var shots := _shot_times(clip)
	while _fired < shots.size() and t >= shots[_fired]:
		_fired += 1
		_view.on_fired(_recoil)
		if _kind == ZeeWeaponNet.KIND_SWING:
			_figure.swing()
		_world.on_fired(Vector2(1.2, 0.0), _kind, false)
	_view.advance(dt)
	_figure.animate(0.0, dt)
	_world.advance(dt)


func _before_draw(_item: String, _clip: String, _frame: int) -> void:
	var _n := GSGameVisualQaViews.tag_layers(_figure, BODY_LAYER)


## Eyes at 1.6 m, looking straight out: the view model hangs off this camera.
func _place_first_person(_item: String) -> void:
	first_person.global_position = _figure.global_position + Vector3(0.0, 1.6, 0.0)
	first_person.global_rotation = Vector3.ZERO
