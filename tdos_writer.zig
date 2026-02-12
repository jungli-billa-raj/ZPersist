const std = @import("std");
const expect = std.testing.expect;

const header =  extern struct {
    magic:[4]u8 = "TDOS".*, // here dereferencing is necessary to get the data "TDOS" and not the pointer to it. 
    version:u16 = 1,
    header_size:u16,
    record_count:u64,
    file_size:u64,
};
const header_size = @sizeOf(header);

const record_table =  extern struct {
    string_offset:u64,
    string_length:u64,
    flags:u32, // 0-done 1-deleted 
};
const record_table_size = @sizeOf(record_table);


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

// create new file function 
pub fn create_new_file(name:[]const u8) !void{


    const h = header{
        // .magic = "TDOS",
        .version = 1, 
        .header_size = header_size,
        .file_size = 0,
        .record_count = 0,
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

    var file_buffer: [1024]u8 = undefined; 
    var writer = file.writer(&file_buffer);
    const writer_interface = &writer.interface;
    // try writer.writeStruct(h); // Or use the built-in struct writer
    try writer_interface.writeAll("TDOS");
    try writer_interface.writeInt(u16, h.version, .little);
    try writer_interface.writeInt(u16, h.header_size, .little);
    try writer_interface.writeInt(u64, h.record_count, .little);
    try writer_interface.writeInt(u64, h.file_size, .little);
    try writer_interface.flush();
}
pub fn findLatestRecordOffset(file_name:[]const u8) !u64{
    var fb1:[256]u8 = undefined;
    const path = try std.fmt.bufPrint(&fb1, "{s}.tdos", .{file_name});
    var file = try std.fs.cwd().openFile(path, .{.mode = .read_write });
    defer file.close();

    const file_size:u64 = try file.getEndPos(); 
    
    var offset:u64 = header_size;

    var fb2:[256]u8 = undefined;
    while (true) {
        if (offset + record_table_size > file_size) break;
        try file.seekTo(offset);
        const bytes_read = try file.read(&fb2);
        if (bytes_read == 0) {
            break;
        }
        const string_length:u32 = std.mem.readInt(u32, fb2[8..12], .little);
        offset += record_table_size + string_length;
        // how to convert bytes to int? for doing 
        // offset = string_offset + string_length; 
    }
    return offset;
}

pub fn addRecord(file_name:[]const u8, data:[]const u8) !void {
    var fb1:[256]u8 = undefined;
    const path = try std.fmt.bufPrint(&fb1, "{s}.tdos", .{file_name});

    // Open in read write mode
    var file = try std.fs.cwd().openFile(path, .{.mode = .read_write });
    defer file.close();

    // Determining append point 
    const file_size = try file.getEndPos();
    // try file.seekTo(record_offset);
    try file.seekTo(file_size);
    std.debug.print("addRecord(): file_size before write:{any}\n", .{file_size});
    const string_offset = file_size + record_table_size;

    const newRecord = record_table{
        .flags = 0,
        .string_length = data.len,
        .string_offset = string_offset,
    };


    var fb2: [1024]u8 = undefined; 
    var writer = file.writer(&fb2);
    const writer_interface = &writer.interface;
    try writer_interface.writeInt(u64, newRecord.string_offset, .little);
    try writer_interface.writeInt(u64, newRecord.string_length, .little);
    try writer_interface.writeInt(u32, newRecord.flags, .little);
    try writer_interface.writeAll(data);
    try writer_interface.flush();

    // update Header ---PENDING---
}

test "addRecord" {
    std.debug.print("=== new test run ===\n", .{});
    try create_new_file("test_file");

    try addRecord("test_file", "Hello, my name is Raj");
    try addRecord("test_file", "Hello, my name is Aadarsh");
    try addRecord("test_file", "Hello, my name is Suraj");
    try addRecord("test_file", "Hello, my name is Siddhanth");
    // only one is being appended and the rest are removed
}
