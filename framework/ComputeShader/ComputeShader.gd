extends Node

class_name ComputeShader

@export var shader_name: String = ""
@export var file: RDShaderFile

@export_group("Layout")
@export_range(0, 1024, 1) var layout_set = 0

@export_group("Execute")
@export_range(1, 512) var x_workgroups = 1
@export_range(1, 512) var y_workgroups = 1
@export_range(1, 512) var z_workgroups = 1

@export var uniforms: Array[RenderingDevice.UniformType]

var rd: RenderingDevice = RenderingServer.create_local_rendering_device()
var spirv: RDShaderSPIRV

var shader: RID
var buffers: Array[RID] = []

var uniform: RDUniform
var uniform_set: RID

var pipeline: RID
var compute_list: int

var input
var input_bytes: PackedByteArray

func set_uniform(uniform_dict: Dictionary):
	var data = uniform_dict.data
	var type = uniform_dict.type
	input = data
	if data is PackedByteArray:
		input_bytes = data
	elif data is PackedInt32Array \
	or data is PackedInt64Array \
	or data is PackedFloat32Array \
	or data is PackedFloat64Array \
	or data is PackedStringArray \
	or data is PackedVector2Array \
	or data is PackedVector3Array \
	or data is PackedColorArray:
		input_bytes = data.to_byte_array()
	else:
		input_bytes = var_to_bytes_with_objects(data)

	buffer = rd.storage_buffer_create(input_bytes.size(), input_bytes)
	uniform = RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = 0
	uniform.add_id(buffer)
	uniform_set = rd.uniform_set_create([uniform], shader, layout_set)
	pipeline = rd.compute_pipeline_create(shader)
	compute_list = rd.compute_list_begin()

	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, x_workgroups, y_workgroups, z_workgroups)
	rd.compute_list_end()

func set_uniforms():
	pass

func initialize(input):
	buffers = []
	spirv = file.get_spirv()
	shader = rd.shader_create_from_spirv(spirv, shader_name)
	if input is Array:
		set_uniforms(input)
	elif input is Dictionary:
		set_uniform(input)

func submit():
	rd.submit()

func sync():
	rd.sync()

func get_output_bytes() -> PackedByteArray:
	return rd.buffer_get_data(buffer)
