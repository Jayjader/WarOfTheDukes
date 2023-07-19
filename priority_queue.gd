extends Object
class_name PriorityQueue

enum TYPE { MAX, MIN }

@export var type: TYPE = TYPE.MIN

var _array = []

@export var size: int = 0


static func is_before(type_: TYPE, a, b) -> bool:
	match type_:
		TYPE.MAX:
			return a.priority > b.priority
		TYPE.MIN:
			return a.priority < b.priority
		_:
			print_debug("Priority Queue type not set: %s" % type_)
			return false

static func parent_index_for(index: int) -> int:
	@warning_ignore("integer_division")
	return (index - 1) / 2
static func left_child_index_for(index: int) -> int:
	return (2 * index) + 1
static func right_child_index_for(index: int) -> int:
	return (2 * index) + 2

func shift_up(index: int):
	while (index > 0):
		var parent_index = PriorityQueue.parent_index_for(index)
		var parent_val = self._array[parent_index]
		var index_val = self._array[index]
		if not PriorityQueue.is_before(self.type, parent_val, index_val):
			self._array[parent_index] = index_val
			self._array[index] = parent_val
			index = parent_index
		else:
			break

func shift_down(index_to_shift: int):
	var value_to_shift = self._array[index_to_shift]
	var lowest_priority_index = index_to_shift
	var lowest_priority_val = value_to_shift

	var index_of_left_child = PriorityQueue.left_child_index_for(index_to_shift)
	if (index_of_left_child < size):
		var left_child_val = self._array[index_of_left_child]
		if PriorityQueue.is_before(self.type, left_child_val, value_to_shift):
			lowest_priority_index = index_of_left_child
			lowest_priority_val = left_child_val

	var index_of_right_child = PriorityQueue.right_child_index_for(index_to_shift)
	if (index_of_right_child < size):
		var right_child_val = self._array[index_of_right_child]
		if PriorityQueue.is_before(self.type, right_child_val, lowest_priority_val):
			lowest_priority_index = index_of_right_child
			lowest_priority_val = right_child_val

	if lowest_priority_index != index_to_shift:
		# one of the node's children should be before it;
		# swap the two,
		self._array[lowest_priority_index] = value_to_shift
		self._array[index_to_shift] = lowest_priority_val

		# and continue shifting the same node (which is now the child) down until it settles into its correct position
		self.shift_down(lowest_priority_index)

func insert(value):
	if len(self._array) <= self.size:
		self._array.push_back(value)
	else:
		self._array[self.size] = value

	self.size += 1
	self.shift_up(self.size - 1)

func extract_max():
	if self.size == 1:
		self.size = 0
		return self._array.pop_front()

	#

	self.size -= 1
	var result = self._array[0]
	self._array[0] = self._array[self.size]


	self.shift_down(0)
	return result

func get_max():
	return self._array[0]

func remove(index: int):
	# set priority of element-to-remove so that its "valid" place is at the top of the queue/heap
	self._array[index].priority = self.get_max().priority + 1
	# rebalance queue/heap with minimal work, so that the element-to-remove effectively rises to the top of the queue/heap without altering the "total" ordering of the remaining elements
	self.shift_up(index)
	# extract the "new" root, which is now the element-to-remove
	self.extract_max()
