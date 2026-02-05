
const header =  struct{
    magic:[]const u8 = "TDOS", 
    version:u16 = 1,
    header_size:u16,
    record_count:u64,
    record_table_offset:u64,
    // string_blob_offset:u64,
    file_size:u64,
};

const std = @import("std");

test "ss" {
    const h = header{
        .magic = "TDOS",
        .version = 1, 
        .header_size = 40,
        .file_size = 0,
        .record_count = 0,
        .record_table_offset = 40,
    };
    std.debug.print("{b64}{b64}{b64}{b64}{b64}{b64}\n", .{std.mem.asBytes(&h.magic),std.mem.asBytes(&h.version),std.mem.asBytes(&h.header_size),std.mem.asBytes(&h.file_size),std.mem.asBytes(&h.record_count),std.mem.asBytes(&h.record_table_offset)});
}
