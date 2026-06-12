class_name BehaviorData
extends Resource

## High-level behavior defaults and decision weights for a pawn.
##
## This resource configures which fallback action a pawn prefers, whether it is
## allowed to participate in job systems, and how [DecisionMaker] scores queued
## work.

## Action used when the pawn has nothing more urgent to do.
@export var default_action: ActionMachine.action_types = ActionMachine.action_types.wander
## If [code]true[/code], the pawn is allowed to roam when idle.
@export var auto_wander: bool = true
## If [code]true[/code], the pawn may bid on and accept jobs.
@export var takes_jobs: bool = true

## Maximum random offset, in tiles, used by wandering behavior.
@export_range(0, 64, 1) var wander_radius: int = 5
## Minimum delay between wander attempts.
@export_range(0.0, 10.0, 0.1) var wander_delay_min: float = 0.3
## Maximum delay between wander attempts.
@export_range(0.0, 10.0, 0.1) var wander_delay_max: float = 1.5

## Weight applied to the base priority passed into [DecisionMaker].
@export_range(0.0, 10.0, 0.1) var base_priority_weight: float = 1.0
## Weight applied to positive skill levels when evaluating a job.
@export_range(0.0, 10.0, 0.1) var skill_weight: float = 1.0
## Weight applied to negative skill levels when evaluating a job.
@export_range(0.0, 10.0, 0.1) var negative_skill_weight: float = 1.0
## Weight controlling how strongly distance lowers effective priority.
@export_range(0.0, 10.0, 0.1) var distance_weight: float = 1.0
