extends CanvasGroup

var node_positions = {}

var t = 0.0

func _ready():
	for node in get_children():
		node_positions[node] = node.position
		for sub_node in node.get_children():
			node_positions[sub_node] = sub_node.position

func _process(delta):
	t += delta * 0.5
	for i in range(get_child_count()):
		var child = get_child(i)
		child.position.y = node_positions[child].y + sin((i * 1.5) + (t * 2.2)) * 0.4
		for j in range(child.get_child_count()):
			var subchild = child.get_child(j)
			subchild.position.y = node_positions[subchild].y + sin((j * 1.2) + (t * 1.2)) * (4.2 * clamp((-1 + t) * 0.1, 0.0, 1.0))
			subchild.position.x = node_positions[subchild].x + sin((j * 10.2) + (t * 3.2 + j * 0.1)) * (1.2 * clamp((-1 + t) * 0.1, 0.0, 1.0))
