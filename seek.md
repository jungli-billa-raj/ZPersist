Common Seeking Operations
Here is a quick reference for the different ways to move the file cursor:
Action
	Method	Description
Jump to absolute	seekTo(pos)	Moves the cursor to exactly pos bytes from the start.
Jump relative	seekBy(offset)	Moves forward or backward (if offset is negative) from current spot.
Jump to end	seekFromEnd(pos)	Moves to pos bytes before the end of the file.
Check position	getPos()	Returns the current u64 offset of the cursor.
Check size	getEndPos()	Returns the total size of the file in bytes.
