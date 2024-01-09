extends Node

class_name Utils

static func clear_children(node: Node, deferred=true):
	if deferred:
		for child in node.get_children():
				child.queue_free()
		return
	for child in node.get_children():
		child.free()

static func map(value, istart, istop, ostart, ostop):
	return ostart + (ostop - ostart) * ((value - istart) / (istop - istart))

static func map_pow(value, istart, istop, ostart, ostop, power):
	return ostart + (ostop - ostart) * (pow((value - istart) / (istop - istart), power))

static func enum_string(value, enum_):
	return enum_.keys()[value].capitalize()

static func get_value_above(dict: Dictionary, num: int):
	var value = dict[0]
	for key in dict:
		if key > num:
			return value
		value = dict[key]
	return value

static func tree_set_all_process(p_node: Node, p_active: bool, p_self_too: bool = false) -> void:
	if not p_node:
		push_error("p_node is empty")
		return
	var p = p_node.is_processing()
	var pp = p_node.is_physics_processing()
	p_node.propagate_call("set_process", [p_active])
	p_node.propagate_call("set_physics_process", [p_active])
	if not p_self_too:
		p_node.set_process(p)
		p_node.set_physics_process(pp)

static func pulse(duration:float=1.0, width:float=0.5) -> bool:
	return wave(0.0, 1.0, duration) < width

static func snap(value, step):
	return round(value / step) * step

static func approach(a, b, amount):
	if a < b:
		a += amount
		if a > b:
			return b
	else:
		a -= amount
		if a < b:
			return b
	return a

static func get_player(node):
	return node.get_tree().get_nodes_in_group("player")[0]

static func ang2vec(angle):
	return Vector2(cos(angle), sin(angle))

static func dtlerp(power, delta):
	return 1 - pow(pow(0.1, power), delta)

static func damp(source: float, target: float, smoothing: float, dt: float):
	return lerp(source, target, dtlerp(smoothing, dt))

static func damp_angle(source: float, target: float, smoothing: float, dt: float):
	return lerp_angle(source, target, 1 - pow(smoothing, dt))

static func damp_vec2(source: Vector2, target: Vector2, smoothing: float, dt: float):
	return source.lerp(target, 1 - pow(smoothing, dt))

static func damp_vec3(source: Vector3, target: Vector3, smoothing: float, dt: float):
	return source.lerp(target, 1 - pow(smoothing, dt))

static func ease_out(num, pow) -> float:
	assert(num <= 1 and num >= 0)
	return 1.0 - pow(1.0 - num, pow)

static func get_angle_from_to(node, position):
	var target = node.get_angle_to(position)
	target = target if abs(target) < PI else target + TAU * -sign(target)
	return target

static func lerp_clamp(a, b, t):
	return lerp(a, b, clamp(t, 0.0, 1.0))

static func inverse_lerp_clamp(a, b, v):
	return clamp(inverse_lerp(a, b, v), 0.0, 1.0)

static func angle_diff(from, to):
	return fposmod(to-from + PI, PI*2) - PI
	
static func comma_sep(number):
	var string = str(int(number))
	var mod = string.length() % 3
	var res = ""
	for i in range(0, string.length()):
		if i != 0 && i % 3 == mod:
			res += ","
		res += string[i]
	return res

static func flicker(object, frames=2, repetitions=6):
	var initial_state = object.visible
	object.hide()
	for i in range(repetitions):
		for j in range(frames):
			await object.get_tree().process_frame
		object.visible = !object.visible
	object.visible = initial_state
	return true

static func marching_squares(nw: bool, ne: bool, se: bool, sw: bool, size = 1):
	var case = (int(ne) * 8) | (int(nw) * 4) | (int(sw) * 2) | (int(se))
#	print(case)
	var polys = [
		[],
		[Vector2(-1, 0), Vector2(-1, 1), Vector2(0, 1), ],
		[Vector2(1, 1), Vector2(1, 0), Vector2(0, 1), ],
		[Vector2(-1, 0), Vector2(1, 0), Vector2(1, 1), Vector2(-1, 1), ],
		[Vector2(0, -1), Vector2(1, -1), Vector2(1, 0), ],
		[Vector2(0, -1), Vector2(1, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 1), Vector2(-1, 0), ],
		[Vector2(0, -1), Vector2(1, -1), Vector2(1, 1), Vector2(0, 1), ],
		[Vector2(0, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(-1, 0), ],
		[Vector2(-1, -1), Vector2(0, -1), Vector2(-1, 0), ],
		[Vector2(-1, -1), Vector2(0, -1), Vector2(0, 1), Vector2(-1, 1), ],
		[Vector2(-1, -1), Vector2(0, -1), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(-1, 0), ],
		[Vector2(-1, -1), Vector2(0, -1), Vector2(1, 0), Vector2(1, 1), Vector2(-1, 1), ],
		[Vector2(-1, -1), Vector2(1, -1), Vector2(1, 0), Vector2(-1, 0), ],
		[Vector2(-1, -1), Vector2(1, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 1), ],
		[Vector2(-1, 0), Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(0, 1), ],
		[Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), ],
	]
	var result = polys[case]
	for i in range(result.size()):
		var point = result[i]
		point *= size
		result[i] = point

	return PackedVector2Array(result)

