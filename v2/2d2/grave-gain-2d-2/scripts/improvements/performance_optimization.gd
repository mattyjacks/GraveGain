extends Node

# Performance Optimization - culling, pooling, and efficiency improvements

class_name PerformanceOptimization

signal performance_warning(metric: String, value: float)

var object_pooling_enabled: bool = true
var frustum_culling_enabled: bool = true
var lod_enabled: bool = true
var physics_optimization_enabled: bool = true

var object_pools: Dictionary = {}
var culled_nodes: Array[Node2D] = []
var lod_distances: Dictionary = {
	"high": 200.0,
	"medium": 400.0,
	"low": 600.0,
}

var fps_target: int = 60
var current_fps: float = 60.0
var frame_time_budget: float = 16.67

func _ready() -> void:
	_initialize_object_pools()

func _initialize_object_pools() -> void:
	object_pools = {
		"projectile": [],
		"particle": [],
		"effect": [],
		"enemy": [],
	}

func _process(delta: float) -> void:
	current_fps = 1.0 / delta
	
	if current_fps < fps_target * 0.8:
		performance_warning.emit("low_fps", current_fps)

func get_pooled_object(object_type: String) -> Node:
	if not object_pooling_enabled or not object_pools.has(object_type):
		return null
	
	var pool = object_pools[object_type]
	if pool.size() > 0:
		return pool.pop_front()
	
	return null

func return_to_pool(object: Node, object_type: String) -> void:
	if not object_pooling_enabled or not object_pools.has(object_type):
		object.queue_free()
		return
	
	object.visible = false
	object_pools[object_type].append(object)

func apply_frustum_culling(nodes: Array[Node2D], camera_pos: Vector2, viewport_size: Vector2) -> void:
	if not frustum_culling_enabled:
		return
	
	var culling_margin = 200.0
	var culling_rect = Rect2(camera_pos - viewport_size / 2.0 - Vector2(culling_margin, culling_margin), 
							  viewport_size + Vector2(culling_margin * 2, culling_margin * 2))
	
	for node in nodes:
		if not is_instance_valid(node):
			continue
		
		var node_rect = Rect2(node.global_position - Vector2(32, 32), Vector2(64, 64))
		node.visible = culling_rect.intersects(node_rect)

func apply_lod(node: Node2D, camera_pos: Vector2) -> void:
	if not lod_enabled or not node.has_meta("lod_levels"):
		return
	
	var distance = node.global_position.distance_to(camera_pos)
	var lod_level = "high"
	
	if distance > lod_distances["low"]:
		lod_level = "low"
	elif distance > lod_distances["medium"]:
		lod_level = "medium"
	
	if node.has_method("set_lod_level"):
		node.set_lod_level(lod_level)

func optimize_physics(physics_space: PhysicsDirectSpaceState2D) -> void:
	if not physics_optimization_enabled:
		return
	
	# Reduce physics update frequency for distant objects
	# This would be implemented in the physics system

func batch_render_calls(nodes: Array[Node2D]) -> void:
	# Group nodes by texture/material for efficient batching
	var batches: Dictionary = {}
	
	for node in nodes:
		if not is_instance_valid(node):
			continue
		
		var key = ""
		if node is Sprite2D:
			key = str(node.texture)
		
		if not batches.has(key):
			batches[key] = []
		
		batches[key].append(node)

func reduce_particle_count(particles: Array[Node2D], target_count: int) -> void:
	if particles.size() <= target_count:
		return
	
	var step = int(ceil(float(particles.size()) / float(target_count)))
	
	for i in range(particles.size()):
		if i % step != 0:
			particles[i].queue_free()

func cache_expensive_calculations(key: String, value: Variant, ttl: float = 1.0) -> void:
	# Simple caching system for expensive calculations
	var cache_entry = {
		"value": value,
		"time": Time.get_ticks_msec(),
		"ttl": ttl * 1000.0,
	}
	
	if not has_meta("calculation_cache"):
		set_meta("calculation_cache", {})
	
	var cache = get_meta("calculation_cache")
	cache[key] = cache_entry

func get_cached_calculation(key: String) -> Variant:
	if not has_meta("calculation_cache"):
		return null
	
	var cache = get_meta("calculation_cache")
	if not cache.has(key):
		return null
	
	var entry = cache[key]
	var age = Time.get_ticks_msec() - entry["time"]
	
	if age > entry["ttl"]:
		cache.erase(key)
		return null
	
	return entry["value"]

func get_current_fps() -> float:
	return current_fps

func get_memory_usage() -> float:
	return OS.get_static_memory_usage() / (1024.0 * 1024.0)

func get_performance_stats() -> Dictionary:
	return {
		"fps": current_fps,
		"memory_mb": get_memory_usage(),
		"pooled_objects": _count_pooled_objects(),
		"visible_nodes": _count_visible_nodes(),
	}

func _count_pooled_objects() -> int:
	var count = 0
	for pool in object_pools.values():
		count += pool.size()
	return count

func _count_visible_nodes() -> int:
	var count = 0
	for node in get_tree().get_nodes_in_group("renderable"):
		if node.visible:
			count += 1
	return count
