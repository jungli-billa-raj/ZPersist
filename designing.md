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
0       4     Magic "TDOS"
4       2     Version (u16) = 1
6       2     Header size (u16)
8       8     Record count (u64)
16      8     Record table offset (u64)
24      8     String blob offset (u64)
32      8     File size (u64)

[Record Table]
Each record (fixed 16 bytes):
0       8     String offset (u64)
8       4     String length (u32)
12      4     Flags (done, deleted, etc.)

[String Blob]
Raw UTF-8 bytes, tightly packed
