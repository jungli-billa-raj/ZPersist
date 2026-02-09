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
const header =  extern struct {
    // magic:[]const u8 = "TDOS", //this has a pointer+length. Not compatible with C or Binary. 
    magic:[4]u8 = "TDOS".*, // here dereferencing is necessary to get the data "TDOS" and not the pointer to it. 
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
// 16      8     Next Record Offset (u64) 
const record_table =  extern struct {
    string_offset:u64,
    string_length:u64,
    flags:u32, // 0-done 1-deleted 
};

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
        .record_table_offset = 40,
    };
    // std.debug.print("{}\n", .{h});

    _ = record_table{
        .string_offset = 56, 
        .string_length = 10, 
        .flags = 0,
    };
    // std.debug.print("{}\n", .{rt});
}

// create new file function 
pub fn create_new_file(name:[]const u8) !void{

    const h = header{
        // .magic = "TDOS",
        .version = 1, 
        .header_size = 40,
        .file_size = 0,
        .record_count = 0,
        .record_table_offset = 40,
    };
    var pathBuffer:[256]u8 = undefined;
    const path = try std.fmt.bufPrint(&pathBuffer, "{s}.tdos", .{name});
    var file = try std.fs.cwd().createFile(path, .{.read = true });
    defer file.close();

    // var buffer:[256]u8 = undefined;
    // var writer = file.writer(&buffer);
    // try writer.interface.writeAll("Hello zig bytes here!!");
    //
    // // flushing is important while using a buffered writer 
    // try writer.interface.flush();

    var file_buffer: [320]u8 = undefined; 
    var writer = file.writer(&file_buffer);
    const writer_interface = &writer.interface;
    // try writer.writeStruct(h); // Or use the built-in struct writer
    try writer_interface.writeStruct(h, .little);
    try writer_interface.flush();
}

// test "create_new_file" {
//     try create_new_file("test_file");
//     //I'm not testing the first few bytes yet. 
// }

// This will come in handy
// const file = try cwd.openFile("output.bin", .{ .mode = .read_write });
// try file.seekFromEnd(0); // Move the cursor to the end
// try file.writeAll(&more_bytes);

pub fn findLatestRecordOffset(file_name:[]const u8) !u64{
    const header_size:u32 = 40;
    const record_meta_size:u32 = 20;

    var fb1:[256]u8 = undefined;
    const path = try std.fmt.bufPrint(&fb1, "{s}.tdos", .{file_name});
    var file = try std.fs.cwd().openFile(path, .{.mode = .read_write });
    defer file.close();

    const file_size:u64 = try file.getEndPos(); 
    
    var offset:u64 = header_size;

    var fb2:[256]u8 = undefined;
    while (true) {
        if (offset + record_meta_size > file_size) break;
        try file.seekTo(offset);
        const bytes_read = try file.read(&fb2);
        if (bytes_read == 0) {
            break;
        }
        const string_length:u32 = std.mem.readInt(u32, fb2[8..12], .little);
        offset += record_meta_size + string_length;
        // how to convert bytes to int? for doing 
        // offset = string_offset + string_length; 
    }
    return offset;
}

// test "findLatestRecordOffset test" {
//     const offset_returned = try findLatestRecordOffset("test_file");
//     std.debug.print("Offset returned by findLatestRecordOffset: {d} \n", .{offset_returned});
// } 

// const record_table =  extern struct {
//     string_offset:u64,
//     string_length:u32,
//     flags:u32, // 0-done 1-deleted 2-in process
//     next_record_offset:u64,
// };

pub fn addRecord(file_name:[]const u8, data:[]const u8) !void {
    var fb1:[256]u8 = undefined;
    const path = try std.fmt.bufPrint(&fb1, "{s}.tdos", .{file_name});
    var file = try std.fs.cwd().openFile(path, .{.mode = .read_write });
    defer file.close();

    const RECORD_META_SIZE:u32 = @sizeOf(record_table);
    std.debug.print("size of record_table:{any}", .{@sizeOf(record_table)});
    // Determining append point 
    const file_size = try file.getEndPos();
    const record_offset = file_size;
    const string_offset = record_offset + RECORD_META_SIZE;

    const newRecord = record_table{
        .flags = 0,
        .string_length = data.len,
        .string_offset = string_offset,
    };

    try file.seekTo(record_offset);

    var fb2: [256]u8 = undefined; 
    var writer = file.writer(&fb2);
    const writer_interface = &writer.interface;
    // try writer.writeStruct(h); // Or use the built-in struct writer
    try writer_interface.writeStruct(newRecord, .little);
    try writer_interface.writeAll(data);
    try writer_interface.flush();
}

test "addRecord" {
    try create_new_file("test_file");

    try addRecord("test_file", "Hello, my name is Raj");
    try addRecord("test_file", "Hello, my name is Aadarsh");
    try addRecord("test_file", "Hello, my name is Suraj");
    try addRecord("test_file", "Hello, my name is Siddhanth");
    // only one is being appended and the rest are removed
}
