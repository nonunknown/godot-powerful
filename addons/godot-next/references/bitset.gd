# Bitset
# author: milesturin
# license: MIT
# description: A class that allows for easily manipulated bitmasks of any size
# usage: Mostly self explanatory. _init() is equivalent to resize().
# 	By setting enforce_soft_size to false, the Bitset will allow the user to access
# 	bits that have been reserved by the script, but are outside of the requested size.

extends Reference
class_name Bitset

### CONSTANTS ###

const MASK_SIZE := 32

### PROPERTIES ###

var bitmasks: PoolIntArray = []
var bits: int

### NOTIFICATIONS ###

func _init(size: int, default_state: bool = false, enforce_soft_size: bool = true) -> void:
	resize(size, default_state, enforce_soft_size)

### PUBLIC METHODS ###

func resize(size: int, default_state: bool = false, enforce_soft_size: bool = true) -> void:
	assert(size >= 0)
	var old_masks := bitmasks.size()
	if old_masks > 0 and bits % MASK_SIZE:
		if default_state:	
			bitmasks[old_masks - 1] |= (~0 << (bits % MASK_SIZE))
		else:
			bitmasks[old_masks - 1] &= ~((~0) << (bits % MASK_SIZE))
	bitmasks.resize(ceil(size / float(MASK_SIZE)))
	bits = size if enforce_soft_size else bitmasks.size() * MASK_SIZE
	for i in range(old_masks, bitmasks.size()):
		bitmasks[i] = ~0 if default_state else 0

func check_bit(index: int) -> bool:
	assert(index < bits)
	return bitmasks[index / MASK_SIZE] & (1 << (index % MASK_SIZE)) != 0

func set_bit(index: int, state: bool) -> void:
	assert(index < bits)
	if state:
		bitmasks[index / MASK_SIZE] |= (1 << (index % MASK_SIZE))
	else:
		bitmasks[index / MASK_SIZE] &= ~(1 << (index % MASK_SIZE))

func flip_bit(index: int) -> void:
	assert(index < bits)
	set_bit(index, !check_bit(index))

func print_bits(multiline: bool = true) -> void:
	if multiline:
		for i in range(bits):
			print("bit " + String(i) + ": " + String(check_bit(i)))
	else:
		var output := ""
		for i in range(bits):
			output += '1' if check_bit(i) else '0'
		print(output)
