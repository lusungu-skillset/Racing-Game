extends CharacterBody3D

# Exported variables
@export var path_node: Path3D
@export var reverse_path: bool = false
@export_range(0.5, 20.0) var separation_radius: float = 4.0
@export var max_speed: float = 20
@export var max_accel: float = 20

# Steering AI components
var agent: GSAICharacterBody3DAgent
var follow_path_behavior: GSAIFollowPath
var separation_behavior: GSAISeparation
var blend_behavior: GSAIBlend

@onready var accel = GSAITargetAcceleration.new()

func _ready():
	# Initialize the steering agent
	agent = await GSAICharacterBody3DAgent.new(self)
	agent.body = self
	agent.linear_speed_max = max_speed
	agent.linear_acceleration_max = max_accel
	agent.linear_drag_percentage = 0.05  # Small damping to prevent overshooting
	
	# Add this agent to metadata for neighbor detection
	set_meta("gsai_agent", agent)
	
	# Add to ai_cars group for separation behavior
	add_to_group("ai_cars")
	
	# Set up steering behaviors
	_setup_steering_behaviors()

func _setup_steering_behaviors():
	# Create path following behavior
	_setup_path_following()
	
	# Create separation behavior
	_setup_separation()
	
	# Blend behaviors (80% path following, 20% separation)
	blend_behavior = GSAIBlend.new(agent)
	blend_behavior.add(follow_path_behavior, 0.8)
	blend_behavior.add(separation_behavior, 0.2)

func _setup_path_following():
	if not path_node or not path_node.curve:
		push_error("Path3D node or curve not found for AI car!")
		return
	
	# Convert Path3D curve to GSAIPath
	var curve_points = _convert_curve_to_gsai_path(path_node.curve)
	var gsai_path = GSAIPath.new(curve_points, false)  # false for not looping
	
	# Create follow path behavior
	follow_path_behavior = GSAIFollowPath.new(agent, gsai_path)
	follow_path_behavior.path_offset = 1.5
	follow_path_behavior.prediction_time = 0.5
	follow_path_behavior.deceleration_radius = 3.0
	
	# Set path direction
	if reverse_path:
		follow_path_behavior.is_arrive_enabled = false

func _convert_curve_to_gsai_path(curve: Curve3D) -> PackedVector3Array:
	var points = PackedVector3Array()
	
	if not curve:
		push_error("No curve provided!")
		return points
	
	# Use baked points for smoother path following
	var baked_points = curve.get_baked_points()
	
	# Reverse path if needed
	if reverse_path:
		baked_points.reverse()
	
	points = baked_points
	return points

func _setup_separation():
	# Get initial neighbors
	var neighbors = _get_neighbor_agents()
	
	# Create proximity and separation behaviors
	var proximity = GSAIRadiusProximity.new(agent, neighbors, separation_radius)
	separation_behavior = GSAISeparation.new(agent, proximity)
	separation_behavior.decay_coefficient = 1.0

func _get_neighbor_agents() -> Array:
	var neighbors = []
	var ai_cars = get_tree().get_nodes_in_group("ai_cars")
	
	for car in ai_cars:
		if car == self:
			continue
		
		var neighbor_agent = car.get_meta("gsai_agent", null)
		if neighbor_agent:
			neighbors.append(neighbor_agent)
	
	return neighbors

func _physics_process(delta):
	if not agent or not blend_behavior:
		return
	
	# Update agent position before calculations
	agent.position = global_position
	
	# Update neighbor agents for separation behavior
	separation_behavior.proximity.agents = _get_neighbor_agents()
	
	# Reset acceleration
	accel.linear = Vector3.ZERO
	
	# Calculate steering acceleration
	blend_behavior.calculate_steering(accel)
	
	# Apply the acceleration to the agent's velocity
	agent._apply_steering(accel, delta)
	
	# Sync Godot's velocity with agent's velocity
	velocity = agent.linear_velocity
	
	# Move the character
	var collision = move_and_slide()
	
	# Handle collisions - reduce speed when hitting walls
	if get_slide_collision_count() > 0:
		for i in get_slide_collision_count():
			var col = get_slide_collision(i)
			# Check if collision is with static geometry (walls)
			if col.get_collider() is StaticBody3D:
				# Reduce speed by 50% when hitting walls
				velocity *= 0.5
				agent.linear_velocity = velocity
				break
	
	# Rotate car to face movement direction
	_face_movement_direction()

func _face_movement_direction():
	if velocity.length_squared() > 0.1:
		# Look at the direction we're moving
		var target_position = global_position + velocity.normalized()
		look_at(target_position, Vector3.UP)
		
		# Rotate 180 degrees because car models typically face backwards
		rotate_object_local(Vector3.UP, PI)

# Debug function to check if everything is set up correctly
func _check_setup():
	print("Agent: ", agent != null)
	print("Blend Behavior: ", blend_behavior != null)
	print("Follow Path: ", follow_path_behavior != null)
	print("Separation: ", separation_behavior != null)
	print("Path Node: ", path_node != null)
	if path_node:
		print("Curve Points: ", path_node.curve.get_baked_points().size())

# Call this in _ready() after setup to verify
func _enter_tree():
	await get_tree().process_frame
	_check_setup()

# Function to update path at runtime if needed
func set_new_path(new_path: Path3D):
	path_node = new_path
	_setup_path_following()

# Function to update separation radius
func set_separation_radius(new_radius: float):
	separation_radius = new_radius
	separation_behavior.proximity.radius = new_radius
