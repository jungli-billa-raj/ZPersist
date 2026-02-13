const std = @import("std");

pub const header =  extern struct {
    magic:[4]u8 = "TDOS".*, // here dereferencing is necessary to get the data "TDOS" and not the pointer to it. 
    version:u16 = 1,
    header_size:u16,
    record_count:u64,
    file_size:u64,
};
pub const header_size = @sizeOf(header);

pub const record_table =  extern struct {
    string_offset:u64,
    string_length:u64,
    flags:u32, // 0-done 1-deleted 
};
pub const record_table_size = @sizeOf(record_table);


// [String Blob]
// Raw UTF-8 bytes, tightly packed
// No struct needed

// ----------------------testing structs----------------------
test "struct" { 
    _ = header{
        // .magic = "TDOS",
        .version = 2, 
        .header_size = 0,
        .file_size = 0,
        .record_count = 0,
    };
    // std.debug.print("{}\n", .{h});

    _ = record_table{
        .string_offset = 56, 
        .string_length = 10, 
        .flags = 0,
    };
    // std.debug.print("{}\n", .{rt});
    std.debug.print("size of header struct is {any}\n", .{@sizeOf(header)});
    std.debug.print("size of record_table struct is {any}\n", .{@sizeOf(record_table)});
}

