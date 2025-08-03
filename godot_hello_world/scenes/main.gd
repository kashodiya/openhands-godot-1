extends Node2D

func _ready():
	# Create a container for our UI elements
	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.size = Vector2(400, 300)
	container.position = Vector2(200, 150)
	
	# Create a label to display "Hello World"
	var label = Label.new()
	label.text = "Hello World!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Set font size
	var font_size = 64
	label.add_theme_font_size_override("font_size", font_size)
	
	# Create a start button
	var button = Button.new()
	button.text = "Start Game"
	button.size = Vector2(200, 50)
	button.position = Vector2(100, 150)
	
	# Connect the button's pressed signal to the _on_start_button_pressed function
	button.connect("pressed", _on_start_button_pressed)
	
	# Add the label and button to the container
	container.add_child(label)
	container.add_spacer(false)  # Add some space between label and button
	container.add_child(button)
	
	# Add the container to the scene
	add_child(container)

func _on_start_button_pressed():
	# Change to the game scene
	get_tree().change_scene_to_file("res://scenes/game_scene.tscn")
