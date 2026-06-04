@icon("res://textures/editor_icons/briefcase.svg")
extends Node

@abstract class Job:
	var location: Vector4i
	var reserved: bool
	var priority: int
	@warning_ignore("shadowed_variable")
	func _init(location: Vector4i, priority: int, reserved: bool = false) -> void:
		self.location = location
		self.priority = priority
		self.reserved = reserved


class BuildingJob:
	extends Job
	var building_id: int
	@warning_ignore("shadowed_variable")
	@warning_ignore("shadowed_variable_base_class")
	func _init(location: Vector4i, building_id: int, priority: int, reserved: bool = false) -> void:  # CRITICAL ADD PAWN REFERENCE TO RESERVED INSTEAD
		self.location = location
		self.priority = priority
		self.reserved = reserved
		self.building_id = building_id


var jobs: Array = []
var auction = {}

# CRITICAL NEED TO ADD JOB TYPES


func _on_building_agent_objects_built(object_id: int, coord_array: Array, queued: bool) -> void:
	if queued:
		GlobalLogger.write_to_logs(self, "Adding built objects to jobs...")
		for coord in coord_array:
			jobs.append(BuildingJob.new(coord, object_id, 5))
			_on_jobs_updated(jobs[-1])


func start_job_auction(job: Job):
	var _queued_action: DecisionMaker.QueuedAction = _job_class_to_queued_action(job)
	var _location = job.location
	for path in GlobalRef.get_pawns():
		var pawn = get_node(path)
		var _dec_maker: DecisionMaker = pawn.decision_maker
		partake_in_auction(
			pawn,
			_dec_maker.calculate_action_priority_modifier(
				_queued_action.action_type, _queued_action.priority, job.location
			)
		)
	GlobalLogger.write_to_logs(self, "Auction won by %s" % auction[auction.keys().max()].name)
	auction[auction.keys().max()].decision_maker.add_action_to_queue(
		_queued_action.action_type, auction.keys().max(), _queued_action.args
	)
	auction.clear()
	job.reserved = true


func _job_class_to_queued_action(job: Job) -> DecisionMaker.QueuedAction:
	if job is BuildingJob:
		return DecisionMaker.QueuedAction.new(
			ActionMachine.action_types.build,
			job.priority,
			{&"target": job.location, &"id": job.building_id}
		)
	return null


func partake_in_auction(pawn: Node, bet: float):
	auction[bet] = pawn


func _on_jobs_updated(with_what) -> void:
	var type
	if with_what is BuildingJob:
		type = "BuildingJob"
	GlobalLogger.write_to_logs(self, "Started auction for %s at %s" % [type, with_what.location])
	start_job_auction(with_what)
