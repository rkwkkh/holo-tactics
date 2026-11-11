class_name GridPathfinder
extends RefCounted

static func find_path(start: Vector2i, goal: Vector2i, columns: int, rows: int, blocked: Dictionary = {}) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if not _inside(start, columns, rows) or not _inside(goal, columns, rows) or blocked.has(goal) or start == goal:
		return path
	var frontier: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var cost_so_far := {start: 0}
	var directions := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
	while not frontier.is_empty():
		var best_index := 0
		var best_cell: Vector2i = frontier[0]
		var best_score: int = cost_so_far[best_cell] + _distance(best_cell, goal)
		for index in range(1, frontier.size()):
			var candidate: Vector2i = frontier[index]
			var score: int = cost_so_far[candidate] + _distance(candidate, goal)
			if score < best_score:
				best_index = index
				best_cell = candidate
				best_score = score
		frontier.remove_at(best_index)
		if best_cell == goal:
			var cursor := goal
			while cursor != start:
				path.push_front(cursor)
				cursor = came_from[cursor]
			return path
		for direction in directions:
			var neighbor: Vector2i = best_cell + direction
			if not _inside(neighbor, columns, rows) or blocked.has(neighbor):
				continue
			var new_cost: int = cost_so_far[best_cell] + 1
			if new_cost < cost_so_far.get(neighbor, 2147483647):
				cost_so_far[neighbor] = new_cost
				came_from[neighbor] = best_cell
				if not frontier.has(neighbor):
					frontier.append(neighbor)
	return path

static func _inside(cell: Vector2i, columns: int, rows: int) -> bool:
	return cell.x >= 0 and cell.x < columns and cell.y >= 0 and cell.y < rows

static func _distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
