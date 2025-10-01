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
	func _init(location : Vector2i, building_id : int, priority : int, reserved : bool = false) -> void:
		self.location = location
		self.priority = priority
		self.reserved = reserved
		self.building_id = building_id

var jobs : Array = []
var auction = {}

signal jobs_updated(with_what : Job)

# CRITICAL NEED TO ADD JOB TYPES

func _on_building_agent_objects_built(object_id: int, coord_array: Array, queued: bool) -> void:
	if queued:
		for coord in coord_array:
			jobs.append(BuildingJob.new(coord, 1, object_id))
		jobs_updated.emit()

func start_job_auction(job : Job):
	var _queued_action := _job_class_to_queued_action(job)
	for pawn in GlobalRef.pawns:
		var _dec_maker : DecisionMaker = pawn.decision_maker
		partake_in_auction(pawn, _dec_maker.calculate_action_priority_modifier(_job_class_to_queued_action(job)))
	auction[auction.keys().max()].decision_maker.add_action_to_queue(_queued_action.action_name, _queued_action.priority, _queued_action.args)

func _job_class_to_queued_action(job : Job) -> DecisionMaker.QueuedAction:
	if job is BuildingJob:
		return DecisionMaker.QueuedAction.new(&"build_action", job.priority,{&"target" : job.location, &"id" : job.building_id})
	return null

func partake_in_auction(pawn : Node, bet : float):
	auction[bet] = pawn
