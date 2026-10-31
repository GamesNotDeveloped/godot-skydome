@tool
extends Node

## The skies (SkydomeSky), each by its RID - the autoload SkydomeServer the plugin adds - as
## RenderingServer keeps the lights a Light3D sets its parameters on.
##
## A Skydome node sets the parameters it is tuned with; the game and the weather set theirs on the
## same sky as they go (the time, the fog, the clouds, the wind), past the node, so nothing of theirs
## reaches a scene.

var _skies: Dictionary[RID, SkydomeSky] = {}
var _last_id: int = 0


## A new sky, drawn once it is bound (skydome_bind())
func skydome_create() -> RID:
    _last_id += 1
    var rid: RID = rid_from_int64(_last_id)
    var sky: SkydomeSky = SkydomeSky.new()
    _skies[rid] = sky
    return rid


func skydome_free(rid: RID) -> void:
    _skies[rid].release()
    _skies.erase(rid)


## The WorldEnvironment and the light the sky draws into; either null - none
func skydome_bind(rid: RID, world_environment: WorldEnvironment, light: DirectionalLight3D) -> void:
    _skies[rid].bind(world_environment, light)


## The sky's parameter [param name] (a property of SkydomeSky's)
func skydome_set_param(rid: RID, name: StringName, value: Variant) -> void:
    _skies[rid].set(name, value)


func skydome_get_param(rid: RID, name: StringName) -> Variant:
    return _skies[rid].get(name)


## The sky itself, for what reads how it is drawn (its blends, its sun, its camera)
func skydome_get_sky(rid: RID) -> SkydomeSky:
    return _skies[rid]


## The clouds' wind taken at once, not eased into
func skydome_apply_wind_now(rid: RID) -> void:
    _skies[rid].apply_wind_now()


func _process(delta: float) -> void:
    for sky: SkydomeSky in _skies.values():
        sky.process(delta)
