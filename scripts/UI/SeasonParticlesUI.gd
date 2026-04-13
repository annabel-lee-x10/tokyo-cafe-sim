extends Node
## Manages CPUParticles2D for seasonal atmosphere effects.
## Attach to a Node child of CafeView.

var _particles: CPUParticles2D = null

func _ready() -> void:
	SeasonManager.season_changed.connect(func(id, _d): _apply_season(id))
	_apply_season(SeasonManager.current_season_id)

func _apply_season(season_id: String) -> void:
	if _particles:
		_particles.queue_free()
		_particles = null

	if season_id != "spring":
		return   # only spring has falling petals

	_particles = CPUParticles2D.new()
	_particles.emitting            = true
	_particles.amount              = 28
	_particles.lifetime            = 6.0
	_particles.preprocess          = 3.0
	_particles.emission_shape      = CPUParticles2D.EMISSION_SHAPE_BOX
	_particles.emission_box_extents = Vector3(560, 4, 1)
	_particles.position            = Vector2(540, -4)
	_particles.direction           = Vector2(0.4, 1.0)
	_particles.spread              = 22.0
	_particles.gravity             = Vector2(12, 48)
	_particles.initial_velocity_min = 24.0
	_particles.initial_velocity_max = 64.0
	_particles.angular_velocity_min = -60.0
	_particles.angular_velocity_max =  60.0
	_particles.color               = Color(1.0, 0.76, 0.82, 0.85)
	_particles.scale_amount_min    = 3.0
	_particles.scale_amount_max    = 5.5
	get_parent().add_child(_particles)
