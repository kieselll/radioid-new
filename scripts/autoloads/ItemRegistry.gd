extends Node
class_name ItemRegistry

## Colony-wide directory of known item piles.
##
## The registry is a [b]memory[/b], not an oracle. It never scans the world on
## its own: entries are written only when a pile is [i]perceived[/i]. Knowledge
## is shared across the whole colony (see one pile, every pawn knows it) and
## persists even after the owning chunk unloads, becoming stale memory that
## [method validate] corrects against the authoritative per-chunk
## [code]ItemManager[/code] at the moment a pawn arrives.
##
## The per-chunk [code]ItemManager[/code] is always the source of truth for what
## items actually exist. This registry is only a hint used for planning routes.

#region signals

## Emitted when a pile is added to or refreshed in colony memory.
signal item_noted(coord: Vector4i, id: int)
## Emitted when a pile is dropped from colony memory.
signal item_forgotten(coord: Vector4i, id: int)

#endregion

#region private vars

## Item type id -> { global coord (Vector4i): last-known total count (int) }.
var _known: Dictionary[int, Dictionary] = {}
## Reverse lookup: global coord -> item type id (needed to bucket deletions).
var _coord_id: Dictionary[Vector4i, int] = {}
## Active reservations: global coord -> reserving pawn node path.
var _reservations: Dictionary[Vector4i, String] = {}
## The chunk manager whose load/unload signals drive perception.
var _chunk_manager: ChunkManager

#endregion

#region binding

## Connects the registry to a [ChunkManager] instance for the current game.
##
## Safe to call again on a new game: any previous binding is dropped first and
## all memory is cleared so stale state never leaks across sessions.
func bind_chunk_manager(chunk_manager: ChunkManager) -> void:
	if _chunk_manager == chunk_manager:
		return
	_unbind_chunk_manager()
	_chunk_manager = chunk_manager
	_known.clear()
	_coord_id.clear()
	_reservations.clear()
	if not _chunk_manager.chunk_generated.is_connected(_on_chunk_generated):
		_chunk_manager.chunk_generated.connect(_on_chunk_generated)
	if not _chunk_manager.chunk_deleted.is_connected(_on_chunk_deleted):
		_chunk_manager.chunk_deleted.connect(_on_chunk_deleted)


func _unbind_chunk_manager() -> void:
	if not is_instance_valid(_chunk_manager):
		_chunk_manager = null
		return
	if _chunk_manager.chunk_generated.is_connected(_on_chunk_generated):
		_chunk_manager.chunk_generated.disconnect(_on_chunk_generated)
	if _chunk_manager.chunk_deleted.is_connected(_on_chunk_deleted):
		_chunk_manager.chunk_deleted.disconnect(_on_chunk_deleted)
	_chunk_manager = null

#endregion

#region perception seam

## Records (or refreshes) a perceived pile in colony memory.
##
## This is the seam the perception system drives. Today the stub calls it for
## every pile in a chunk as the chunk loads ("loaded == perceived"); a real
## field-of-view system will later call it only for piles a pawn can actually
## see, without touching the rest of the registry.
func note_item(coord: Vector4i, id: int, count: int) -> void:
	if count <= 0:
		forget_item(coord)
		return
	# A coord that changed item type: drop it from its old bucket first.
	if _coord_id.has(coord) and _coord_id[coord] != id:
		_erase_known(coord)
	if not _known.has(id):
		_known[id] = {}
	_known[id][coord] = count
	_coord_id[coord] = id
	item_noted.emit(coord, id)


## Removes a pile from colony memory and releases any reservation on it.
func forget_item(coord: Vector4i) -> void:
	if not _coord_id.has(coord):
		return
	var id: int = _coord_id[coord]
	_erase_known(coord)
	_reservations.erase(coord)
	item_forgotten.emit(coord, id)


func _erase_known(coord: Vector4i) -> void:
	if not _coord_id.has(coord):
		return
	var id: int = _coord_id[coord]
	_coord_id.erase(coord)
	if _known.has(id):
		_known[id].erase(coord)
		if _known[id].is_empty():
			_known.erase(id)

#endregion

#region queries

## Returns the nearest known coord holding item [param id], or [constant Vector4i.MAX] if none.
##
## Reserved piles are skipped by default so two pawns are not sent to the same
## pile. Distance is measured in tiles from [param from_coord].
func find_nearest(from_coord: Vector4i, id: int, skip_reserved: bool = true) -> Vector4i:
	if not _known.has(id):
		return Vector4i.MAX
	var from_tile: Vector2i = GridUtils.chunk_coord_to_tile_coord(from_coord)
	var nearest: Vector4i = Vector4i.MAX
	var nearest_dist: float = INF
	for coord: Vector4i in _known[id]:
		if skip_reserved and _is_reserved(coord):
			continue
		var dist: float = from_tile.distance_squared_to(GridUtils.chunk_coord_to_tile_coord(coord))
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = coord
	return nearest


## Returns the last-known count remembered at [param coord] (0 if unknown).
##
## This is remembered/stale data. Use [method validate] before acting on it.
func get_known_count(coord: Vector4i) -> int:
	if not _coord_id.has(coord):
		return 0
	var id: int = _coord_id[coord]
	return _known[id].get(coord, 0)

