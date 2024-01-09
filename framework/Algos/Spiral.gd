extends RefCounted

class_name Spiral

var dx: int = 1
var dy: int = 0
var length = 1 # segment length
var x: int = 0
var y: int = 0
var passed: int = 0 # segment passed
var counter: int = 0
var end: int = 0


func _init(size: int):
	self.end = size * size

func _iter_init(_arg):
	dx = 1
	dy = 0
	x = 0
	y = 0
	counter = 0
	passed = 0
	length = 1
	return should_continue()

func _iter_next(_arg):
	x += dx
	y += dy
	passed += 1
	if passed == length:
		# done with current segment
		passed = 0
		var temp = dx
		dx = -dy
		dy = temp
		# we've made a full rotation, increase length
		if dy == 0:
			length += 1
	counter += 1
	return should_continue()

func should_continue():
	return counter < end

func _iter_get(_arg):
	return Vector2i(x, y)
