@icon("res://shared/editor_icons/briefcase.svg")
extends Node

## Converts world tasks into auctioned work for pawns.
##
## The current implementation focuses on building jobs: when ghost build tiles
## are queued, it creates [code]BuildingJob[/code] entries, asks each registered pawn for a
## bid, and forwards the winning action request to that pawn's
## [DecisionMaker].

## Base job description shared by all concrete job types.
@abstract class Job:
	var location: Vector4i
	var reserved: bool
	var priority: int
	@warning_ignore("shadowed_variable")
	func _init(location: Vector4i, priority: int, reserved: bool = false) -> void:
		self.location = location
		self.priority = priority
		self.reserved = reserved


## Job requesting that a pawn builds a specific buildable at the stored location.
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


## Pending jobs waiting to be auctioned or completed.
var jobs: Array[Job] = []
## Temporary bid table used while choosing a pawn for the current job.
var auction: Dictionary[float, BaseEntity] = {}

# CRITICAL NEED TO ADD JOB TYPES


## Converts queued build placements into [code]BuildingJob[/code] entries.
func _on_building_agent_objects_built(
	object_id: int, coord_array: Array[Vector4i], queued: bool
) -> void:
	if queued:
		GlobalLogger.write_to_logs(self, "Adding built objects to jobs...")
		for coord: Vector4i in coord_array:
			jobs.append(BuildingJob.new(coord, object_id, 5))
			_on_jobs_updated(jobs[-1])


## Starts an auction for [param job] and assigns it to the best bidder.
func start_job_auction(job: Job) -> void:
	var queued_action: DecisionMaker.QueuedAction = _job_class_to_queued_action(job)
	for path: String in GlobalRef.get_pawns():
		var pawn := get_node(path) as BaseEntity
		var decision_maker: DecisionMaker = pawn.decision_maker
		partake_in_auction(
			pawn,
			decision_maker.calculate_action_priority_modifier(
				queued_action.action_type, queued_action.priority, job.location
			)
		)
	var best_bid: float = auction.keys().max()
	var winner: BaseEntity = auction[best_bid]
	GlobalLogger.write_to_logs(self, "Auction won by %s" % winner.name)
	winner.decision_maker.add_action_to_queue(
		queued_action.action_type, best_bid, queued_action.args
	)
	auction.clear()
	job.reserved = true


## Converts a job record into the queued action that should fulfill it.
func _job_class_to_queued_action(job: Job) -> DecisionMaker.QueuedAction:
	if job is BuildingJob:
		var building_job := job as BuildingJob
		return DecisionMaker.QueuedAction.new(
			ActionMachine.action_types.build,
			building_job.priority,
			{"target": building_job.location, &"id": building_job.building_id}
		)
	return null


## Registers a pawn's bid for the active auction round.
func partake_in_auction(pawn: BaseEntity, bet: float) -> void:
	auction[bet] = pawn


## Handles job creation by logging it and immediately starting an auction.
func _on_jobs_updated(with_what: Job) -> void:
	var type: String = "UnknownJob"
	if with_what is BuildingJob:
		type = "BuildingJob"
	GlobalLogger.write_to_logs(self, "Started auction for %s at %s" % [type, with_what.location])
	start_job_auction(with_what)