#endregion

#region reservations

## Claims [param coord] for [param pawn] so other pawns skip it in searches.
##
## Returns [code]false[/code] if the pile is already live-reserved by a
## different, still-valid pawn. A reservation is a promise not to hand the
## address out again; the items stay physically on the shelf until taken.
func reserve(coord: Vector4i, pawn: Node) -> bool:
	if not is_instance_valid(pawn):
		return false
	if _is_reserved(coord) and _reservations[coord] != String(pawn.get_path()):
		return false
	_reservations[coord] = String(pawn.get_path())
	return true


## Releases [param pawn]'s claim on [param coord]. No-op if it holds no claim.
func release(coord: Vector4i, pawn: Node) -> void:
	if not _reservations.has(coord):
		return
	if is_instance_valid(pawn) and _reservations[coord] != String(pawn.get_path()):
		return
	_reservations.erase(coord)


## Releases every reservation held by [param pawn] (e.g. on death or cancel).
func release_all_for(pawn: Node) -> void:
	if not is_instance_valid(pawn):
		return
	var path: String = String(pawn.get_path())
	for coord: Vector4i in _reservations.keys():
		if _reservations[coord] == path:
			_reservations.erase(coord)


## Returns whether [param coord] currently has a live reservation.
func is_reserved(coord: Vector4i) -> bool:
	return _is_reserved(coord)


## Internal reservation check that also prunes claims by dead pawns.
func _is_reserved(coord: Vector4i) -> bool:
	if not _reservations.has(coord):
		return false
	if get_node_or_null(_reservations[coord]) == null:
		_reservations.erase(coord)
		return false
	return true

#endregion

#region validation

## Confirms a remembered pile against the authoritative live [code]ItemManager[/code].
##
## Returns [code]true[/code] only when the chunk is loaded, still holds a pile
## of item [param id] at [param coord], and that pile has at least
## [param min_count] items. A stale or unloaded target returns [code]false[/code],
## which is the caller's cue to release, re-query, and fall back to wander.
func validate(coord: Vector4i, id: int, min_count: int = 1) -> bool:
	var chunk: Node = GlobalRef.get_chunk(Vector2i(coord.x, coord.y))
	if chunk == null:
		return false
	var item_manager: Node = chunk.get_node_or_null("ItemManager")
	if item_manager == null:
		return false
	var local: Vector2i = Vector2i(coord.z, coord.w)
	if not item_manager.items.has(local):
		return false
	var pile = item_manager.items[local]
	return pile.id == id and pile.total_count >= min_count

#endregion

#region chunk lifecycle

## Indexes a newly loaded chunk and starts tracking its live pile changes.
func _on_chunk_generated(coords: Vector2i) -> void:
	var chunk: Node = GlobalRef.get_chunk(coords)
	if chunk == null:
		return
	var item_manager: Node = chunk.get_node_or_null("ItemManager")
	if item_manager == null:
		return
	# Refresh colony memory with the ground truth for this area.
	for local: Vector2i in item_manager.items:
		var pile = item_manager.items[local]
		note_item(Vector4i(coords.x, coords.y, local.x, local.y), pile.id, pile.total_count)
	# Keep memory in sync while the chunk stays loaded ("loaded == perceived").
	if not item_manager.item_pile_added.is_connected(_on_pile_changed):
		item_manager.item_pile_added.connect(_on_pile_changed.bind(coords))
	if not item_manager.item_pile_count_changed.is_connected(_on_pile_changed):
		item_manager.item_pile_count_changed.connect(_on_pile_changed.bind(coords))
	if not item_manager.item_pile_deleted.is_connected(_on_pile_deleted):
		item_manager.item_pile_deleted.connect(_on_pile_deleted.bind(coords))


## Handles a chunk unload: keep the stale memory, drop live tracking + reservations.
func _on_chunk_deleted(coords: Vector2i) -> void:
	# The chunk node is already being freed; its signals disconnect with it.
	# Colony memory of its piles is intentionally KEPT (shared, persistent),
	# but any reservation pointing into it must be released so it never freezes.
	for coord: Vector4i in _reservations.keys():
		if coord.x == coords.x and coord.y == coords.y:
			_reservations.erase(coord)


## Live-sync callback: a pile in a loaded chunk was added or changed count.
func _on_pile_changed(local: Vector2i, coords: Vector2i) -> void:
	var chunk: Node = GlobalRef.get_chunk(coords)
	if chunk == null:
		return
	var item_manager: Node = chunk.get_node_or_null("ItemManager")
	if item_manager == null or not item_manager.items.has(local):
		return
	var pile = item_manager.items[local]
	note_item(Vector4i(coords.x, coords.y, local.x, local.y), pile.id, pile.total_count)


## Live-sync callback: a pile in a loaded chunk was fully depleted.
func _on_pile_deleted(local: Vector2i, coords: Vector2i) -> void:
	forget_item(Vector4i(coords.x, coords.y, local.x, local.y))

#endregion
