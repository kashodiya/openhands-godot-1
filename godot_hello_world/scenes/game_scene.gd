extends Node2D

var ball
var floor_node
var velocity = Vector2(0, 0)
var gravity = 20.0
var friction = 0.8
var bounce = 0.7
var jump_force = 500
var move_speed = 300
var jump_count = 0
var max_jumps = 3
var jump_decay = 0.7  # Each subsequent jump is 70% as powerful
var last_jump_time = 0
var jump_cooldown = 0.3  # Seconds between jumps

# Platform variables
var platforms = []
var platform_speed = 3.0
var platform_spawn_interval = 2.0
var last_platform_time = 0.0
var platform_container

func _ready():
	# Create the floor (static body for collision)
	floor_node = StaticBody2D.new()
	var floor_collision = CollisionShape2D.new()
	var floor_shape = RectangleShape2D.new()
	floor_shape.size = Vector2(800, 50)
	floor_collision.shape = floor_shape
	
	var floor_visual = ColorRect.new()
	floor_visual.color = Color(0.33, 0.66, 0.33)  # Green color
	floor_visual.set_size(Vector2(800, 50))
	floor_visual.position = Vector2(-400, -25)  # Center the rect on the collision shape
	
	floor_node.position = Vector2(400, 575)  # Position at the bottom of the screen
	floor_node.add_child(floor_collision)
	floor_node.add_child(floor_visual)
	add_child(floor_node)
	
	# Create platform container
	platform_container = Node2D.new()
	platform_container.name = "PlatformContainer"
	add_child(platform_container)
	
	# Create the ball (rigid body for physics)
	ball = create_ball()
	add_child(ball)
	
	# Start platform timer
	last_platform_time = Time.get_ticks_msec() / 1000.0

func create_ball():
	var ball_node = RigidBody2D.new()
	ball_node.mass = 1.0
	ball_node.gravity_scale = 4.0
	ball_node.bounce = bounce
	ball_node.friction = friction
	ball_node.linear_damp = 0.0
	ball_node.can_sleep = false
	ball_node.lock_rotation = true
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 25
	collision.shape = circle
	
	# Add visual
	var ball_visual = ColorRect.new()
	ball_visual.color = Color(1.0, 0.33, 0.33)  # Red color
	ball_visual.set_size(Vector2(50, 50))
	ball_visual.position = Vector2(-25, -25)  # Center the rect on the collision shape
	
	ball_node.position = Vector2(400, 300)  # Center of the screen
	ball_node.add_child(collision)
	ball_node.add_child(ball_visual)
	
	return ball_node

func _physics_process(delta):
	# Update platforms
	update_platforms(delta)
	
	# Handle input
	var input_vector = Vector2.ZERO
	var current_velocity = ball.linear_velocity
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
		# Apply force with acceleration but cap at max speed
		if current_velocity.x > -move_speed:
			ball.apply_central_force(Vector2(input_vector.x * move_speed * 2, 0))
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
		# Apply force with acceleration but cap at max speed
		if current_velocity.x < move_speed:
			ball.apply_central_force(Vector2(input_vector.x * move_speed * 2, 0))
			
	# Handle jumping with multiple air jumps
	if Input.is_action_just_pressed("ui_up"):
		var on_floor = is_ball_on_floor()
		
		# Allow jump if on floor or if we have jumps remaining and cooldown passed
		if on_floor or (jump_count < max_jumps and current_time - last_jump_time > jump_cooldown):
			# Reset jump count if on floor
			if on_floor:
				jump_count = 0
				
			# Calculate jump force with decay for subsequent jumps
			var current_jump_force = jump_force * pow(jump_decay, jump_count)
			ball.apply_central_impulse(Vector2(0, -current_jump_force))
			
			jump_count += 1
			last_jump_time = current_time
	
	# Cap maximum horizontal speed
	if abs(current_velocity.x) > move_speed:
		ball.linear_velocity.x = move_speed * sign(current_velocity.x)
		
	# Apply more friction when not pressing movement keys
	if input_vector.x == 0:
		ball.linear_velocity.x *= friction
		
	# Reset jump count when landing on floor
	if is_ball_on_floor() and ball.linear_velocity.y >= 0:
		jump_count = 0

func is_ball_on_floor():
	# Simple check if ball is close to the floor
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(ball.position, ball.position + Vector2(0, 30))
	var result = space_state.intersect_ray(query)
	
	if result and result.collider == floor_node:
		return true
	
	# Check if ball is on any platform
	for platform in platforms:
		if platform.is_ball_on_platform(ball):
			return true
	
	return false

func create_platform():
	# Generate random platform properties
	var width = randf_range(50, 200)
	var height = 20
	var y_pos = randf_range(150, 450)
	
	# Create platform node
	var platform_node = StaticBody2D.new()
	platform_node.position = Vector2(800, y_pos)  # Start from right edge
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(width, height)
	collision.shape = rect_shape
	
	# Add visual
	var platform_visual = ColorRect.new()
	platform_visual.color = Color(0.2, 0.4, 0.8)  # Blue color
	platform_visual.set_size(Vector2(width, height))
	platform_visual.position = Vector2(-width/2, -height/2)  # Center the rect on the collision shape
	
	platform_node.add_child(collision)
	platform_node.add_child(platform_visual)
	platform_container.add_child(platform_node)
	
	# Create platform object to track
	var platform = Platform.new(platform_node, width, height)
	platforms.append(platform)
	
	return platform

func update_platforms(delta):
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Check if there's enough space for a new platform
	var can_create_platform = true
	var rightmost_x = 0
	
	for platform in platforms:
		rightmost_x = max(rightmost_x, platform.node.position.x + platform.width/2)
	
	# Only create a new platform if the rightmost platform is at least 300px away from the right edge
	if rightmost_x > 500:
		can_create_platform = false
	
	# Spawn new platform if it's time and there's enough space
	if can_create_platform and current_time - last_platform_time > platform_spawn_interval:
		create_platform()
		last_platform_time = current_time
		
		# Randomize next spawn interval
		platform_spawn_interval = randf_range(1.0, 3.0)
	
	# Update platform positions
	for i in range(platforms.size() - 1, -1, -1):
		var platform = platforms[i]
		
		# Move platform left
		platform.node.position.x -= platform_speed
		
		# Remove platform if it's off screen
		if platform.node.position.x + platform.width/2 < 0:
			platform.node.queue_free()
			platforms.remove_at(i)

# Platform class to track platform data
class Platform:
	var node: StaticBody2D
	var width: float
	var height: float
	
	func _init(p_node, p_width, p_height):
		node = p_node
		width = p_width
		height = p_height
	
	func is_ball_on_platform(ball_node: RigidBody2D) -> bool:
		# Check if ball is above the platform and falling
		var ball_bottom = ball_node.position.y + 25  # Ball radius
		var platform_top = node.position.y - height/2
		var ball_x = ball_node.position.x
		var platform_left = node.position.x - width/2
		var platform_right = node.position.x + width/2
		
		return (ball_node.linear_velocity.y >= 0 and
				abs(ball_bottom - platform_top) < 10 and
				ball_x >= platform_left and
				ball_x <= platform_right)
