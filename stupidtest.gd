extends Node2D

func _process(delta):
	#loop_1()
	#loop_2()
	loop_4()

# 14.5ms
func loop_1():
	for i in 1000:
		for j in 1000:
			pass

# 33.40ms
func loop_2():
	var size = 1000
	var i = 0
	var j = 0
	while i < size:
		j = 0
		i += 1
		while j < size:
			j += 1

# 26.1ms
func loop_3():
	var arr = range(1000)
	for i in arr:
		for j in arr:
			pass

# 0.0ms
func loop_4():
	for i in range(1000000):
		break

# 7.0ms
func loop_5():
	var a = range(1000000)
	for i in a:
		break