static func bools_to_axis(negative, positive) -> float:
	return (-1.0 if negative else 0) + (1.0 if positive else 0)

static func bools_to_vector2(left, right, up, down) -> Vector2:
	return Vector2(bools_to_axis(left, right), bools_to_axis(up, down))

static func wave(from, to, duration, offset=0):
	var t = Time.get_ticks_msec() / 1000.0
	var a = (to - from) * 0.5
	return from + a + sin((((t) + duration * offset) / duration) * TAU) * a

static func remove_duplicates(array: Array):
	var seen = []
	var new = []
	for i in array.size():
		var value = array[i]
		if value in seen:
			continue
		seen.append(value)
		new.append(value)
	return new

static func queue_free_children(node: Node):
	for child in node.get_children():
		child.queue_free()
		
static func free_children(node: Node):
	for child in node.get_children():
		child.free()

static func is_in_circle(point: Vector2i, circle_center: Vector2i, circle_radius: float):
	return veci_distance_to(point, circle_center) < circle_radius

static func veci_distance_to(start: Vector2i, end: Vector2i):
	return veci_to_vec(start).distance_to(veci_to_vec(end))

static func veci_to_vec(veci: Vector2i) -> Vector2:
	return Vector2(veci.x, veci.y)

static func sin_0_1(value):
	return (sin(value) / 2.0) + 0.5

static func veci_length(v: Vector2i):
	return Vector2(v.x, v.y).length()

static func clamp_cell(cell: Vector2i, map: Array2D) -> Vector2i:
	return Vector2i(clamp(cell.x, 0, map.width - 1), clamp(cell.y, 0, map.height - 1))

static func stepify(s, step):
	return round(s / step) * step

static func spiral(size: int):
	return Spiral.new(size)

static func walk_path(path, absolute=false, filter_file_type=""):
	
	var files: = []
	var dir = DirAccess.open(path)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		#print(file)
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file if !absolute else dir.get_current_dir().path_join(file))
	return files.filter(func(f: String): return f.ends_with(filter_file_type))

static func quick_save_data(dict: Dictionary, name: String):
	var path = "user://".path_join(name)
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_var(dict, true) 

static func quick_load_data(name: String):
	var path = "user://".path_join(name)
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	return file.get_var()

static func line(start: Vector2i, end: Vector2i):
	# Bresenham's algorithm
	var temp
	var x1 = int(start.x)
	var y1 = int(start.y)
	var x2 = int(end.x)
	var y2 = int(end.y)
	var dx = x2 - x1
	var dy = y2 - y1
	
	var steep = abs(dy) > abs(dx)
	if steep:
		temp = x1
		x1 = y1
		y1 = temp
		temp = x2
		x2 = y2
		y2 = temp

	var swapped = false
	if x1 > x2:
		temp = x1
		x1 = x2
		x2 = temp
		temp = y1
		y1 = y2
		y2 = temp
		swapped = true
		
	dx = x2 - x1
	dy = y2 - y1
	var error: int = int(dx / 2.0)
	var ystep = 1 if y1 < y2 else -1
	var y = y1
	var points = []
	for x in range(x1, x2 + 1):
		points.append(Vector2i(y, x) if steep else Vector2i(x, y))
		error = error - abs(dy)
		if error < 0:
			y += ystep
			error += dx
	if swapped:
		points.reverse()
	return points

static func random_triangle_point(a, b, c):
	return a + sqrt(randf()) * (-a + b + randf() * (c - b))

static func triangle_area(a, b, c):
	var ba = a - b
	var bc = c - b
	return abs(ba.cross(bc)/2)

static func get_polygon_tris(polygon: PackedVector2Array):
	var points = Geometry2D.triangulate_polygon(polygon)
	var size = polygon.size()
	var tris = []
	for i in range(0, points.size(), 3):
		tris.append([polygon[points[i]], polygon[points[i + 1]], polygon[points[i + 2]]])
	return tris

