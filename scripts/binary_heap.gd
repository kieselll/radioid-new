extends RefCounted
class_name BinaryHeap

var heap : Array = []

func append(element : Variant) -> void:
	heap.append(element)

func get_front() -> Variant:
	return heap[0]

func pop_front() -> Variant:
	return heap.pop_front()

func get_back() -> Variant:
	return heap[-1]

func pop_back() -> Variant:
	return heap.pop_back()

func move_last_to_front() -> void:
	heap.insert(0, heap[-1])

func is_empty() -> bool:
	return heap.is_empty()

func size() -> int:
	return heap.size()

func clear() -> void:
	heap.clear()

## Sorts the heap using a custom Callable.[br][br]
## func is called as many times as necessary, receiving two heap elements as arguments.
## The function should return true if the first element should be bubbled up, otherwise it should return false.
func bubble_up_heap_custom(function : Callable) -> void:
	var current_index : int = heap.size() - 1
	@warning_ignore_start("integer_division")
	while not current_index == 0 and function.call(heap[(current_index - 1) / 2], heap[current_index]):
		var parent_index : int = (current_index - 1) / 2
		var temp_parent = heap[parent_index]
		heap[parent_index] = heap[current_index]
		heap[current_index] = temp_parent
		current_index = parent_index
	@warning_ignore_restore("integer_division")

## Sorts the heap using a custom Callable.[br][br]
## func is called as many times as necessary, receiving two heap elements as arguments.
## The function should return true if the first element should be bubbled down, otherwise it should return false.
func bubble_down_heap_custom(function : Callable) -> void:
	var current_index : int = 0
	while current_index * 2 + 1 < heap.size():
		var left : int = current_index * 2 + 1
		var right : int = current_index * 2 + 2
		var has_right : bool = right < heap.size()
		if function.call(heap[left], heap[current_index])\
		or (has_right and function.call(heap[right], heap[current_index])):
			var temp_child_index : int = left if has_right and function.call(heap[left], heap[right])\
			else right
			var temp_child = heap[temp_child_index]
			heap[temp_child_index] = heap[current_index]
			heap[current_index] = temp_child
			current_index = temp_child_index
		else:
			break

func bubble_up_heap() -> void:
	bubble_up_heap_custom(func(a : int, b : int) -> bool: return a < b)

func bubble_down_heap() -> void:
	bubble_down_heap_custom(func(a : int, b : int) -> bool: return a > b)
