const std = @import("std");

// [Header] (fixed size)
// Offset  Size  Meaning
// 0       4     Magic "TDOS"
// 4       2     Version (u16) = 1
// 6       2     Header size (u16)
// 8       8     Record count (u64)
// 16      8     Record table offset (u64)
// 24      8     String blob offset (u64)
// 32      8     File size (u64)
const header = struct {
    magic:[]const u8 = "TDOS", 
    version:u16 = 1,
    header_size:u16,
    record_count:u64,
    record_table_offset:u64,
    // string_blob_offset:u64,
    file_size:u64,
};

// [Record Table]
// Each record (fixed 16 bytes):
// Offset  Size  Meaning
// 0       8     String offset (u64)
// 8       4     String length (u32)
// 12      4     Flags (done, deleted, etc.)
const record_table = struct {
    string_offset:u64,
    string_length:u32,
    flags:u32, // 0-done 1-deleted
};

// [String Blob]
// Raw UTF-8 bytes, tightly packed
// No struct needed

// ----------------------testing structs----------------------
test "struct" {
    const h = header{
        .magic = "TDOS",
        .version = 2, 
        .header_size = 0,
        .file_size = 0,
        .record_count = 0,
        .record_table_offset = 40,
    };
    std.debug.print("{}\n", .{h});
}

// create new file function 
// pub fn create_new_file(name:[]u8) !void{
//
// }