static func get_polygon_area(polygon: PackedVector2Array):
	var area = 0.0
	for tri in get_polygon_tris(polygon):
		area += triangle_area(tri[0], tri[1], tri[2])
	return area

static func get_polygon_bounding_box(polygon: PackedVector2Array) -> Rect2:
	var top_left = Vector2(INF, INF)
	var bottom_right = Vector2(-INF, -INF)
	for point in polygon:
		if point.x < top_left.x:
			top_left.x = point.x
		if point.y < top_left.y:
			top_left.y = point.y
		if point.x > bottom_right.x:
			bottom_right.x = point.x
		if point.y > bottom_right.y:
			bottom_right.y = point.y
	return Rect2(top_left, bottom_right - top_left)

static func get_polygon_center(polygon: PackedVector2Array) -> Vector2:
	var avg = Vector2()
	for point in polygon:
		avg += point
	return (avg / float(polygon.size()))

static func get_random_point_in_polygon(polygon: PackedVector2Array, rng: BetterRng, num_points = 1, min_distance_between_points=0):
	var tris = get_polygon_tris(polygon)
	if tris.size() == 0:
		return Vector2()
	var get_point = (func():
		var tri = rng.func_weighted_choice(tris, func(t): return triangle_area(tris[t][0], tris[t][1], tris[t][2]))
		return random_triangle_point(tri[0], tri[1], tri[2]))
	if num_points == 1:
		return get_point.call()
	else:
		var chosen_points = []
		if min_distance_between_points == 0:
			for i in range(num_points):
				chosen_points.append(get_point.call())
		else:
			var quad_tree = QuadTree.new(get_polygon_bounding_box(polygon), 1)
			var max_try_count = 0
			for i in range(num_points):
				var tries = 0
				var valid_point = false
				var point
				var max_tries = 1000
				while tries == 0 or !(valid_point or tries >= max_tries):
					point = get_point.call()
					if chosen_points.is_empty():
						valid_point = true
					else:
						valid_point = true
						for nearby_point in quad_tree.search(point, min_distance_between_points, min_distance_between_points):
							if point.distance_to(nearby_point) < min_distance_between_points:
								valid_point = false
					tries += 1
					if tries >= max_tries:
						max_try_count += 1
#					Debug.dbg_max("tries", tries)
				quad_tree.insert(point)
#					print("didnt insert point into tree")
#				print("acquired point %d" % i)
				chosen_points.append(point)
#				Debug.dbg("max_try_count", max_try_count)
		return chosen_points

static func unique(callable: Callable, amount: int):
	var arr = []
	while arr.size() < amount:
		var result = callable.call()
		if !(result in arr):
			arr.append(result)
	return arr

static func quadratic_bell_curve(x):
	x = clamp(x, 0.0, 1.0)
	return (4.0 * x) * (1.0 - x)

static func spring(x:float,  v:float, xt:float, zeta:float, omega:float, h:float):
	# thanks chaoclypse
	var f = 1.0 + 2.0 * h * zeta * omega;
	var oo = omega * omega;
	var hoo = h * oo;
	var hhoo = h * hoo;
	var detInv = 1.0 / (f + hhoo);
	var detX = f * x + h * v + hhoo * xt;
	var detV = v + hoo * (xt - x);
	x = detX * detInv;
	v = detV * detInv;
	return [x,v];

static func vector_spring(vec:Vector2, vel:Vector2, target:Vector2, zeta:float,  omega:float,  h:float):
	var x = vec.x;
	var y = vec.y;
	var t1 = spring(x, vel.x, target.x, zeta, omega, h);
	x = t1[0]
	vel.x = t1[1]
	var t2=spring(y, vel.y, target.y, zeta, omega, h);
	y = t2[0]
	vel.y = t2[1]
	vec = Vector2(x, y);
	return [vec,vel];

static func closest_point_on_line_segment(p: Vector2, q: Vector2, point: Vector2):
	var ls = (point - p).dot(q - p) / (q - p).dot(q - p)
	var s
	if ls <= 0:
		s = p
	elif ls >= 1:
		s = q
	else:
		s = p + ls * (q - p)
	return s


static func time_convert(time_in_sec):
	time_in_sec = int(time_in_sec)
	var seconds = time_in_sec%60
	var minutes = (time_in_sec/60)%60
	var hours = (time_in_sec/60)/60

	#returns a string with the format "HH:MM:SS"
	return "%02d:%02d:%02d" % [hours, minutes, seconds]
