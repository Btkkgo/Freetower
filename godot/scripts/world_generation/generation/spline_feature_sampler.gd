class_name SplineFeatureSampler
extends RefCounted


func sample(feature: Resource, spacing_m: float = 1.0) -> PackedVector3Array:
	var result := PackedVector3Array()
	if feature.control_points.size() < 2 or spacing_m <= 0.0:
		return result
	result.append(feature.control_points[0])
	for index in range(feature.control_points.size() - 1):
		var start: Vector3 = feature.control_points[index]
		var finish: Vector3 = feature.control_points[index + 1]
		var distance := start.distance_to(finish)
		var steps := maxi(1, ceili(distance / spacing_m))
		for step in range(1, steps + 1):
			result.append(start.lerp(finish, float(step) / float(steps)))
	return result


func distance_to_feature(point: Vector3, feature: Resource) -> float:
	if feature.control_points.size() < 2:
		return INF
	var point_2d := Vector2(point.x, point.z)
	var best := INF
	for index in range(feature.control_points.size() - 1):
		var start := Vector2(feature.control_points[index].x, feature.control_points[index].z)
		var finish := Vector2(feature.control_points[index + 1].x, feature.control_points[index + 1].z)
		var closest := Geometry2D.get_closest_point_to_segment(point_2d, start, finish)
		best = minf(best, point_2d.distance_to(closest))
	return best
