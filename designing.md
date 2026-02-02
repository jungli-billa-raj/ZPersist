_______todos store file format_______

SCOPE:
Append Only

WHAT FILE MUST REMEMBER:
Record Store 

INVARIANTS:
All integers are little-endian
File starts with a fixed-size header
Offsets are u64 from file start
Strings are UTF-8, not null-terminated
File is append-only
Reader must reject unknown versions

LAYOUT(minimal):
FILE LAYOUT

[Header] (fixed size)
Offset  Size  Meaning
0       4     Magic "TDST"
4       48     Version ([6]const u8)
52      2     Header size (u16)
54      8     Record count (u64)
62      8     Record table offset (u64)  // 2 
70      8     String blob offset (u64)   // what is this? why is this even needed?
78      8     File size (u64)

[Record Table] (repeated)
Each record:
  0     8     String offset (u64)
  8     4     String length (u32)
  12    4     Flags / reserved

[String Blob]
Raw UTF-8 bytes, tightly packed
