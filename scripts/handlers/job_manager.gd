@icon("res://textures/editor_icons/briefcase.svg")
extends Node

@abstract class Job:
	var location : Vector2i
	var reserved : bool
	var priority : int
	@warning_ignore("shadowed_variable")
	func _init(location : Vector2i, priority : int, reserved : bool = false) -> void:
		self.location = location
		self.priority = priority
		self.reserved = reserved

class BuildingJob:
	extends Job
	var building_id : int
	@warning_ignore("shadowed_variable")
	@warning_ignore("shadowed_variable_base_class")
	func _init(location : Vector2i, building_id : int, priority : int, reserved : bool = false) -> void: # CRITICAL ADD PAWN REFERENCE TO RESERVED INSTEAD
		self.location = location
		self.priority = priority
		self.reserved = reserved
		self.building_id = building_id

var jobs : Array = []
var auction = {}

# CRITICAL NEED TO ADD JOB TYPES

func _on_building_agent_objects_built(object_id: int, coord_array: Array, queued: bool) -> void:
	if queued:
		for coord in coord_array:
			jobs.append(BuildingJob.new(coord, object_id, 5))
			print(coord)
			_on_jobs_updated(jobs[-1])

func start_job_auction(job : Job):
	var _queued_action : DecisionMaker.QueuedAction = _job_class_to_queued_action(job)
	var _location = job.location
	for path in GlobalRef.pawns:
		var pawn = get_node(path)
		var _dec_maker : DecisionMaker = pawn.decision_maker
		partake_in_auction(pawn, _dec_maker.calculate_action_priority_modifier(_queued_action.action_name, _queued_action.priority, job.location))
	auction[auction.keys().max()].decision_maker.add_action_to_queue(_queued_action.action_name, auction.keys().max(), _queued_action.args)
	auction.clear()
	job.reserved = true

func _job_class_to_queued_action(job : Job) -> DecisionMaker.QueuedAction:
	if job is BuildingJob:
		return DecisionMaker.QueuedAction.new(&"build_action", job.priority,{&"target" : job.location, &"id" : job.building_id})
	return null

func partake_in_auction(pawn : Node, bet : float):
	auction[bet] = pawn

func _on_jobs_updated(with_what) -> void:
	start_job_auction(with_what)
